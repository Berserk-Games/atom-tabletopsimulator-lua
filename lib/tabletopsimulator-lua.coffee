{CompositeDisposable} = require 'atom'

net = require 'net'
fs = require 'fs'
os = require 'os'
path = require 'path'
mkdirp = require 'mkdirp'
provider = require './provider'

domain = 'localhost'
port = 39999

ttsLuaDir = path.join(os.tmpdir(), "TabletopSimulator", "Lua")

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
        atom.focus()
        # register events
        atom.workspace.open(@tempfile, activatePane:true).then (editor) =>
            @handle_connection(editor)

    handle_connection: (editor) ->
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

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:getObjects': => @getObjects()
    @subscriptions.add atom.commands.add 'atom-workspace', 'tabletopsimulator-lua:saveAndPlay': => @saveAndPlay()

    # Delete any existing cached Lua files
    try
      @oldfiles = fs.readdirSync(ttsLuaDir)
      for oldfile,i in @oldfiles
        @deletefile = path.join(ttsLuaDir, oldfile)
        fs.unlinkSync(@deletefile)
    catch error

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  getProvider: -> provider

  getObjects: ->
    # Confirm just in case they misclicked Save & Play
    atom.confirm
      message: 'Get Lua Scripts from game?'
      detailedMessage: 'This will erase any local changes that you may have done.'
      buttons:
        Yes: ->
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
      editor.save()

    # Read all files into JSON object
    @luaObjects = {}
    @luaObjects.messageID = 1
    @luaObjects.scriptStates = []
    @luafiles = fs.readdirSync(ttsLuaDir)
    for luafile,i in @luafiles
      @luaObject = {}
      tokens = luafile.split "."
      @luaObject.name = luafile
      @luaObject.guid = tokens[tokens.length-2]
      fname = path.join(ttsLuaDir, luafile)
      @luaObject.script = fs.readFileSync(fname, 'utf8')
      @luaObjects.scriptStates.push(@luaObject)

    if not @if_connected
      @startConnection()
    try
      @connection.write JSON.stringify(@luaObjects)
    catch error
      console.log error

  startConnection: ->
    if @if_connected
      @stopConnection()

    @connection = net.createConnection port, domain
    @connection.tabletopsimulator = @
    @connection.parse_line = @parse_line
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
        for f,i in @data.scriptStates
          @file = new FileHandler()
          @file.setBasename(f.name + "." + f.guid + ".lua")
          @file.setDatasize(f.script.length)
          @file.create()

          lines = f.script.split "\n"
          for line,i in lines
            if i < lines.length-1
              line = line + "\n"
            @parse_line(line)
          @file.open()
          @file = null

      @data_cache = ""

    @connection.on 'error', (e) =>
      #console.log e
      @stopConnection()

    @connection.on 'end', (data) ->
      #console.log "Connection closed"
      @tabletopsimulator.if_connected = false

  stopConnection: ->
    @connection.end()
    @if_connected = false

  parse_line: (line) ->
    @file.append(line)
