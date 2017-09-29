{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'

net = require 'net'
fs = require 'fs'
os = require 'os'
path = require 'path'
mkdirp = require 'mkdirp'
luaparse = require 'luaparse'
provider = require './provider'
StatusBarFunctionView = require './status-bar-function-view'
FunctionListView = require './function-list-view'

domain = 'localhost'
clientport = 39999
serverport = 39998

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
activeEditorPath = ''
mutex = {}
mutex.doingSaveAndPlay = false

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
  lines = text.split(/\r?\n/)
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
  return path.dirname(fn) == ttsLuaDir

isGlobalScript = (fn) ->
  return path.basename(fn) == 'Global.-1.ttslua'

destroyTTSEditors = ->
  if not atom.config.get('tabletopsimulator-lua.loadSave.openOtherFiles')
    force = true
  for editor,i in atom.workspace.getTextEditors()
    if force or isFromTTS(editor.getPath())
      try
        editor.destroy()
      catch error
        console.log error


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

  open: ->
    #atom.focus()
    row = 0
    col = 0
    try
      row = cursors[@tempfile].row
      col = cursors[@tempfile].column
    catch error
    if activeEditorPath
      active = (activeEditorPath == @tempfile)
    else
      active = true
    atom.workspace.open(@tempfile, {initialLine: row, initialColumn: col, activatePane: active}).then (editor) =>
      @handle_connection(editor)

  handle_connection: (editor) ->
    cursorPosition =  editor.getCursorBufferPosition()
    filepath = editor.getPath()
    # Map and remove included files
    if atom.config.get('tabletopsimulator-lua.loadSave.includeOtherFiles')
      text = editor.getText()
      lines = text.split(/\r?\n/)
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
    # Replace \u character codes
    if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')
      replace_unicode = (unicode) ->
        unicode.replace(String.fromCharCode(parseInt(unicode.match[1],16)))
      editor.scan(/\\u\{([a-zA-Z0-9]{1,4})\}/g, replace_unicode)
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


module.exports = TabletopsimulatorLua =
  subscriptions: null
  config:
    loadSave:
      title: 'Loading/Saving'
      type: 'object'
      order: 1
      properties:
        convertUnicodeCharacters:
          title: 'Convert between unicode chacter and \\u{xxxx} escape sequence when loading/saving'
          description: 'When loading from TTS automatically convert to unicode character from instances of ``\\u{xxxx}``.  When saving to TTS do the reverse.  e.g. it will convert ``é`` from/to ``\\u{00e9}``'
          order: 1
          type: 'boolean'
          default: false
        openGlobalOnly:
          title: 'Open only the Global script automatically'
          description: 'You can still manually open your scripts from the package view'
          order: 2
          type: 'boolean'
          default: false
        openOtherFiles:
          title: 'Experimental: Ignore files from outwith the TTS folder'
          description: 'When you Save And Play do not close files which are not in the TTS temp folder'
          order: 3
          type: 'boolean'
          default: false
        includeOtherFiles:
          title: 'Experimental: Insert other files specified in source code'
          description: 'Convert lines containing ``#include <FILE>`` with text from the file specified'
          order: 4
          type: 'boolean'
          default: false
        includeOtherFilesPath:
          title: 'Experimental: Base path for files you wish to #include'
          description: 'Start with ``~`` to represent your user folder.  If left blank will default to ``~' + PATH_SEPERATOR + 'Documents' + PATH_SEPERATOR + 'Tabletop Simulator' + PATH_SEPERATOR + '``' + '.  You may refer to this path explicitly in your code by starting your #include path with ``!' + PATH_SEPERATOR + '``'
          order: 5
          type: 'string'
          default: ''
#        includeKeyword:
#          title: 'Insertion keyword to use'
#          description: 'Example (using default keyword): ``-- include c:\\path\\to\\file`` will insert the contents of file ``c:\\path\\to\\file.ttslua``\nIf you specify a file with no path then it will look for the file in the same folder as the current file.'
#          order: 5
#          type: 'string'
#          default: 'include'
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
    editor:
      title: 'Editor'
      order: 4
      type: 'object'
      properties:
        showFunctionName:
          title: 'Show function name in status bar'
          order: 1
          description: 'Display the name of the function the cursor is currently inside'
          type: 'boolean'
          default: false
        showFunctionInGoto:
          title: 'Show ``function`` prefix during Go To Function'
          order: 2
          description: 'Prefix all function names with the keyword \'function\' when using the Go To Function command.'
          type: 'boolean'
          default: true
    hacks:
      title: 'Hacks (Experimental!)'
      order: 5
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



  activate: (state) ->
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
      atom.config.set('tabletopsimulator-lua.loadSave.convertUnicodeCharacters', atom.config.get('tabletopsimulator-lua.convertUnicodeCharacters'))
      atom.config.unset('tabletopsimulator-lua.convertUnicodeCharacters')
    if atom.config.get('tabletopsimulator-lua.parameterToDisplay') != undefined
      atom.config.set('tabletopsimulator-lua.autocomplete.parameterToDisplay', atom.config.get('tabletopsimulator-lua.parameterToDisplay'))
      atom.config.unset('tabletopsimulator-lua.parameterToDisplay')

    # StatusBarFunctionView to display current function in status bar
    @statusBarFunctionView = new StatusBarFunctionView()
    @statusBarFunctionView.init()
    @statusBarActive = false
    @statusBarPreviousPath = ''
    @statusBarPreviousRow  = 0

    # Function name lookup
    @functionByName = {}
    @functionPaths = {}

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

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:getObjects': => @getObjects()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:saveAndPlay': => @saveAndPlay()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:gotoFunction': => @gotoFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:jumpToFunction': => @jumpToCursorFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:selectFunction': => @selectCurrentFunction()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:expandSelection': => @expandSelection()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:retractSelection': => @retractSelection()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:toggleSelectionCursor': => @toggleCursorSelectionEnd()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:displayCurrentFunction': => @displayFunction()

    # Register events
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.autocomplete.excludeLowerPriority', (newValue) => @excludeChange()
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.editor.showFunctionName', (newValue) => @showFunctionChange()
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
    try
      @oldfiles = fs.readdirSync(ttsLuaDir)
      for oldfile,i in @oldfiles
        @deletefile = path.join(ttsLuaDir, oldfile)
        fs.unlinkSync(@deletefile)
    catch error

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
      view = atom.views.getView(editor)
      f = () ->
        atom.commands.dispatch(view, 'linter:lint')
      delay = 0
      while delay < 1000
        delay += 100
        setTimeout f, delay


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
    if event and @isBlockSelecting and not @blockSelectLock
      @isBlockSelecting = false
    if event and @statusBarActive
      editor = event.cursor.editor
      if editor
        filepath = editor.getPath()
        if not filepath or not filepath.endsWith('.ttslua')
          @statusBarFunctionView.updateFunction(null)
        else if filepath == @statusBarPreviousPath and event.newBufferPosition.row == @statusBarPreviousRow
          return
        else
          [names, rows] = @getFunctions(editor, event.newBufferPosition.row)
          @statusBarFunctionView.updateFunction(names, rows)

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
      if row == -1 #no root function found
        return [null, null]
      else
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

  getObjects: ->
    # Confirm just in case they misclicked Save & Play
    atom.confirm
      message: 'Get Lua Scripts from game?'
      detailedMessage: 'This will erase any local changes that you may have done.'
      buttons:
        Yes: ->
          # Close any open files
          #for editor,i in atom.workspace.getTextEditors()
          #  try
          #    # Store cursor positions
          #    cursors[editor.getPath()] = editor.getCursorBufferPosition()
          #    #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
          #    editor.destroy()
          #  catch error
          #    console.log error
          destroyTTSEditors()

          # Delete any existing cached Lua files
          try
            @oldfiles = fs.readdirSync(ttsLuaDir)
            for oldfile,i in @oldfiles
              @deletefile = path.join(ttsLuaDir, oldfile)
              fs.unlinkSync(@deletefile)
          catch error

          # Add temp dir to atom
          atom.project.addPath(ttsLuaDir)

          if not TabletopsimulatorLua.if_connected
            TabletopsimulatorLua.startConnection()
          TabletopsimulatorLua.connection.write '{ messageID: 0 }'
        No: -> return

  # hack needed because atom 1.19 makes save() async
  blocking_save: (editor) =>
    if async_save
      if editor.isModified()
        return Promise.resolve(editor.save())
      else
        return Promise.resolve(editor.getBuffer())
    else
      try
        editor.save()
      catch error
      return Promise.resolve(editor.getBuffer())


  saveAndPlay: ->
    if mutex.doingSaveAndPlay
      return
    mutex.doingSaveAndPlay = true
    #clear this after some time in case a problem occured during save and play
    f = () ->
      mutex.doingSaveAndPlay = false
    setTimeout f, 3000

    # Store active editor
    try
      activeEditorPath = atom.workspace.getActiveTextEditor().getPath()
    catch error

    # Save any open files
    openFiles = 0
    savedFiles = 0
    editors = []
    for editor,i in atom.workspace.getTextEditors()
      openFiles += 1
      # Store cursor positions
      ttsEditors = {}
      if path.dirname(editor.getPath()) == ttsLuaDir
        ttsEditors[path.basename(editor.getPath())] = true
      else
        editors.push(editor.getPath())
      cursors[editor.getPath()] = editor.getCursorBufferPosition()

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
              # Replace with \u character codes
              if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')
                replace_character = (character) ->
                  return "\\u{" + character.codePointAt(0).toString(16) + "}"
                @luaObject.script = @luaObject.script.replace(/[\u0080-\uFFFF]/g, replace_character)
              @luaObjects.scriptStates.push(@luaObject)

          if not @if_connected
            @startConnection()
          try
            @connection.write JSON.stringify(@luaObjects)
          catch error
            console.log error


  insertFiles: (text, dir = null, alreadyInserted = {}) ->
    lines = text.split(/\r?\n/)
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
            filetext = filetext.replace(/[\s\n\r]*$/gm, '')
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
    lines = text.split(/\r?\n/)
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

  startConnection: ->
    if @if_connected
      @stopConnection()

    @connection = net.createConnection clientport, domain
    @connection.tabletopsimulator = @
    #@connection.parse_line = @parse_line
    @connection.data_cache = ""
    @if_connected = true

    @connection.on 'connect', () ->
      #console.log "Opened connection to #{domain}:#{clientport}"

    @connection.on 'data', (data) ->
      # getObjects results in this
      try
        @data = JSON.parse(@data_cache + data)
      catch error
        @data_cache = @data_cache + data
        #console.log "Received data cache"
        return
      #console.log "Received: ", @data.messageID

      if @data.messageID == 0
        # Close any open files
        #for editor,i in atom.workspace.getTextEditors()
        #  try
        #    #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
        #    editor.destroy()
        #  catch error
        #    console.log error
        destroyTTSEditors()

        for f,i in @data.scriptStates
          @file = new FileHandler()
          f.name = f.name.replace(/([":<>/\\|?*])/g, "")
          @file.setBasename(f.name + "." + f.guid + ".ttslua")
          @file.setDatasize(f.script.length)
          @file.create()

          lines = f.script.split(/\r?\n/)
          for line,i in lines
            if i < lines.length-1
              line = line + "\n"
            #@parse_line(line)
            @file.append(line)
          if isGlobalScript(@file.basename) or ttsEditors[@file.basename] or not atom.config.get('tabletopsimulator-lua.loadSave.openGlobalOnly')
            #console.log i, "Opening file in Start Connection", @file
            @file.open()
          @file = null

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

  ###
  parse_line: (line) ->
    @file.append(line)
  ###

  startServer: ->
    server = net.createServer (socket) ->
      #console.log "New connection from #{socket.remoteAddress}"
      socket.data_cache = ""
      #socket.parse_line = @parse_line

      socket.on 'data', (data) ->
        # saveAndPlay and making a new script in TTS results in this

        try
          @data = JSON.parse(@data_cache + data)
        catch error
          @data_cache = @data_cache + data
          #console.log "Received data cache"
          return
        #console.log "Received: #{@data.messageID} from #{socket.remoteAddress}"

        # Pushing new Object
        if @data.messageID == 0
          for f,i in @data.scriptStates
            @file = new FileHandler()
            f.name = f.name.replace(/([":<>/\\|?*])/g, "")
            @file.setBasename(f.name + "." + f.guid + ".ttslua")
            @file.setDatasize(f.script.length)
            @file.create()

            lines = f.script.split(/\r?\n/)
            for line,i in lines
              if i < lines.length-1
                line = line + "\n"
              #@parse_line(line)
              @file.append(line)
              #console.log i, "Opening file in Start Server message 0", @file
            @file.open()
            @file = null

        # Loading a new game
        else if @data.messageID == 1
          #for editor,i in atom.workspace.getTextEditors()
          #  try
          #    #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
          #    editor.destroy()
          #  catch error
          #    console.log error
          destroyTTSEditors()

          # Delete any existing cached Lua files
          try
            @oldfiles = fs.readdirSync(ttsLuaDir)
            for oldfile,i in @oldfiles
              @deletefile = path.join(ttsLuaDir, oldfile)
              fs.unlinkSync(@deletefile)
          catch error

          # Load scripts from new game
          for f,i in @data.scriptStates
            @file = new FileHandler()
            f.name = f.name.replace(/([":<>/\\|?*])/g, "")
            @file.setBasename(f.name + "." + f.guid + ".ttslua")
            @file.setDatasize(f.script.length)
            @file.create()

            lines = f.script.split(/\r?\n/)
            for line,i in lines
              if i < lines.length-1
                line = line + "\n"
              #@parse_line(line)
              @file.append(line)
            if isGlobalScript(@file.basename) or ttsEditors[@file.basename] or not atom.config.get('tabletopsimulator-lua.loadSave.openGlobalOnly')
              #console.log "Opening file in Start Server message 1", @file
              @file.open()
            @file = null

          # TODO trying to do this by simply not closing them instead of reopening them
          # Load any further files that were previously open
          #if atom.config.get('tabletopsimulator-lua.loadSave.openOtherFiles')
          #  for filepath in editors
          #    row = 0
          #    col = 0
          #    try
          #      row = cursors[filepath].row
          #      col = cursors[filepath].column
          #    catch error
          #    active = (activeEditorPath == filepath)
          #    #console.log "Opening other file", filepath
          #    atom.workspace.open(filepath, {initialLine: row, initialColumn: col, activatePane: active, activateItem: active})
          mutex.doingSaveAndPlay = false

        # Print/Debug message
        else if @data.messageID == 2
          console.log @data.message

        # Error message
        # Might change this from a string to a struct with more info
        else if @data.messageID == 3
          console.error @data.errorMessagePrefix + @data.error
          #console.error @data.message

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
        nextLineExpectIndent = null
        lints = []
        addLint = (severity, message, row, column) ->
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
          scopes = editor.scopeDescriptorForBufferPosition([i, 0])
          if 'string.quoted.other.multiline.lua' in scopes.scopes
            i += 1
            continue
          scopes = editor.scopeDescriptorForBufferPosition([i, line.length])
          if 'comment.line.double-dash.lua' in scopes.scopes
            line = line.split('--')[0]
          m = line.match(/^(\s*)([^\s]+)/)
          if m
            indent = m[1].length
            if line.match(/else\s+if/)
              addLint('warning', "'else if' should be 'elseif'", i, indent)
            multiple = line.match(/(^|\s)(end|else|endif|until)(?=(\s|$))/g)
            if multiple and multiple.length > 1
              addLint('warning', 'Multiple block end keywords on single line', i, indent)
            override = line.match(/^\s*(if|else|elseif|repeat|for|while|function)(\s|\(|$)(.*\send\s*$)?/)
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
              m = line.match(/^\s*(if|else|elseif|repeat|for|while|function)(\s|\(|$)(.*\send\s*$)?/)
              if m and not m[3]
                nextLineExpectIndent = m[1]
              else
                m = line.match(/([\{\[\(]+)$/)
                if m and not m[1].endsWith('[[')
                  nextLineExpectIndent = m[1]
                else
                  m = line.match(/\s(function)(\s|\()(.*\send\s*$)?/)
                  if m and not m[3]
                    nextLineExpectIndent = m[1]
                  else
                    nextLineExpectIndent = null
            else if nextLineContinuation[1] == ','
              m = line.match(/^(\s*)([^\s]+)/)
              if m and m[2].match(/^[\]\}\)]+$/)
                indent = m[1].length
                [..., prevIndent, currentIndent] = indents
                if indent == prevIndent
                  indents.pop()
                else
                  addLint('warning', 'Dedent does not match indent', i, indent)
                  while indent < currentIndent
                    indents.pop()
                    [..., currentIndent] = indents
                  if indent > currentIndent
                    indents.push(indent)
            nextLineContinuation = line.match(/(\sor|\sand|\.\.|,)\s*$/)
          i += 1
        try
          luaparse.parse(editor.getText().replace(/^#include/gm, '--nclude'))
        catch error
          row = error.line - 1
          column = error.column
          message = error.message
          addLint('error', message, row, column)
        return lints
