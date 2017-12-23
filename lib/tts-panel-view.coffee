{$$, View} = require 'space-pen'
{CompositeDisposable} = require 'atom'

module.exports = class TTSPanelView extends View

  @content: (watchList) ->
    @div class: 'tts-panel-view', =>
      @ul class: 'list-inline tab-bar inset-panel', is: 'atom-tabs', location: 'right', =>
        @li class: 'tab active', is: 'tabs-tab', =>
          @div 'Tabletop Simulator', class: 'title'
      @table class: 'watch-list', =>
        entries = 0
        while entries < 12
          @tr =>
            @td =>
              if entries < watchList.length
                @input class: 'input-text', name: 'watch-entry-'+entries, type: 'text', text: watchList[entries].entry, change: 'onEntryChange'
              else
                @input class: 'input-text', name: 'watch-entry-'+entries, type: 'text', text: "", change: 'onEntryChange'
            @td =>
              @input class: 'input-text', name: 'watch-value-'+entries, type: 'text', text: "", change: 'onValuechange'
          entries += 1



  initialize: ->
    @panel = atom.workspace.addRightPanel(item: this, visible: false)
    @state = {visible: false, watchList: []}
    for i in 12
      @state.watchList[i] = {}
      @state.watchList[i].entry = ''
      @state.watchList[i].value = ''


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
    if not @state.visible and state.visible
      @toggle()
    @state = state

  destroy: ->
    @panel.destroy()

  onEntryChange: (evt) ->
    id = parseInt(evt.target.name.split("-")[2])
    @state.watchList[id].entry = evt.target.text
