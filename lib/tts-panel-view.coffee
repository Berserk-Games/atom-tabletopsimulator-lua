{$$, View} = require 'space-pen'
{CompositeDisposable} = require 'atom'

watchListEntries = 12

module.exports = class TTSPanelView extends View

  @content: (watchList) ->
    console.log watchList
    @div class: 'tts-panel-view', =>
      @ul class: 'list-inline tab-bar inset-panel', is: 'atom-tabs', location: 'right', =>
        @li class: 'tab active', is: 'tabs-tab', =>
          @div 'Tabletop Simulator', class: 'title'
      @table class: 'watch-list', =>
        entries = 0
        while entries < watchListEntries
          @tr =>
            @td =>
              if watchList and entries < watchList.length
                @input class: 'input-text', name: 'watch-entry-'+entries, type: 'text', value: watchList[entries].entry, change: 'onEntryChange'
              else
                @input class: 'input-text', name: 'watch-entry-'+entries, type: 'text', value: "", change: 'onEntryChange'
            @td =>
              @a click: 'onClear', =>
                @div class: 'close-icon'
            @td =>
              @input class: 'input-text', name: 'watch-value-'+entries, type: 'text', value: "", change: 'onValueChange'
          entries += 1



  initialize: ->
    @panel = atom.workspace.addRightPanel(item: this, visible: false)
    @state = @validateState()

  validateState: (state) ->
    if not state
      state = {}
    if not ('visible' of state)
      state.visible = false
    if not ('watchList' of state)
      state.watchList = []
    for i in [0 ... watchListEntries]
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

  getState: ->
    return @state

  setState: (state) ->
    state = @validateState(state)
    if not @state.visible and state.visible
      @toggle()
    @state = state

  destroy: ->
    @panel.destroy()

  onEntryChange: (evt) ->
    id = parseInt(evt.target.name.split("-")[2])
    @state.watchList[id].entry = evt.target.value

  onValueChange: (evt) ->
    console.log evt

  onClear: (evt) ->
    console.log evt
