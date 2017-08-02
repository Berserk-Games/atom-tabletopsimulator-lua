{CompositeDisposable} = require 'atom'
{BufferedProcess} = require 'atom'

net = require 'net'
fs = require 'fs'
os = require 'os'
path = require 'path'
mkdirp = require 'mkdirp'
provider = require './provider'

domain = 'localhost'
clientport = 39999
serverport = 39998

ttsLuaDir = path.join(os.tmpdir(), "TabletopSimulator", "Lua")

# Store cursor positions between loads
cursors = {}

# Ping function not used at the moment
ping = (socket, delay) ->
  console.log "Pinging server"
  socket.write "Ping"
  nextPing = -> ping(socket, delay)
  setTimeout nextPing, delay

###
https://github.com/randy3k/remote-atom/blob/master/lib/remote-atom.coffee

Copyright (c) Randy Lai 2014

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
###
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
    # register events
    atom.workspace.open(@tempfile, activatePane:true).then (editor) =>
      @handle_connection(editor)

  handle_connection: (editor) ->
    # Replace \u character codes
    if atom.config.get('tabletopsimulator-lua.loadSave.convertUnicodeCharacters')
      replace_unicode = (unicode) ->
        unicode.replace(String.fromCharCode(parseInt(unicode.match[1],16)))
      editor.scan(/\\u\{([a-zA-Z0-9]{1,4})\}/g, replace_unicode)

    # Restore cursor position
    try
      editor.setCursorBufferPosition(cursors[editor.getPath()])
      editor.scrollToCursorPosition()
    catch error
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
    hacks:
      title: 'Hacks (Experimental!)'
      order: 4
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

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:getObjects': => @getObjects()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:saveAndPlay': => @saveAndPlay()
    @subscriptions.add atom.config.observe 'tabletopsimulator-lua.autocomplete.excludeLowerPriority', (newValue) => @excludeChange()

    # Close any open files
    for editor,i in atom.workspace.getTextEditors()
      try
        #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
        editor.destroy()
      catch error
        console.log error

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
          for editor,i in atom.workspace.getTextEditors()
            try
              # Store cursor positions
              cursors[editor.getPath()] = editor.getCursorBufferPosition()
              #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
              editor.destroy()
            catch error
              console.log error

          # Delete any existing cached Lua files
          try
            @oldfiles = fs.readdirSync(ttsLuaDir)
            for oldfile,i in @oldfiles
              @deletefile = path.join(ttsLuaDir, oldfile)
              fs.unlinkSync(@deletefile)
          catch error

          atom.project.addPath(ttsLuaDir)

          if not TabletopsimulatorLua.if_connected
            TabletopsimulatorLua.startConnection()
          TabletopsimulatorLua.connection.write '{ messageID: 0 }'
        No: -> return

  saveAndPlay: ->
    # Save any open files
    for editor,i in atom.workspace.getTextEditors()
      try
        # Store cursor positions
        cursors[editor.getPath()] = editor.getCursorBufferPosition()
      catch error
      try
        await editor.save()
      catch error

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

  excludeChange: (newValue) ->
    provider.excludeLowerPriority = atom.config.get('tabletopsimulator-lua.autocomplete.excludeLowerPriority')

  startConnection: ->
    if @if_connected
      @stopConnection()

    @connection = net.createConnection clientport, domain
    @connection.tabletopsimulator = @
    #@connection.parse_line = @parse_line
    @connection.data_cache = ""
    @if_connected = true

    @connection.on 'connect', () ->
      #console.log "Opened connection to #{domain}:#{port}"

    @connection.on 'data', (data) ->
      try
        @data = JSON.parse(@data_cache + data)
      catch error
        @data_cache = @data_cache + data
        return

      if @data.messageID == 0
        # Close any open files
        for editor,i in atom.workspace.getTextEditors()
          try
            #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
            editor.destroy()
          catch error
            console.log error

        for f,i in @data.scriptStates
          @file = new FileHandler()
          f.name = f.name.replace(/([":<>/\\|?*])/g, "")
          @file.setBasename(f.name + "." + f.guid + ".ttslua")
          @file.setDatasize(f.script.length)
          @file.create()

          lines = f.script.split "\n"
          for line,i in lines
            if i < lines.length-1
              line = line + "\n"
            #@parse_line(line)
            @file.append(line)
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
          #console.log "#{socket.remoteAddress} sent: #{data}"

          try
            @data = JSON.parse(@data_cache + data)
          catch error
            @data_cache = @data_cache + data
            return

          # Pushing new Object
          if @data.messageID == 0
            for f,i in @data.scriptStates
              @file = new FileHandler()
              f.name = f.name.replace(/([":<>/\\|?*])/g, "")
              @file.setBasename(f.name + "." + f.guid + ".ttslua")
              @file.setDatasize(f.script.length)
              @file.create()

              lines = f.script.split "\n"
              for line,i in lines
                if i < lines.length-1
                  line = line + "\n"
                #@parse_line(line)
                @file.append(line)
              @file.open()
              @file = null

          # Loading a new game
          else if @data.messageID == 1
            for editor,i in atom.workspace.getTextEditors()
              try
                #atom.commands.dispatch(atom.views.getView(editor), 'core:close')
                editor.destroy()
              catch error
                console.log error

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

              lines = f.script.split "\n"
              for line,i in lines
                if i < lines.length-1
                  line = line + "\n"
                #@parse_line(line)
                @file.append(line)
              @file.open()
              @file = null

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
