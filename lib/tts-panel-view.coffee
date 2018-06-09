{$$, View} = require 'space-pen'
{CompositeDisposable} = require 'atom'
{TextEditorView} = require 'atom-space-pen-views'
path = require 'path'
mkdirp = require 'mkdirp'

THROTTLE_VALUES = {0: 0, 1: 0.5, 2: 1, 3: 1.5, 4: 2, 5: 3, 6: 5, 7: 10, 8: 20, 9: 30, 10: 60, 11:999999}
getThrottleText = (throttle) ->
  if throttle <= 10
    return THROTTLE_VALUES[throttle] + 's'
  else
    return '-'

module.exports = class TTSPanelView extends View

  @content: (state, executeLua, watchListEntries, checkLua, maxSnippets) ->
    watchList = state.watchList
    @snippetEditor = new TextEditorView()
    entries = 0
    snippets = 0
    @div class: 'tts-panel-view', =>
      @ul class: 'list-inline tab-bar inset-panel', is: 'atom-tabs', location: 'right', =>
        @li class: 'tab active', is: 'tabs-tab', =>
          @div class: 'close-icon', click: 'onClose'
          @div 'Tabletop Simulator', class: 'title'
      @div class: 'header', =>
        @span 'Watch List'
      @table class: 'watch-list', =>
        @tr =>
          @td =>
            @div class: 'watch-control', =>
              @table id: 'watch-table-header', =>
                @tr =>
                  @td =>
                    @label 'Automatically attach', class: 'input-label', =>
                      @input class: 'input-checkbox', id: 'autoAttach', type: 'checkbox', checked: state.autoAttach, change: 'onAutoAttach', tabindex: watchListEntries
                  @td class: 'button-container', =>
                    @button class: 'inline-block btn', click: 'onAttach', tabindex: watchListEntries + 2, 'Attach'
                  @td class: 'button-container', =>
                    @button class: 'inline-block btn', click: 'onDetach', tabindex: watchListEntries + 3, 'Detach'
        while entries < watchListEntries
          @tr =>
            @td =>
              @div class: 'tab-bar', =>
                @div class: 'tab', =>
                  @div class: 'close-icon', click: 'onClear', id: 'watch-close-'+entries
                  @table id: 'watch-table-' + entries, =>
                    @tr =>
                      @td =>
                        if watchList and entries < watchList.length
                          @input class: 'input-text native-key-bindings entry', id: 'watch-entry-'+entries, type: 'text', value: watchList[entries].entry, change: 'onEntryChange', tabindex: entries
                        else
                          @input class: 'input-text native-key-bindings entry', id: 'watch-entry-'+entries, type: 'text', value: "", change: 'onEntryChange', tabindex: entries
                      @td =>
                        @input class: 'input-text native-key-bindings value', id: 'watch-value-'+entries, type: 'text', value: "", change: 'onValueChange'
          entries += 1
        @tr =>
          @td =>
            @div class: 'watch-control', =>
              @table id: 'watch-table-footer', =>
                @tr =>
                  @td =>
                    @input class: 'input-slider', id: 'throttle', type: 'range', min: 0, max: 11, step: 1, value: state.watchListThrottle, input: 'onThrottleChange'
                  @td class: 'throttle-container', =>
                    @div class: 'throttle-container', =>
                      @input class: 'input-label', id: 'throttle-label', type: 'text', readOnly: true, value: state.watchListThrottleText
                  @td class: 'button-container', =>
                    @button class: 'inline-block btn', click: 'onRefresh', tabindex: watchListEntries + 1, '↻'
      @div class: 'header', =>
        @span 'Snippets'
      @div class: 'snippets', =>
        @div id: 'snippet-buttons', =>
          while snippets < maxSnippets
            @button class: 'inline-block btn hidden', click: 'onSnippetClick', id: 'snippet-button-' + snippets
            snippets++
        @div class: 'snippet', =>
          @table class: 'snippet-controls', =>
            @tr =>
              @td =>
                @button class: 'inline-block btn execute', click: 'executeSnippet', 'Execute'
              @td =>
                @label 'Label', class: 'input-label'
              @td =>
                @input class: 'input-text native-key-bindings snippet-label', id: 'snippet-label', type: 'text', value: ''
              @td class: 'button-container', =>
                @button class: 'icon icon-arrow-up inline-block btn', click: 'onSnippetSave', id: 'snippet-save'
              @td class: 'button-container', =>
                @button class: 'icon icon-trashcan inline-block btn', click: 'onSnippetTrash', id: 'snippet-trash'
          @subview "snippetEditor", @snippetEditor
      #@div class: 'editor mini editor-colors snippet', id: 'snippet', type: 'text', value: '', change: 'onSnippetChange', tabindex: entries+2


  initialize: (state, executeLua, watchListEntries, checkLua, maxSnippets) ->
    @executeLua = executeLua
    @checkLua = checkLua
    @panel = atom.workspace.addRightPanel(item: this, visible: false)
    @lastDetach = 0
    @detachCount = 0
    @watchListEntries = watchListEntries
    @maxSnippets = maxSnippets
    #@snippetEditor.getModel().setGrammar(atom.grammars.grammarForScopeName('source.tts.lua'))
    #atom.textEditors.setGrammarOverride(@snippetEditor.getModel(), 'source.tts.lua')
    @storage = path.join(path.dirname(atom.config.getUserConfigPath()), 'storage', 'TabletopSimulator')
    mkdirp(@storage)
    @snippetFile = path.join(@storage, "snippet.ttslua")
    @snippetBuffer = @snippetEditor.getModel().getBuffer()
    @snippetBuffer.setPath(@snippetFile)
    @snippetBuffer.reload()
    @snippets = {}
    @snippetList = ['foo', 'bar', 'baz', 'qux', 'quux']
    #load snippets
    @generateSnippetButtons()

  dispose: () ->
    @snippetBuffer.save()

  validateState: (state) ->
    if not state
      state = {}
    if not ('visible' of state)
      state.visible = false
    if not ('autoAttach' of state)
      state.autoAttach = false
    if not ('watchListThrottle' of state)
      state.watchListThrottle = 5
    if not ('watchListThrottleText' of state)
      state.watchListThrottleText = getThrottleText(state.watchListThrottle)
    if not ('watchList' of state)
      state.watchList = []
    for i in [0 ... @watchListEntries]
      if i >= state.watchList.length
        state.watchList.push({})
      if not ('entry' of state.watchList[i])
        state.watchList[i].entry = ''
      if not ('value' of state.watchList[i])
        state.watchList[i].value = ''
    return state

  serialize: ->
    @ttsPanelView.serialize()

  toggle: ->
    if @panel?.isVisible()
      @panel.hide()
      @state.visible = false
    else
      @panel?.show()
      @state.visible = true
      @updateUIFromState()
      if @state.autoAttach
        @attachToTTS()

  getState: ->
    return @state

  updateUIFromState: ->
    @find('#autoAttach').prop('checked', @state.autoAttach)
    @find('#throttle').val(@state.watchListThrottle)
    @find('#throttle-label').val(@state.watchListThrottleText)

  setState: (state) ->
    @state = @validateState(state)
    @updateUIFromState()
    if @state.visible != @panel?.isVisible()
      @toggle()

  destroy: ->
    @panel.destroy()

  onClose: (evt) ->
    @toggle()

  onEntryChange: (evt) ->
    id = parseInt(evt.target.id.split("-")[2])
    if @checkLua("a = function() return (" + evt.target.value + ") end")
      @state.watchList[id].entry = evt.target.value
      @updateWatchEntryOK(id, true)
      @addToTTSWatchList(id, evt.target.value)
    else
      if(evt.target.value == '')
        @doClear(id)
      else
        @updateWatchEntryOK(id, false)

  onValueChange: (evt) ->

  setThrottle: (seconds) ->

  onThrottleChange: (evt) ->
    @state.watchListThrottle = evt.target.value
    throttle = THROTTLE_VALUES[evt.target.value]
    @state.watchListThrottleText = getThrottleText(@state.watchListThrottle)
    @find('#throttle-label').val(@state.watchListThrottleText)
    @setTTSPollDelay(throttle)

  onRefresh: (evt) ->
    @executeLua("""
      if __atom_watch_list ~= nil then
        __atom_watch_list_refresh_all = true
      end
    """)

  onSnippetChange: (evt) ->
    console.log evt.target.text

  updateValue: (index, value) ->
    @state.watchList[index].value = value
    @find('#watch-value-' + index).val(value)

  onClear: (evt) ->
    id = parseInt(evt.target.id.split("-")[2])
    @doClear(id)

  doClear: (id) ->
    @find('#watch-entry-' + id).val('')
    @find('#watch-value-' + id).val('')
    @updateWatchEntryOK(id, true)
    @state.watchList[id].entry = ''
    @state.watchList[id].value = ''
    @removeFromTTSWatchList(id)

  onAutoAttach: (evt) ->
    @state.autoAttach = evt.target.checked

  getAutoAttach: () ->
    return @state.autoAttach

  visible: () ->
    return @panel?.isVisible()

  onAttach: (evt) ->
    @attachToTTS()

  onDetach: (evt) ->
    if Date.now() < @lastDetach + 1000 #within a second of last click
      @detachCount += 1
      if @detachCount == 2
        @detachFromTTS(true)
    else
      @lastDetach = Date.now()
      @detachCount = 0
      @detachFromTTS()

  clearTTSWatchList: ->
    @executeLua("""
      __atom_watch_list = nil
    """)

  updateWatchEntryOK: (id, ok) ->
    if ok
      @find('#watch-entry-' + id).removeClass('error')
    else
      @find('#watch-entry-' + id).addClass('error')

  addToTTSWatchList: (index, lua) ->
    lua = "function() return (" + lua + ") end"
    if @checkLua("a = " + lua)
      @executeLua("""
        if __atom_watch_list ~= nil then
          __atom_watch_list[#{index}] = {func=#{lua}, update=true}
          __atom_watch_list_refresh = true
        end
      """)

  removeFromTTSWatchList: (index) ->
    @executeLua("""
      if __atom_watch_list ~= nil then
        __atom_watch_list[#{index}] = nil
      end
    """)

  setTTSPollDelay: (delay) ->
    @executeLua("""
      if __atom_watch_list_delay != nil then
        __atom_watch_list_delay = #{delay}
      end
    """)

  detachFromTTS: (force) ->
    if force
      @executeLua("""
        __atom_watch_list = nil
        __atom_watch_list_delay = nil
        __atom_watch_list_routine = nil
        __atom_watch_list_refresh = nil
        __atom_watch_list_refresh_all = nil
      """)
    else
      @executeLua("""
        __atom_watch_list_routine = nil
      """)

  attachToTTS: ->
    lua = """
      __atom_watch_list_delay = #{THROTTLE_VALUES[@state.watchListThrottle]}
      __atom_watch_list_refresh = true
      __atom_watch_list = {}
    """
    i = 0
    while i < @watchListEntries
      code = "function() return (#{@state.watchList[i].entry}) end"
      if @state.watchList[i].entry != '' and @checkLua("a = " + code)
        lua += "\n__atom_watch_list[#{i}] = {func=#{code}, update=true}"
      else
        lua += "\n__atom_watch_list[#{i}] = nil"
      i += 1
    lua += """\n
      if __atom_watch_list_routine == nil then
        __atom_watch_list_routine = function()
          if __atom_watch_list_delay == nil then __atom_watch_list_delay = 0 end
          local last_time = os.clock()
          local ok
          local result
          local now
          local update
          repeat
            now = os.clock()
            if (now >= last_time + __atom_watch_list_delay) or __atom_watch_list_refresh or __atom_watch_list_refresh_all then
              last_time = now
              if __atom_watch_list ~= nil then
                local watched = {messageID = 1}
                update = false
                for k, watch in pairs(__atom_watch_list) do
                  ok, result = pcall(watch.func)
                  if result ~= watch.previous or ok ~= watch.previous_ok or watch.update or __atom_watch_list_refresh_all then
                    watch.update = nil
                    update = true
                    if ok then
                      watched['error'..k] = false
                      t = type(result)
                      if t == 'boolean' or t == 'number' or t == 'string' or result == nil then
                        watched['result'..k] = result
                      else
                        watched['result'..k] = tostring(result)
                      end
                    else
                      watched['error'..k].error = true
                      watched['result'..k].result = 0
                    end
                    watch.previous_ok = ok
                    watch.previous    = result
                  end
                end
                if update then
                  sendExternalMessage(watched)
                end
              end
              __atom_watch_list_refresh = nil
              __atom_watch_list_refresh_all = nil
            end
            coroutine.yield(0)
          until __atom_watch_list_routine == nil
          _G['__atom_watch_list'] = nil
          _G['__atom_watch_list_delay'] = nil
          _G['__atom_watch_list_refresh'] = nil
          _G['__atom_watch_list_refresh_all'] = nil
          return 1
        end
      end
      startLuaCoroutine(Global, '__atom_watch_list_routine')
    """
    @executeLua(lua)

  executeSnippet: ->
    @snippetEditor.getModel().save()

  generateSnippetButtons: ->
    snippet = 0
    while snippet < @maxSnippets
      id = 'snippet-button-' + snippet
      button = @find('#' + id)
      if snippet < @snippetList.length
        button.prop('innerHTML', @snippetList[snippet])
        button.removeClass('hidden')
      else
        button.addClass('hidden')
      snippet++

  onSnippetClick: (evt) ->
    id = parseInt(evt.target.id.substring(15))
    console.log @snippetList[id]

  onSnippetSave: ->
    snippetName = @find('#snippet-label').val()
    console.log snippetName
    key = snippetName.toLowerCase()
    if !(key of @snippets)
      i = 0
      while i < @snippetList.length and @snippetList[i].toLowerCase() < key
        i++
      @snippetList.splice(i, 0, snippetName)
      @generateSnippetButtons()
    @snippets[key] = @snippetBuffer.getText()
