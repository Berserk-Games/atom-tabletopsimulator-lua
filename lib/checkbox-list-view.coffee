{$$, View} = require 'space-pen'
{ScrollView} = require 'atom-space-pen-views'
#CheckboxListView = require './checkbox-list-view'
{CompositeDisposable} = require 'atom'

module.exports = class CheckboxListView extends View

  @content: (guids, editor) ->
    tags = {}
    for guid of guids
      tags[guids[guid].tag] = true
    @div class: 'checkbox-list-view', =>
      @h1 'Generate GUID code'
      @h2 'Select objects to include:'
      @ul style: 'list-style-type: none; margin-top: 1em; margin-bottom: 1em;', =>
        for tag of tags
          @li =>
            @label tag, class: 'input-label', =>
              @input class: 'input-checkbox', alt: tag, type: 'checkbox', checked: true, change: 'onchange'
      @div class: 'btn-group', =>
        @button class: 'inline-block btn btn-primary checkbox-list-confirm', click: 'confirmedAsFunction', 'Generate Function'
        @button class: 'inline-block btn btn-primary checkbox-list-confirm', click: 'confirmedAsCode', 'Generate Block'
      @button class: 'inline-block btn checkbox-list-cancel', click: 'cancelled', 'Cancel'

  initialize: (guids, editor) ->
    @modalPanel = atom.workspace.addModalPanel(item: this, visible: false)
    @guids = guids
    @editor = editor
    @pane = atom.workspace.paneForItem(@editor)
    @doCancel = true
    @tags = {}
    for guid of guids
      @tags[guids[guid].tag] = true
      @doCancel = false

  serialize: ->
    checkboxListViewState: @checkboxListView.serialize()

  onchange: (evt) ->
    @tags[evt.target.alt] = evt.target.checked

  confirmedAsFunction: ->
    @function = true
    @confirmed()

  confirmedAsCode: ->
    @function = false
    @confirmed()

  confirmed: ->
    @confirmedCallback(@tags, @guids, @function)
    @cancelled()

  cancelled: ->
    @destroy()
    if @pane
      @pane.activate()

  toggle: (callback) ->
    if @doCancel
      atom.notifications.addInfo("No GUIDs found!")
      @cancelled()
    else
      @confirmedCallback = callback
      if @modalPanel.isVisible()
        @modalPanel.hide()
      else
        @modalPanel.show()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()
    @modalPanel.destroy()
