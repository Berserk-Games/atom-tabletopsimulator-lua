{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'

net = require 'net'
fs = require 'fs'
os = require 'os'
path = require 'path'
mkdirp = require 'mkdirp'
luaparse = require 'luaparse'
shell = require 'shell'
provider = require './provider'
StatusBarFunctionView = require './status-bar-function-view'
FunctionListView = require './function-list-view'
CheckboxList = require './checkbox-list-view'
TTSPanelView = require './tts-panel-view'

domain = 'localhost'
clientport = 39999
serverport = 39998

TTS_MSG_NONE        = -1
TTS_MSG_NEW_OBJECTS = 0
TTS_MSG_NEW_GAME    = 1
TTS_MSG_PRINT       = 2
TTS_MSG_ERROR       = 3
TTS_MSG_CUSTOM      = 4
TTS_MSG_RETURN      = 5

ATOM_MSG_NONE        = -1
ATOM_MSG_GET_SCRIPTS = 0
ATOM_MSG_SAVE_PLAY   = 1
ATOM_MSG_CUSTOM      = 2
ATOM_MSG_LUA         = 3

CUSTOM_MSG_WATCH = 1


ttsLuaDir = path.join(os.tmpdir(), "TabletopSimulator", "Tabletop Simulator Lua")
# remove old name for temp dir, for people who have used previous versions (21/08/17)
# TODO remove this at some later date
try
  atom.project.removePath(path.join(os.tmpdir(), "TabletopSimulator", "Lua"))
catch error


# Check atom version; if 1.19+ then editor.save has become async
# TODO when 1.19 has been out long enough remove this check and require atom 1.19 in package.json
async_save = true
try
  if parseFloat(atom.getVersion()) < 1.19
    async_save = false
catch error


# Store cursor positions and open editors between loads
cursors = {}
editors = []
ttsEditors = {}
globals = {}
globals.activeEditorPath = null
globals.count = 0
mutex = {}
mutex.doingSaveAndPlay = false
mutex.functionCount = 0
mutex.returnID = 0


luaFunctionName = ->
  mutex.functionCount += 1
  return "atom_lua_function_" + mutex.functionCount


getExecuteReturnID = ->
  mutex.returnID += 1
  return mutex.returnID


# Ping function not used at the moment
ping = (socket, delay) ->
  console.log "Pinging server"
  socket.write "Ping"
  nextPing = -> ping(socket, delay)
  setTimeout nextPing, delay

# #include system for inserting one file into another
insertFileKeyword = '#include'
insertFileSeperator = '|'
insertFileMarkerString = '(\\s*' + insertFileKeyword + '\\s+([^\\s].*))'
insertFileRegexp = RegExp('^' + insertFileMarkerString)
insertedFileRegexp = RegExp('^----' + insertFileMarkerString)
fileMap = {}
appearsInFile = {}

# record last error message
lastError = {message: "", guid: ""}

if os.platform() == 'win32'
  PATH_SEPERATOR = '\\'
else
  PATH_SEPERATOR = '/'


completeFilepath = (fn, dir) ->
  filepath = fn
  if not filepath.endsWith('.ttslua')
    filepath += '.ttslua'
  if filepath.match(/^![\\/]/) # ! = configured dir for TTSLua files
    filepath = path.join(getRootPath(), filepath[2..])
  else if filepath.match(/^~[\\/]/) # ~ = home dir
    filepath = path.join(os.homedir(), filepath[2..])
  if os.platform() == 'win32'
    fullPathPattern = /\:/
  else
    fullPathPattern = /^\//
  if filepath.match(fullPathPattern)
    return filepath
  if not dir
    dir = getRootPath()
  return path.join(dir, filepath)


getRootPath = () ->
  rootpath = atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFilesPath')
  if rootpath == ''
    rootpath = '~/Documents/Tabletop Simulator'
  if rootpath.match(/^~[\\/]/) # home dir selector ~
    rootpath = path.join(os.homedir(), rootpath[2..])
  return rootpath


extractFileMap = (text, filepath) ->
  lines = text.split(/\n/)
  tree = {label: filepath, children: [], parent: null, startRow: 0, endRow: lines.length-1, depth: 0}
  for line, row in lines
    found = line.match(insertedFileRegexp)
    if found
      if tree.parent
        dir = path.dirname(tree.parent.label)
      else # root node
        dir = path.dirname(filepath)
      label = completeFilepath(found[2], dir)
      if tree.parent and tree.parent.label == label #closing include
        tree.endRow = row
        tree = tree.parent
        if tree.parent == null
          output.push(found[1])
      else #opening include
        tree.children.push({label: label, children: [], parent: tree, startRow: row + 1, endRow: null, depth: tree.depth + 1})
        tree = tree.children[tree.children.length-1]
        if not (label of appearsInFile)
          appearsInFile[label] = {}
        appearsInFile[label][filepath] = tree.depth


isFromTTS = (fn) ->
  return fn and path.dirname(fn) == ttsLuaDir


isGlobalScript = (fn) ->
  return fn and path.basename(fn) == 'Global.-1.ttslua'


getPathGUID = (fn) ->
  [name, guid, ext] = fn.split('.')
  return guid


destroyTTSEditors = ->
  try
    globals.activeEditorPath = atom.workspace.getActiveTextEditor().getPath()
  catch error
  if not atom.config.get('tabletopsimulator-lua.loadSave.openOtherFiles')
    force = true
  for editor,i in atom.workspace.getTextEditors()
    if force or isFromTTS(editor.getPath())
      try
        editor.destroy()
      catch error
        console.log error


findFileRow = (filepath, row) ->
  if fileMap[filepath]
    walkFileMap = (r, node) ->
      offset = 0
      if node.startRow <= r <= node.endRow
        for child in node.children
          if child.endRow < r
            offset += (child.endRow - child.startRow) + 1
          else if r >= child.startRow
            return walkFileMap(r, child)
        # not in any children, so is only in this file
      return [node.label, r - (node.startRow + offset)]
    [fp, row] = walkFileMap(row, fileMap[filepath])
    if fp
      filepath = fp
  return [filepath, row]


gotoFileRow = (filepath, row) ->
  [filepath, row] = findFileRow(filepath, row)
  editor = atom.workspace.getActiveTextEditor()
  if filepath and filepath != editor.getPath()
    console.log "Opening file in Go-To-File-Row", filepath
    atom.workspace.open(filepath, {initialLine: row, initialColumn: 0}).then (editor) ->
      editor.setCursorBufferPosition([row, 0])
      editor.scrollToCursorPosition()
  else
    editor.setCursorBufferPosition([row, 0])
    editor.scrollToCursorPosition()


gotoError = (message, guid) ->
  # kludge for bad guid reporting in coroutines; will treat all coroutines as if they were in Global script
  if guid == "-2"
    guid = "-1"
  row = 0
  fname = ""
  row_string = message.match(/:\(([0-9]*),[^\)]+\):/)
  if row_string
    row = parseInt(row_string[1]) - 1
  luafiles = fs.readdirSync(ttsLuaDir)
  for luafile, i in luafiles
    guid_string = luafile.match(/\.(.+)\.ttslua$/)
    if guid_string[1] == guid
      fname = path.join(ttsLuaDir, luafile)
      break
  if fname != ""
    gotoFileRow(fname, row)


lengthInUtf8Bytes = (str) ->
  m = encodeURIComponent(str).match(/%[89ABab]/g)
  return str.length + (if m then m.length else 0)


class FileHandler
  constructor: ->
    @readbytes = 0
    @ready = false


  setBasename: (basename) ->
    @basename = basename


  setDatasize: (datasize) ->
    @datasize = datasize


  create: ->
    @tempfile = path.join(ttsLuaDir, @basename)
    dirname = path.dirname(@tempfile)
    mkdirp.sync(dirname)
    @fd = fs.openSync(@tempfile, 'w')


  append: (line) ->
    if @readbytes < @datasize
      @readbytes += Buffer.byteLength(line)
      # remove trailing newline if necessary
      if @readbytes == @datasize + 1 and line.slice(-1) is "\n"
        @readbytes = @datasize
        line = line.slice(0, -1)
      fs.writeSync(@fd, line)
    if @readbytes >= @datasize
      fs.closeSync @fd
      @ready = true


  open: (forceActive = false) ->
    #atom.focus()
    row = 0
    col = 0
    try
      row = cursors[@tempfile].row
      col = cursors[@tempfile].column
    catch error
    if !isFromTTS(globals.activeEditorPath)
      globals.activeEditorPath = null
    if globals.activeEditorPath
      active = (globals.activeEditorPath == @tempfile)
    else
      active = isGlobalScript(@tempfile)
    if forceActive
      active = true
    console.log @tempfile, active
    atom.workspace.open(@tempfile, {initialLine: row, initialColumn: col, activatePane: active, activateItem: active}).then (editor) =>
      @handle_connection(editor)


  handle_connection: (editor) ->
    cursorPosition =  editor.getCursorBufferPosition()
    filepath = editor.getPath()
    # Map and remove included files
    if atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFiles')
      text = editor.getText()
      lines = text.split(/\n/)
      tree = fileMap[filepath] = {label: null, children: [], parent: null, startRow: 0, endRow: lines.length-1, depth: 0, closeTag: ''}
      output = []
      for line, row in lines
        found = line.match(insertedFileRegexp)
        #console.log tree
        if found
          dir = null
          if tree.label
            dir = path.dirname(tree.label)
          label = completeFilepath(found[2], dir)
          if found[2] == tree.closeTag #closing include
            tree.endRow = row
            tree = tree.parent
            if tree.parent == null
              output.push(found[1])
          else #opening include
            tree.children.push({label: label, children: [], parent: tree, startRow: row + 1, endRow: null, depth: tree.depth + 1, closeTag: found[2]})
            tree = tree.children[tree.children.length-1]
            if not (label of appearsInFile)
              appearsInFile[label] = {}
            appearsInFile[label][filepath] = tree.depth
        else if tree.parent == null
          output.push(line)
      editor.setText(output.join('\n'))

    # // REMOVED 2018.03.23: Atom no longer supports \u regexes, and this feature is no longer needed since TTS supports unicode intrinsically
    # Replace \u character codes
    #if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')
    #  replace_unicode = (unicode) ->
    #    unicode.replace(String.fromCharCode(parseInt(unicode.match[1],16)))
    #  editor.scan(/\\x\{([a-zA-Z0-9]{1,4})\}/g, replace_unicode)

    if editor.isModified()
      editor.save()

    # Restore cursor position (may have been curtailed due to include)
    try
      editor.setCursorBufferPosition(cursors[filepath])
    catch error
      editor.setCursorBufferPosition(cursorPosition)
    editor.scrollToCursorPosition()

    buffer = editor.getBuffer()
    @subscriptions = new CompositeDisposable
    @subscriptions.add buffer.onDidSave =>
      @save()
    @subscriptions.add buffer.onDidDestroy =>
      @close()

  save: ->

  close: ->
    @subscriptions.dispose()


readFilesFromTTS = (files, forceOpen = false) ->
  toOpen = []
  @files_opened = []

  for f, i in files
    @file = new FileHandler()
    f.name = f.name.replace(/([":<>/\\|?*])/g, "")
    if f.guid == "-2"
      @file.setBasename(f.name + "." + f.guid + ".xml")
    else
      @file.setBasename(f.name + "." + f.guid + ".ttslua")
    @file.setDatasize(lengthInUtf8Bytes(f.script))
    @file.create()

    lines = f.script.split(/\n/)
    for line,i in lines
      if i < lines.length-1
        line = line + "\n"
      @file.append(line)
    mode = atom.config.get('tabletopsimulator-lua.loadSave.communicationMode')
    if forceOpen or mode == 'all' or (mode == 'global' and isGlobalScript(@file.basename)) or ttsEditors[@file.basename]
      toOpen.push(@file)
    @file = null

  if toOpen.length == 1
    toOpen[0].open(true)
  else
    toOpen.sort (a, b) ->
      if isGlobalScript(a.tempfile)
        return 1
      else if isGlobalScript(b.tempfile)
        return -1
      else
        return if a.tempfile < b.tempfile then 1 else -1

    openFilesInOrder = (files) ->
      file = files.shift()
      if file
        file.open().then =>
          openFilesInOrder(files)

    openFilesInOrder(toOpen)


deleteCachedFiles = () ->
  try
    for oldfile,i in fs.readdirSync(ttsLuaDir)
      deletefile = path.join(ttsLuaDir, oldfile)
      fs.unlinkSync(deletefile)
  catch error


module.exports = TabletopsimulatorLua =
  subscriptions: null
  config:
    loadSave:
      title: 'Loading/Saving'
      type: 'object'
      order: 1
      properties:
        communicationMode:
          title: 'Communication with Tabletop Simulator'
          description: 'Should Atom automatically open files received from the game?'
          order: 1
          type: 'string'
          default: 'all'
          enum: [
            {value: 'all',     description: 'Automatically open all files sent from Tabletop Simulator'}
            {value: 'global',  description: 'Only automatically open the Global script file'}
            {value: 'none',    description: 'Do not automatically open any files sent from Tabletop Simulator'}
            {value: 'disable', description: 'DISABLE: Do not communicate with Tabletop Simulator at all (requires restart when switching to/from this option)'}
          ]
    #    convertUnicodeCharacters:
    #      title: 'Convert between unicode characters and \\u{xxxx} escape sequences when loading/saving'
    #      description: 'When loading from TTS automatically convert to unicode character from instances of ``\\u{xxxx}``.  When saving to TTS do the reverse.  e.g. it will convert ``é`` from/to ``\\u{00e9}``'
    #      order: 2
    #      type: 'boolean'
    #      default: true
        openOtherFiles:
          title: 'Ignore files from outwith the TTS folder'
          description: 'When you Save And Play do not close files which are not in the TTS temp folder'
          order: 2
          type: 'boolean'
          default: true
        includeOtherFiles:
          title: 'Insert other files specified in source code'
          description: 'Convert lines containing ``#include <FILE>`` with text from the file specified'
          order: 3
          type: 'boolean'
          default: true
        includeOtherFilesPath:
          title: 'Base path for files you wish to #include'
          description: 'Start with ``~`` to represent your user folder.  If left blank will default to ``~' + PATH_SEPERATOR + 'Documents' + PATH_SEPERATOR + 'Tabletop Simulator' + PATH_SEPERATOR + '``' + '.  You may refer to this path explicitly in your code by starting your #include path with ``!' + PATH_SEPERATOR + '``'
          order: 4
          type: 'string'
          default: ''
        delayLinter:
          title: 'Delay Linter When Loading'
          description: 'Delay in ``ms`` before linting a newly loaded file.'
          order: 5
          type: 'integer'
          default: 0
          minimum: 0
    autocomplete:
      title: 'Autocomplete'
      order: 2
      type: 'object'
      properties:
        excludeLowerPriority:
          title: 'Only autocomplete API suggestions'
          order: 1
          description: 'This will disable the default autocomplete provider and any other providers with a lower priority; try unticking it - you might like it!'
          type: 'boolean'
          default: true
        parameterToDisplay:
          title: 'Function Parameters'
          description: 'This will determine how autocomplete inserts parameters into your script'
          order: 2
          type: 'string'
          default: 'type'
          enum: [
            {value: 'none', description: 'Do not insert most parameters'}
            {value: 'type', description: 'Insert parameters as TYPE'}
            {value: 'name', description: 'Insert parameters as NAME'}
            {value: 'both', description: 'Insert parameters as TYPE & NAME'}
          ]
    style:
      title: 'Style'
      order: 3
      type: 'object'
      properties:
        parameterFormat:
          title: 'Parameter TYPE & NAME Format'
          description: "If you select ``TYPE & NAME`` above it will format like this. You may vary the case, e.g. ``typeName`` or ``name <TYPE>``"
          order: 1
          type: 'string'
          default: 'type_name'
        coroutinePostfix:
          title: 'Coroutine Postfix'
          description: "When automatically creating an internal coroutine function this is appended to the parent function's name"
          order: 2
          type: 'string'
          default: '_routine'
        guidPostfix:
          title: 'GUID Postfix'
          description: "When guessing the getObjectFromGUID parameter this is appended to the name of the variable being assigned to"
          order: 3
          type: 'string'
          default: '_GUID'
        guidCodeGeneration:
          title: 'Generate GUID Code'
          description: "When automatically generating GUID code, format the variable name like this.  Can use ``(Field)`` ``(field)`` or ``(FIELD)``to refer to object properties, ``(FIELD:#)`` to limit to ``#`` characters, ``(FIELD?xxx:yyy)`` to insert ``xxx`` if FIELD is present and ``yyy`` if it's not.  Fields: ``Name`` ``Nickname`` ``Description`` ``Tooltip``.  ``[from:to]`` will replace ``from`` with ``to``"
          order: 4
          type: 'string'
          default: '(name)_(nickname:12)[die_:d][scriptingtrigger:zone][custom_:][game_piece_:][infinite_:][fogofwartrigger:hidden]'
    editor:
      title: 'Editor'
      order: 4
      type: 'object'
      properties:
        errorPopup:
          title: 'Report TTS messages in pop-up'
          order: 1
          description: 'Display Atom notifications for run-time errors (with button to jump to offending line) and return values.'
          type: 'string'
          default: 'flash'
          enum: [
            {value: 'off', description: 'Off: simply log message to the developer console'}
            {value: 'flash', description: 'Display a notification for a few seconds'}
            {value: 'close', description: 'Display a notification which user must close'}
          ]
        highlightGUIDObject:
          title: 'Highlight GUID object in TTS'
          order: 2
          description: 'When the cursor is on a row which contains a GUID string, highlight the object in TTS'
          type: 'boolean'
          default: true
        showFunctionName:
          title: 'Show function name in status bar'
          order: 3
          description: 'Display the name of the function the cursor is currently inside'
          type: 'boolean'
          default: true
        showFunctionInGoto:
          title: 'Show ``function`` prefix during Go To Function'
          order: 4
          description: 'Prefix all function names with the keyword \'function\' when using the Go To Function command.'
          type: 'boolean'
          default: true
    panel:
      title: 'Tabletop Simulator Panel'
      order: 5
      type: 'object'
      properties:
        watchListLength:
          title: 'Watch List Entries'
          description: 'Number of rows in watch list table (requires restart)'
          order: 1
          type: 'integer'
          default: 8
    hacks:
      title: 'Hacks (Experimental!)'
      order: 6
      type: 'object'
      properties:
        incrementals:
          title: 'Expand Compound Assignments'
          description: 'Convert operators +=, -=, etc. into their Lua equivalents'
          order: 1
          type: 'string'
          default: 'off'
          enum: [
            {value: 'off', description: 'Disabled'}
            {value: 'on', description: 'Enabled'}
            {value: 'spaced', description: 'Enabled (add spacing)'}
          ]



  activate: (state = {visible: false, watchList: []}) ->
    # See if there are any Updates
    @updatePackage()

    # TODO
    # 23/07/17 - config settings moved into groups.  This will orphan their old
    # settings in user's config file if they had set them to non-default values.
    # i.e. they'll be confusingly visible in settings until removed.  This code
    # will remove them, but after a small amount of time has passed (and most
    # users have updated) everyone will be clean and this will no longer be
    # needed: remove this code at that point.
    if atom.config.get('tabletopsimulator-lua.convertUnicodeCharacters') != undefined
      atom.config.unset('tabletopsimulator-lua.convertUnicodeCharacters')
    if atom.config.get('tabletopsimulator-lua.parameterToDisplay') != undefined
      atom.config.set('tabletopsimulator-lua.autocomplete.parameterToDisplay', atom.config.get('tabletopsimulator-lua.parameterToDisplay'))
      atom.config.unset('tabletopsimulator-lua.parameterToDisplay')
    # 30/10/17 - same for openGlobalOnly
    if atom.config.get('tabletopsimulator-lua.loadSave.openGlobalOnly') != undefined
      if atom.config.get('tabletopsimulator-lua.loadSave.openGlobalOnly')
        atom.config.set('tabletopsimulator-lua.loadSave.communicationMode', 'global')
      else
        atom.config.set('tabletopsimulator-lua.loadSave.communicationMode', 'all')
      atom.config.unset('tabletopsimulator-lua.loadSave.openGlobalOnly')
    # 23/03/18 - removed convertUnicodeCharacters
    if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters') != undefined
      atom.config.unset('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')

    # Dynamic Editor settings
    @highlightGUIDObject = atom.config.get('tabletopsimulator-lua.editor.highlightGUIDObject')

    # Code awaiting return value from TTS
    @returnIDs = {}

    # StatusBarFunctionView to display current function in status bar
    @statusBarFunctionView = new StatusBarFunctionView()
    @statusBarFunctionView.init()
    @statusBarActive = atom.config.get('tabletopsimulator-lua.editor.showFunctionName')
    @statusBarPreviousPath = ''
    @statusBarPreviousRow  = 0

    # Function name lookup
    @functionByName = {}
    @functionPaths = {}

    # JSON of currently loaded mod save file
    @savePath = ""
    @guids = {}

    # Set font for Go To Function UI
    styleSheetSource = atom.styles.styleElementsBySourcePath['global-text-editor-styles'].textContent
    fontFamily = atom.config.get('editor.fontFamily')
    styleSheetSource += """

      .tabletopsimulator-lua-goto-function {
        font-family: #{fontFamily};
      }
      .tabletopsimulator-lua-goto-function .right {
        float: right;
      }
    """
    atom.styles.addStyleSheet(styleSheetSource, sourcePath: 'global-text-editor-styles')
    @blockSelectLock = false
    @isBlockSelecting = false

    # Tabletop Simulator panel
    @ttsPanelView = new TTSPanelView(state, @executeLua, atom.config.get('tabletopsimulator-lua.panel.watchListLength'), @checkLua)
    @ttsPanelView.setState(state)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:getObjects': => @getObjects()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:saveAndPlay': => @saveAndPlay()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:gotoLastError': => @gotoLastError()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:gotoFunction': => @gotoFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:jumpToFunction': => @jumpToCursorFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:selectFunction': => @selectCurrentFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:expandSelection': => @expandSelection()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:retractSelection': => @retractSelection()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:toggleSelectionCursor': => @toggleCursorSelectionEnd()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:displayCurrentFunction': => @displayFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:openHelp': => @openHelp()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:generateGUIDFunction': => @generateGUIDFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:executeLuaSelection': => @executeLuaSelection()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:openSaveFile': => @openSaveFile()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:toggleTTSPanel': => @toggleTTSPanel()

    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:testMessage': => @testMessage()

    # Register events
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.autocomplete.excludeLowerPriority', (newValue) => @excludeChange()
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.editor.showFunctionName', (newValue) => @showFunctionChange()
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.editor.highlightGUIDObject', (newValue) => @highlightGUIDObjectChange()
    @subscriptions.add atom.workspace.onDidOpen (event) => @onLoad(event)
    @subscriptions.add atom.workspace.observeTextEditors (editor) =>
      @subscriptions.add editor.onDidChangeCursorPosition (event) =>
        @cursorChangeEvent(event)
      @subscriptions.add editor.onDidSave (event) =>
        @onSave(event)

    # Close any open files
    #for editor,i in atom.workspace.getTextEditors()
    #  try
    #    #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
    #    editor.destroy()
    #  catch error
    #    console.log error
    destroyTTSEditors()

    # Delete any existing cached Lua files
    deleteCachedFiles()

    # Start server to receive push information from Unity
    @startServer()


  deactivate: ->
    @subscriptions.dispose()
    @statusBarFunctionView.destroy()
    @statusBarTile?.destroy()


  onLoad: (event) ->
    editor = event.item
    if not atom.workspace.isTextEditor(editor)
      return
    filepath = editor.getPath()
    if filepath and filepath.endsWith('.ttslua')
      if not (filepath of @functionPaths)
        @doCatalog(editor.getText(), filepath, !isFromTTS(filepath))
      linterDelay = atom.config.get('tabletopsimulator-lua.loadSave.delayLinter')
      if linterDelay > 0
        view = atom.views.getView(editor)
        atom.commands.dispatch(view, 'linter:toggle')
        f = () ->
          atom.commands.dispatch(view, 'linter:toggle')
          atom.commands.dispatch(view, 'linter:lint')
        setTimeout f, linterDelay


  onSave: (event) ->
    if not event.path.endsWith('.ttslua')
      return
    for editor in atom.workspace.getTextEditors()
      if editor.getPath() == event.path
        @doCatalog(editor.getText(), event.path)
        break


  doCatalog: (text, filepath, includeSiblings = false) ->
    otherFiles = @catalogFunctions(text, filepath)
    if atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFiles')
      if includeSiblings
        files = fs.readdirSync(path.dirname(filepath))
        for filename in files
          filename = path.join(path.dirname(filepath), filename)
          if filename.endsWith('.ttslua') and not fs.statSync(filename).isDirectory()
            otherFiles[filename] = true
      for otherFile of otherFiles
        if fs.existsSync(otherFile)
          if not (otherFile of @functionPaths)
            a = 0
            @catalogFileFunctions(otherFile)
        else
          atom.notifications.addError("Could not catalog #include - file not found:", {icon: 'type-file', detail: otherFile, dismissable: true})


  cursorChangeEvent: (event) ->
    if event
      if @isBlockSelecting and not @blockSelectLock
        @isBlockSelecting = false
      editor = event.cursor.editor
      if editor
        filepath = editor.getPath()
        isTTS = filepath and filepath.endsWith('.ttslua')
      else
        isTTS = false
      if @statusBarActive
        if not editor or not filepath or not isTTS
          @statusBarFunctionView.updateFunction(null)
        else
          if filepath == @statusBarPreviousPath and event.newBufferPosition.row == @statusBarPreviousRow
            return
          else
            [names, rows] = @getFunctions(editor, event.newBufferPosition.row)
            @statusBarFunctionView.updateFunction(names, rows)
      if @highlightGUIDObject and isTTS
        line = editor.lineTextForBufferRow(event.newBufferPosition.row)
        guid_pattern = /(['"][a-zA-Z0-9]{6}['"])/
        m = line.match(guid_pattern)
        if m
          if event.cursor.isAtBeginningOfLine()
            guid = m[1]
          else if event.cursor.isAtEndOfLine()
            c = line.length
            while c > 0
              m = line.substring(c).match(guid_pattern)
              if m
                break
              c -= 1
            if m
              guid = m[1]
            else
              guid = "********"
          else
            c = event.newBufferPosition.column
            while c > 0 and line[c].match(/[a-zA-Z0-9"']/)
              c -= 1
            m = line.substring(c).match(guid_pattern)
            if m
              guid = m[1]
            else
              while c > 0
                m = line.substring(c).match(guid_pattern)
                if m
                  break
                c -= 1
              if m
                guid = m[1]
              else
                guid = "********"
          guid = guid.substring(1, 7)
          if guid of @guids
            duration = 3
            if @guids[guid].Name.indexOf("Trigger") != -1 # is a zone
              transform = @guids[guid].Transform
              @executeLua("""
                  Physics.cast({
                    origin       = {x=#{transform.posX}, y=#{transform.posY}, z=#{transform.posZ}},
                    direction    = {x=0, y=0, z=0},
                    type         = 3,
                    size         = {x=#{transform.scaleX}, y=#{transform.scaleY}, z=#{transform.scaleZ}},
                    orientation  = {x=#{transform.rotX}, y=#{transform.rotY}, z=#{transform.rotZ}},
                    max_distance = 30,
                    debug        = true,
                  })
                  if __atom_highlight_guids ~= nil then __atom_highlight_guids.end_time = 0 end
                """)
            else
              @executeLua("""
                if __atom_highlight_guids == nil then
                  __atom_highlight_guids = {}
                end
                __atom_highlight_guids.next_guid = '#{guid}'
                __atom_highlight_guids.end_time  = os.clock() + #{duration}
                if __atom_highlight_guid == nil then
                  __atom_highlight_guid = function()
                    local start_time = os.clock()
                    local object
                    repeat
                      if __atom_highlight_guids.current ~= __atom_highlight_guids.next_guid then
                        if object then object.highlightOff() end
                        __atom_highlight_guids.current = __atom_highlight_guids.next_guid
                        object = getObjectFromGUID(__atom_highlight_guids.current)
                      end
                      if object then
                        object.highlightOn({r=math.random(),g=math.random(),b=math.random()})
                      end
                      coroutine.yield(0)
                    until os.clock() > __atom_highlight_guids.end_time
                    if object then object.highlightOff() end
                    _G['__atom_highlight_guids'] = nil
                    _G['__atom_highlight_guid'] = nil
                    return 1
                  end
                  startLuaCoroutine(Global, '__atom_highlight_guid')
                end
              """)


  highlightGUIDObjectChange: (newValue) ->
    @highlightGUIDObject = atom.config.get('tabletopsimulator-lua.editor.highlightGUIDObject')


  getFunctions: (editor, startRow) ->
    line = editor.lineTextForBufferRow(startRow)
    m = line.match(/^function ([^(]*)/)
    if m # on row of root function
      return [[m[1]], [startRow]]
    else
      function_names = {}
      function_rows = {}
      row = startRow - 1
      while (row >= 0)
        line = editor.lineTextForBufferRow(row)
        m = line.match(/^end($|\s|--)/)
        if m #in no function
          return [null, null]
        m = line.match(/^function ([^(]*)/)
        if m # root function found
          function_names[0] = m[1]
          function_rows[0] = row
          break
        row -= 1
      root_row = row
      row += 1
      while row <= startRow
        line = editor.lineTextForBufferRow(row)
        m = line.match(/^(\s*)function\s+([^\s(]*)/)
        if m
          indent = m[1].length
          if not(indent of function_names)
            function_names[indent] = m[2]
            function_rows[indent]  = row
        else if row < startRow
          m = line.match(/^(\s*)end($|\s|--)/)
          if m #previous function may have ended
            indent = m[1].length
            if indent of function_names
              delete function_names[indent]
              delete function_rows[indent]
        row += 1
      keys = []
      for k,v of function_names
        keys.push(k)
      keys.sort (a, b) ->
        return if parseInt(a) >= parseInt(b) then 1 else -1
      names = []
      rows = []
      for indent in keys
        names.push(function_names[indent])
        rows.push(function_rows[indent])
      return [names, rows]


  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile(item: @statusBarFunctionView, priority: 2)


  serialize: ->
    return @ttsPanelView.getState()


  getProvider: -> provider


  # Adapted from https://github.com/yujinakayama/atom-auto-update-packages
  updatePackage: (isAutoUpdate = true) ->
    @runApmUpgrade()


  runApmUpgrade: (callback) ->
    command = atom.packages.getApmPath()
    args = ['upgrade', '--no-confirm', '--no-color', 'tabletopsimulator-lua']

    stdout = (data) ->
      console.log "Checking for tabletopsimulator-lua updates:\n" + data

    exit = (exitCode) ->
      # Reload package - reloaded the old version, not the new updated one
      ###
      pkgModel = atom.packages.getLoadedPackage('tabletopsimulator-lua')
      pkgModel.deactivate()
      pkgModel.mainModule = null
      pkgModel.mainModuleRequired = false
      pkgModel.reset()
      pkgModel.load()
      checkedForUpdate = true
      pkgModel.activate()
      ###

      #atom.reload()

    new BufferedProcess({command, args, stdout, exit})


  openHelp: ->
    shell.openExternal('https://github.com/Knils/atom-tabletopsimulator-lua/wiki')


  toggleTTSPanel: ->
    @ttsPanelView.toggle()


  getObjects: ->
    if atom.config.get('tabletopsimulator-lua.loadSave.communicationMode') == 'disable'
      return
    # Confirm just in case they misclicked Save & Play
    atom.confirm
      message: 'Get Lua Scripts from game?'
      detailedMessage: 'This will erase any local changes that you may have done.'
      buttons:
        Yes: ->
          #console.log "Request at", Date.now()
          destroyTTSEditors()

          # Delete any existing cached Lua files
          deleteCachedFiles()

          # Add temp dir to atom
          atom.project.addPath(ttsLuaDir)

          if not TabletopsimulatorLua.if_connected
            TabletopsimulatorLua.startConnection()
          TabletopsimulatorLua.connection.write '{ messageID: ' + ATOM_MSG_GET_SCRIPTS + ' }'
        No: -> return


  # hack needed because atom 1.19 makes save() async
  blocking_save: (editor) =>
    if async_save
      if editor.isModified()
        return Promise.resolve(editor.save())
      else
        return Promise.resolve(editor.getBuffer())
    else
      console.log "Non-async save"
      try
        editor.save()
      catch error
      return Promise.resolve(editor.getBuffer())


  saveAndPlay: ->
    if atom.config.get('tabletopsimulator-lua.loadSave.communicationMode') == 'disable'
      return
    if mutex.doingSaveAndPlay
      return
    mutex.doingSaveAndPlay = true
    #clear this after some time in case a problem occured during save and play
    f = () ->
      mutex.doingSaveAndPlay = false
    setTimeout f, 3000

    # Save any open files
    openFiles = 0
    savedFiles = 0
    editors = []
    ttsEditors = {}
    for editor,i in atom.workspace.getTextEditors()
      openFiles += 1
      # Store cursor positions
      cursors[editor.getPath()] = editor.getCursorBufferPosition()
      if isFromTTS(editor.getPath())
        ttsEditors[path.basename(editor.getPath())] = true
      else
        editors.push(editor.getPath())

    console.log "Starting to save..."

    for editor, i in atom.workspace.getTextEditors()
      @blocking_save(editor).then (buffer) =>
        console.log buffer.getPath(), buffer.isModified()
        savedFiles += 1
        if savedFiles == openFiles
          console.log "All done!"
          # This is a horrible hack I feel - we see how many editors are open, then
          # run this block after each save, but only do the below code if the
          # number of files we have saved is the number of files open.  Urgh.

          # Read all files into JSON object
          @luaObjects = {}
          @luaObjects.messageID = 1
          @luaObjects.scriptStates = []
          @luafiles = fs.readdirSync(ttsLuaDir)
          for luafile,i in @luafiles
            fname = path.join(ttsLuaDir, luafile)
            if not fs.statSync(fname).isDirectory()
              @luaObject = {}
              tokens = luafile.split "."
              @luaObject.name = luafile
              @luaObject.guid = tokens[tokens.length-2]
              @luaObject.script = fs.readFileSync(fname, 'utf8')
              # Insert included files
              if atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFiles')
                @luaObject.script = @insertFiles(@luaObject.script)
              # TODO this section commented out because TTS now handles unicode correctly
              # When setting is enabled we still convert \u codes to utf8 when loading
              # but we no longer write \u codes to TTS.
              # This setting should be removed entirely at a future date
              #if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')
              # Replace with \u character codes
              #  replace_character = (character) ->
              #    return "\\u{" + character.codePointAt(0).toString(16) + "}"
              #  @luaObject.script = @luaObject.script.replace(/[\u0080-\uFFFF]/g, replace_character)
              @luaObjects.scriptStates.push(@luaObject)

          destroyTTSEditors()
          deleteCachedFiles()

          console.log "Connected:", @if_connected
          if not @if_connected
            @startConnection()
          try
            @connection.write JSON.stringify(@luaObjects)
          catch error
            console.log error


  insertFiles: (text, dir = null, alreadyInserted = {}) ->
    lines = text.split(/\n/)
    for line, i in lines
      found = line.match(insertFileRegexp)
      if found
        filepath = completeFilepath(found[2], dir)
        filetext = null
        if fs.existsSync(filepath)
          try
            filetext = fs.readFileSync(filepath, 'utf8')
          catch error
            atom.notifications.addError(error.message, {dismissable: true, icon: 'type-file', detail: filepath})
        else
          atom.notifications.addError("Could not catalog #include - file not found:", {icon: 'type-file', detail: filepath})
        if filetext
          if filepath of alreadyInserted
            atom.notifications.addWarning(atom.config.get('tabletopsimulator-lua.loadSave.includeKeyword') + " used for same file twice.", {dismissable: true, icon: 'type-file', detail: filepath})
            lines[i] = ''
          else
            alreadyInserted[filepath] = true
            #filetext = filetext.replace(/[\s\n\r]*$/gm, '')
            marker = '----' + found[1]
            newDir = path.dirname(filepath)
            lines[i] = marker + '\n' + @insertFiles(filetext, newDir, alreadyInserted) + '\n' + marker
        else
          marker = '----' + found[1]
          lines[i] = marker + '\n' + marker
    return lines.join('\n')


  excludeChange: (newValue) ->
    provider.excludeLowerPriority = atom.config.get('tabletopsimulator-lua.autocomplete.excludeLowerPriority')


  showFunctionChange: (newValue) ->
    @statusBarActive = atom.config.get('tabletopsimulator-lua.editor.showFunctionName')
    if not @statusBarActive
      @statusBarFunctionView.updateFunction(null)


  displayFunction: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith('.ttslua')
      return
    row = editor.getCursorBufferPosition().row
    [names, rows] = @getFunctions(editor, row)
    if names == null
      info = "Not in a function!"
    else
      info = 'Function: `'
      for name, i in names
        if i > 0
          info += ' → '
        info += name
        row = rows[i]
      info += '`'
    filepath = editor.getPath()
    details = path.basename(filepath) + " line " + (row + 1)
    walkFileMap = (filepath, node) ->
      if node.label == filepath
        return [true, node.startRow]
      else
        for child in node.children
          [found, r] = walkFileMap(filepath, child)
          if found
            return [true, r]
        return [false, 0]
    if filepath of appearsInFile
      for parentFilePath of appearsInFile[filepath]
        [found, parentRow] = walkFileMap(filepath, fileMap[parentFilePath])
        if found
          details += '\n' + path.basename(parentFilePath) + " line " + (parentRow + row + 1)
    atom.notifications.addInfo(info, {icon: 'type-function', detail: details})


  gotoFunction: ->
    editor = atom.workspace.getActiveTextEditor()
    text = editor.getSelectedText()
    if not text.match(/^\w+$/)
      text = ''
    @functionListView = new FunctionListView(@functionByName, fileMap[editor.getPath()]).toggle(text)


  catalogFileFunctions: (filepath) ->
    if not (filepath of @functionPaths)
      text = fs.readFileSync(filepath, 'utf8')
      otherFiles = @catalogFunctions(text, filepath, path.dirname(filepath))
      for otherFile of otherFiles
        if not (otherFile of @functionPaths)
          @catalogFileFunctions(otherFile)


  catalogFunctions: (text, filepath, root = null) ->
    @functionPaths[filepath] = {}
    otherFiles = {}
    stack = []
    lines = text.split(/\n/)
    closingTag = []
    if not isFromTTS(filepath) and root == null
      root = path.dirname(filepath)
    if atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFiles')
      for line, row in lines
        if stack.length == 0
          dir = root
        else
          dir = path.dirname(stack[stack.length-1])
        insert = line.match(insertFileRegexp)
        if insert
          label = completeFilepath(insert[2], dir)
          otherFiles[label] = true
        else
          inserted = line.match(insertedFileRegexp)
          if inserted
            label = completeFilepath(inserted[2], dir)
            if closingTag.length > 0 and inserted[2] == closingTag[closingTag.length - 1]
              stack.pop()
              closingTag.pop()
            else #opening marker
              if not (label of @functionPaths)
                otherFiles[label] = true
              stack.push(label)
              closingTag.push(inserted[2])
          else
            if not stack.length
              m = line.match(/^\s*function\s+([^\s\(]+)\s*\(([^\)]*)\)/)
              if m
                functionDescription = {functionName: m[1], parameters: m[2], line: row, filepath: filepath}
                @functionByName[functionDescription.functionName] = functionDescription
                @functionPaths[filepath][functionDescription.functionName] = row
    else
      for line, row in lines
        m = line.match(/^\s*function\s+([^\s\(]+)\s*\(([^\)]*)\)/)
        if m
          functionDescription = {functionName: m[1], parameters: m[2], line: row, filepath: filepath}
          @functionByName[functionDescription.functionName] = functionDescription
          @functionPaths[filepath][functionDescription.functionName] = row
    return otherFiles


  jumpToCursorFunction: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith(".ttslua")
      return
    function_name = editor.getWordUnderCursor()
    if not function_name
      return
    function_name = function_name.match(/\w*/)[0]
    if function_name == ''
      return
    if function_name of @functionByName
      item = @functionByName[function_name]
      if editor.getPath() == item.filepath
          editor.setCursorBufferPosition([item.line, 0])
          editor.scrollToCursorPosition()
      else if item.filepath
        #console.log "Opening Jumped-to file", item.filepath
        atom.workspace.open(item.filepath, {initialLine: item.line, initialColumn: 0}).then (other) ->
          other.setCursorBufferPosition([item.line, 0])
          other.scrollToCursorPosition()
    else
      # If we didn't find it then open Go To Function panel
      editor.selectWordsContainingCursors()
      @gotoFunction()


  gotoLastError: ->
    gotoError(lastError.message, lastError.guid)


  getFunctionRow: (text, function_name) ->
    #deprecated: TODO remove
    lineCount = editor.getLineCount()
    row = 0
    while (row < lineCount)
      line = editor.lineTextForBufferRow(row)
      re = new RegExp('^\\s*function\\s+' + function_name + '\\s*\\(')
      m = line.match(re)
      if m
        return row
      row += 1
    return null


  selectCurrentFunction: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith(".ttslua")
      return
    pos = editor.getCursorBufferPosition()
    row = pos.row
    line = editor.lineTextForBufferRow(row)
    m = line.match(/^(\s*)function/)
    if m and @isBlockSelecting and @blockSelectTop == row
      if row == 0 or @blockSelectIndent == 0
        return
      row -= 1
    [names, rows] = @getFunctions(editor, row)
    if rows
      row = rows[rows.length-1]
      startRow = row
      lastRow = editor.getLastBufferRow()
      line = editor.lineTextForBufferRow(row)
      m = line.match(/^(\s*)function/)
      indent = m[1].length
      while row <= lastRow
        line = editor.lineTextForBufferRow(row)
        m = line.match(/^(\s*)end($|\s|--)/)
        if m and m[1].length == indent
          if @isBlockSelecting
            previousBlock = [@blockSelectTop, @blockSelectBottom, @blockSelectIndent, @blockSelectUntilBlank]
            @blockSelectStack.push(previousBlock)
          else
            @blockSelectCursorPosition = pos
            @blockSelectStack = []
            @isBlockSelecting = true
          @blockSelectTop = startRow
          @blockSelectBottom = row
          @blockSelectIndent = indent
          @blockSelectUntilBlank = false
          @blockSelectLock = true
          editor.setCursorBufferPosition([@blockSelectBottom, editor.lineTextForBufferRow(@blockSelectBottom).length])
          editor.selectToBufferPosition([@blockSelectTop, 0])
          @blockSelectLock = false
          editor.scrollToCursorPosition()
          return
        row += 1


  expandSelection: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith(".ttslua")
      return
    cursor = editor.getLastCursor()
    pos = cursor.getBufferPosition()
    if not @isBlockSelecting
      @blockSelectCursorPosition = pos
      @blockSelectStack = []
      row = pos.row
      blankRow = false
      while row >= 0
        line = editor.lineTextForBufferRow(row)
        #m = line.match(/^(\s*)(if[\s\(]|for[\s\(]|while[\s\(]|repeat($|\s|--)|function[\s])/) #strict control blocks
        m = line.match(/^(\s*)([^\s]+)/)
        if m and not m[2].match(/^(else|elseif|--.*)/)
          if m[1].length == 0 and not m[2].match(/^(function|end($|\s|--))/)
              @blockSelectIndent = 1
              @blockSelectTop = row + 1
              @blockSelectBottom = pos.row
              @blockSelectUntilBlank = true
          else
            @blockSelectUntilBlank = false
            n = editor.lineTextForBufferRow(row+1).match(/^(\s*)([^\s]+)/)
            if n and n[1].length > m[1].length
              @blockSelectIndent = n[1].length
              @blockSelectTop = row + 2
              @blockSelectBottom = pos.row
            else
              n = editor.lineTextForBufferRow(row-1).match(/^(\s*)([^\s]+)/)
              if n and n[1].length > m[1].length
                @blockSelectIndent = n[1].length
                @blockSelectTop = row
                @blockSelectBottom = pos.row - 2
              else
                if blankRow and m[2].match(/^(if($|\()|for($|\()|while($|\()|repeat($|--)|function$)/)
                  @blockSelectIndent = m[1].length + 1
                else
                  @blockSelectIndent = m[1].length
                @blockSelectTop = row + 1
                @blockSelectBottom = pos.row - 1
          break
        else
          blankRow = true
        row -= 1
      if row < 0
        return
    if @blockSelectIndent == 0
      return
    previousBlock = [@blockSelectTop, @blockSelectBottom, @blockSelectIndent, @blockSelectUntilBlank]
    row = @blockSelectTop - 1
    while row >= 0
      line = editor.lineTextForBufferRow(row)
      #m = line.match(/^(\s*)(if[\s\(]|for[\s\(]|while[\s\(]|repeat($|\s|--)|function[\s])/) #strict control blocks
      if @blockSelectUntilBlank
        m = line.match(/^()(\s*)$/)
      else
        m = line.match(/^(\s*)([^\s]+)/)
      if m and m[1].length < @blockSelectIndent and not m[2].match(/^(else|elseif|--.*)/)
        if @blockSelectUntilBlank
          @blockSelectTop = row + 1
        else
          @blockSelectTop = row
        @blockSelectIndent = m[1].length
        break
      row -= 1
    if row < 0
      return
    row = @blockSelectBottom + 1
    lastRow = editor.getLastBufferRow()
    if @blockSelectUntilBlank and blankRow
      while row < lastRow
        line = editor.lineTextForBufferRow(row)
        m = line.match(/^\s*$/)
        if not m
          break
        row += 1
    while row <= lastRow
      line = editor.lineTextForBufferRow(row)
      #m = line.match(/^(\s*)(end($|\s|--)|until[\s\)])/)  #strict control blocks
      if @blockSelectUntilBlank
        m = line.match(/^()(\s*)$/)
      else
        m = line.match(/^(\s*)([^\s]+)/)
      if m and m[1].length <= @blockSelectIndent and not m[2].match(/^(else|elseif|--.*)/)
        @blockSelectBottom = row
        @blockSelectIndent = m[1].length
        break
      row += 1
    if @isBlockSelecting
      @blockSelectStack.push(previousBlock)
    else
      @isBlockSelecting = true
    @blockSelectLock = true
    editor.setCursorBufferPosition([@blockSelectBottom, editor.lineTextForBufferRow(@blockSelectBottom).length])
    editor.selectToBufferPosition([@blockSelectTop, 0])
    @blockSelectLock = false
    editor.scrollToCursorPosition()


  retractSelection: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith(".ttslua") or not @isBlockSelecting
      return
    if @blockSelectStack and @blockSelectStack.length > 0
      [@blockSelectTop, @blockSelectBottom, @blockSelectIndent] = @blockSelectStack.pop()
      @blockSelectLock = true
      editor.setSelectedBufferRange([[@blockSelectTop, 0], [@blockSelectBottom, editor.lineTextForBufferRow(@blockSelectBottom).length]])
      @blockSelectLock = false
      editor.scrollToCursorPosition()
    else
      if @blockSelectCursorPosition
        editor.setCursorBufferPosition(@blockSelectCursorPosition)
        editor.scrollToCursorPosition()
      @blockSelectCursorPosition = null
      @isBlockSelecting = false


  toggleCursorSelectionEnd: ->
    editor = atom.workspace.getActiveTextEditor()
    if not editor or not editor.getPath().endsWith(".ttslua")
      return
    selected = editor.getSelectedBufferRange()
    if selected
      position = editor.getCursorBufferPosition()
      if position.row == selected.start.row and position.column == selected.start.column
        editor.setCursorBufferPosition(selected.start)
        editor.selectToBufferPosition(selected.end)
      else
        editor.setCursorBufferPosition(selected.end)
        editor.selectToBufferPosition(selected.start)
      editor.scrollToCursorPosition()


  generateGUIDFunction: () ->
    editor = atom.workspace.getActiveTextEditor()
    insert = (tags, guids, func) ->
      s = ""
      pre = ""
      fields = ['Name', 'Nickname', 'Description', 'Tooltip']
      format = atom.config.get('tabletopsimulator-lua.style.guidCodeGeneration')
      replacements = {}
      get_replacements = (s) ->
        s = s.slice(1, -1)
        [f, t] = s.split(':', 2)
        replacements[f] = t
        return ''
      format = format.replace(/\[[^\]:]+:[^\]:]*\]/g, get_replacements)
      formats = {}
      for field in fields
        formats[field] = {field: field, f: (s) -> s}
        formats[field.toLowerCase()] = {field: field, f: (s) -> s.toLowerCase()}
        formats[field.toUpperCase()] = {field: field, f: (s) -> s.toUpperCase()}
      if func
        s += "function getGUIDs()\n"
        pre = editor.getTabText()
      i = 0
      for tag of tags
        if tags[tag]
          i += 1
          if i > 1
            s += "\n"
          rows = []
          maxlen = 0
          for guid of guids
            desc = guids[guid]
            if desc.tag == tag
              format_field = (s) ->
                s = s.slice(1, -1)
                if '?' in s
                  [s, present, missing] = s.split(/[?:]/, 3)
                  if s of formats and formats[s].field of desc and desc[formats[s].field] != ''
                    return present
                  else if missing
                    return missing
                  else
                    return ''
                else
                  chars = 0
                  out = ""
                  if ':' in s
                    [s, chars] = s.split(':', 2)
                    try
                      chars = parseInt(chars)
                  if s of formats
                    out = formats[s].f(desc[formats[s].field]).replace(/[^a-zA-Z0-9_]/g, "")
                    if chars > 0
                      out = out.slice(0, chars)
                  for f of replacements
                    out = out.replace(f, replacements[f])
                  return out
              label = pre + format.replace(/\([^)]+\)/g, format_field)
              post = " = getObjectFromGUID('" + guid + "')\n"
              rows.push({label: label, post: post})
              if label.length > maxlen
                maxlen = label.length
          for row in rows
            label = row.label
            while label.length < maxlen
              label += " "
            s += label + " " + row.post
      if func
        s += "end\n"
      editor.insertText(s, {select: true})
    @checkboxList = new CheckboxList(@guids, editor).toggle(insert)


  parseSavePath: (self, savePath) ->
    self.savePath = savePath
    self.guids = {}
    if savePath == ""
      return
    save = JSON.parse(fs.readFileSync(savePath, 'utf8'))
    walkSave = (node, parent) ->
      nodes = []
      guid = parent
      for k of node
        if k == 'GUID'
          guid = node[k]
          self.guids[guid] = {parent: parent, tag: node.Name, Name: node.Name, Nickname: node.Nickname, Description: node.Description, Transform: node.Transform, Tooltip: node.Tooltip}
        else if typeof node[k] == 'object'
          nodes.push(k)
      for k in nodes
        walkSave(node[k], guid)
    walkSave(save, null)


  handleMessage: (self, data, fromTTS = false) ->
    id = data.messageID
    if data.savePath and data.savePath != undefined
      self.parseSavePath(self, data.savePath)

    if id == TTS_MSG_NONE
      return

    else if id == TTS_MSG_NEW_OBJECTS
      #console.log "Received data from TTS", Date.now()
      readFilesFromTTS(data.scriptStates, fromTTS)
      #console.log "Finished receiving data from TTS", Date.now()

    else if id == TTS_MSG_NEW_GAME
      #console.log "Received data from TTS", Date.now()
      readFilesFromTTS(data.scriptStates)
      #console.log "Finished receiving data from TTS", Date.now()
      mutex.doingSaveAndPlay = false

    else if id == TTS_MSG_PRINT
      console.log data.message

    else if id == TTS_MSG_ERROR
      console.error data.errorMessagePrefix + data.error
      lastError.message = data.error
      lastError.guid = data.guid
      popup = atom.config.get('tabletopsimulator-lua.editor.errorPopup')
      if popup != "off"
        detail = "GUID: " + data.guid
        btns = []
        row_string = data.error.match(/:\(([0-9]*),[^\)]+\):/)
        msg = data.error
        guid = data.guid
        f = () ->
          gotoError(msg, guid)
        if row_string
          detail += "\nRow: " + (parseInt(row_string[1]) - 1)
          btns = [{onDidClick: f, text: "<- Jump to Error"}]
        atom.notifications.addError(data.error, {
          icon: 'puzzle',
          detail: detail,
          dismissable: popup == "close",
          buttons: btns,
        })
      #console.error @data.message

    else if id == TTS_MSG_CUSTOM
      console.log data
      if "messageID" of data.customMessage
        msg = data.customMessage
        if msg.messageID == CUSTOM_MSG_WATCH
          for k, watch of msg.watched
            if watch.error
              self.ttsPanelView.updateValue(k, '-')
            else
              self.ttsPanelView.updateValue(k, watch.result)
        else
          console.log "Unknown custom message: messageID = " + msg.messageID
      else
        console.log data.customMessage

    else if id == TTS_MSG_RETURN
      if data.returnValue
        detail = "Return value: " + data.returnValue
        id = data.returnID
        if self.returnIDs[id]
          console.log {code: self.returnIDs[id], result: data.returnValue}
          self.returnIDs[id] = null
        else
          console.log data.returnValue
      else
        detail = "Nothing returned by code; end with a 'return' statement to return something"
      if typeof(data.returnValue) == 'object'
        detail += "\n\n- You can view and expand the returned object in \nthe dev console (ctrl-shift-i)"
      popup = atom.config.get('tabletopsimulator-lua.editor.errorPopup')
      if popup != "off"
        atom.notifications.addInfo("Code Executed", {
          icon: 'type-function',
          detail: detail,
          dismissable: popup == "close",
        })


  testMessage: ->
    console.log "Sending test message..."
    if not TabletopsimulatorLua.if_connected
      TabletopsimulatorLua.startConnection()
    msg = JSON.stringify({messageID: ATOM_MSG_CUSTOM, customMessage: {test: 1, foo: "bar"}})
    TabletopsimulatorLua.connection.write msg

  executeLuaSelection: ->
    editor = atom.workspace.getActiveTextEditor()
    code = editor.getSelectedText()
    if code == ''
      editor.moveToBeginningOfLine();
      editor.selectToEndOfLine();
      code = editor.getSelectedText()
    ok = true
    try
      luaparse.parse(code)
    catch error
      ok = false
      row = error.line
      column = error.column
      message = error.message
      atom.notifications.addError("Invalid Lua selection:", {icon: 'type-file', detail: "#{message}\nRow: #{row}\nCol: #{column}", dismissable: false})
    if ok
      fn = editor.getPath()
      guid = '-1'
      if isFromTTS(fn)
        guid = getPathGUID(fn)
      @executeLua(code, guid, getExecuteReturnID())

  checkLua: (lua) ->
    ok = true
    try
      luaparse.parse(lua)
    catch error
      ok = false
    return ok

  executeLua: (lua, guid, returnID) ->
    #console.log lua
    if not TabletopsimulatorLua.if_connected
      TabletopsimulatorLua.startConnection()
    msg = {messageID: ATOM_MSG_LUA, guid: '-1', script: lua}
    if guid
      msg.guid = guid
    if returnID
      msg.returnID = returnID
      @returnIDs[returnID] = lua
    TabletopsimulatorLua.connection.write JSON.stringify(msg)

  openSaveFile: ->
    if @savePath != ''
      atom.workspace.open(@savePath)

  startConnection: ->
    if atom.config.get('tabletopsimulator-lua.loadSave.communicationMode') == 'disable'
      return
    if @if_connected
      @stopConnection()

    handleMessage = @handleMessage
    self = this

    @connection = net.createConnection clientport, domain
    @connection.tabletopsimulator = @
    #@connection.parse_line = @parse_line
    @connection.data_cache = ""
    @if_connected = true

    @connection.on 'connect', () ->
      #console.log "Opened connection to #{domain}:#{clientport}"

    @connection.on 'data', (data) ->
      #console.log "Data received", Date.now()
      @data_cache += data
      try
        @data = JSON.parse(@data_cache)
      catch error
        console.log error
        return
      handleMessage(self, @data)
      @data_cache = ""

    @connection.on 'error', (e) ->
      #console.log e
      @tabletopsimulator.stopConnection()

    @connection.on 'end', (data) ->
      #console.log "Connection closed"
      @tabletopsimulator.if_connected = false

  stopConnection: ->
    @connection.end()
    @if_connected = false


  startServer: ->
    if atom.config.get('tabletopsimulator-lua.loadSave.communicationMode') == 'disable'
      return
    handleMessage = @handleMessage
    self = this
    server = net.createServer (socket) ->
      #console.log "New connection from #{socket.remoteAddress}"
      socket.data_cache = ""
      #socket.parse_line = @parse_line

      socket.on 'data', (data) ->
        #console.log "Data received", Date.now()
        @data_cache += data
        try
          @data = JSON.parse(@data_cache)
        catch error
          if !String(error).startsWith("SyntaxError: Unexpected end of JSON input")
            console.log error
          return
        handleMessage(self, @data, true)
        @data_cache = ""

      socket.on 'error', (e) ->
        console.log e

    console.log "Listening to #{domain}:#{serverport}"
    server.listen serverport, domain


  provideLinter: ->
    provider =
      name: 'TTS Lua'
      grammarScopes: ['source.tts.lua']
      scope: 'file'
      lintsOnChange: true
      lint: (editor) =>
        filepath = editor.getPath()
        indents = [0]
        nextLineContinuation = false
        overrideContinuation = false
        nextLineExpectIndent = null
        lints = []
        suppress = [false]
        addLint = (severity, message, row, column) ->
          return if suppress[0]
          lints.push({
            severity: severity,
            excerpt: message,
            location: {
              file: filepath,
              position: [[row, column], [row, column]]
            }
            reference: {
              file: filepath,
              position: [row, column]
            }
          })
        lineCount = editor.getLineCount()
        i = 0
        while (i < lineCount)
          line = editor.lineTextForBufferRow(i)
          suppress[0] = line.endsWith('--') and not line.endsWith(']]--')
          if 'string.quoted.other.multiline.lua' in editor.scopeDescriptorForBufferPosition([i, 0]).scopes
            i += 1
            continue
          if 'comment.line.double-dash.lua' in editor.scopeDescriptorForBufferPosition([i, line.length]).scopes
            c = line.length - 1
            while c > 0 and 'comment.line.double-dash.lua' in editor.scopeDescriptorForBufferPosition([i, c]).scopes
              c -= 1
            line = line.slice(0, c)
            if line.match(/^\s*$/)
              i += 1
              continue
          m = line.match(/^(\s*)([^\s]+)/)
          if m
            indent = m[1].length
            if line.match(/else\s+if/)
              addLint('warning', "'else if' should be 'elseif'", i, indent)
            multiple = line.match(/(^|\s)(end|else|endif|until)(?=(\s|$))/g)
            if multiple and multiple.length > 1
              addLint('warning', 'Multiple block end keywords on single line', i, indent)
            override = line.match(/^\s*(if|else|elseif|repeat|for|while|function)(\s|\(|$)(.*\send[\s\)\}\]]*$|.*\suntil[\s\)\}\]]*)?/)
            override = override and not override[3]
            if not nextLineContinuation or override
              irregular = null
              [..., currentIndent] = indents
              if indent > currentIndent
                if m[2] in ['end', 'else', 'elseif', 'until'] or m[2].match(/^[\]\}\)]+$/)
                  irregular = "Dedent expected for '" + m[2] + "'"
                else if not nextLineExpectIndent and not override
                  irregular = "Indentation not expected"
                indents.push(indent)
              else
                if nextLineExpectIndent
                  addLint('warning', "Indentation expected after '" + nextLineExpectIndent + "'", i, indent)
                if indent < currentIndent
                  indents.pop()
                  [..., currentIndent] = indents
                  if indent > currentIndent
                    irregular = "Dedent does not match indent"
                    indents.push(indent)
                  else if indent < currentIndent
                    irregular = "Dedent does not match indent"
                    while indent < currentIndent
                      indents.pop()
                      [..., currentIndent] = indents
                    if indent > currentIndent
                      indents.push(indent)
                  else if m[2] not in ['end', 'else', 'elseif', 'until'] and not m[2].match(/^[\]\}\)]+$/)
                    irregular = "Dedent without keyword"
                else # indent == currentIndent
                  if m[2] in ['end', 'else', 'elseif', 'until'] or m[2].match(/^[\]\}\)]+$/)
                    irregular = "Dedent expected for '" + m[2] + "'"
              if irregular
                addLint('warning', irregular, i, indent)
              m = line.match(/^\s*(if|else|elseif|repeat|for|while|function)(\s|\(|$)(.*\send[\s\)\}\]]*$|.*\suntil[\s\)\}\]]*)?/)
              if m and not m[3]
                nextLineExpectIndent = m[1]
              else
                m = line.match(/([\{\[\(]+)$/)
                if m and not m[1].endsWith('[[')
                  nextLineExpectIndent = m[1]
                else
                  m = line.match(/\s(function)(\s|\()(.*\send[\s\)\]\}]*$)?/)
                  if m and not m[3]
                    nextLineExpectIndent = m[1]
                  else
                    nextLineExpectIndent = null
            else if nextLineContinuation[1] == ','
              m = line.match(/^(\s*)([^\s]+)/)
              if m and m[2].match(/^[\]\}\)]+/)
                indent = m[1].length
                [..., prevIndent, currentIndent] = indents
                if indent == prevIndent
                  indents.pop()
                  overrideContinuation = true
                else
                  addLint('warning', 'Dedent does not match indent', i, indent)
                  while indent < currentIndent
                    indents.pop()
                    [..., currentIndent] = indents
                  if indent > currentIndent
                    indents.push(indent)
            if overrideContinuation
              nextLineContinuation = false
              overrideContinuation = false
            else
              nextLineContinuation = line.match(/(\sor|\sand|\.\.|,)\s*$/)
          i += 1
        try
          luaparse.parse(editor.getText().replace(/^#include/gm, '--nclude'))
        catch error
          row = error.line - 1
          column = error.column
          message = error.message
          suppress[0] = false
          addLint('error', message, row, column)
        return lints
