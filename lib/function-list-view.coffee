{$$, View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'
{BufferedProcess, CompositeDisposable} = require 'atom'

module.exports =
class FunctionListView extends SelectListView
  maxItems: 99999
  minFilterLength: 3

  initialize: ->
    super
    @editor = atom.workspace.getActiveTextEditor()
    @pane = atom.workspace.paneForItem(@editor)
    @currentRow = @editor.getCursorBufferPosition().row
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @showFunctionName = atom.config.get('tabletopsimulator-lua.editor.showFunctionInGoto')
    @addClass 'tabletopsimulator-lua-goto-function'
    @addItems()

  addItems: () =>
    if @editor
      @lineCount = @editor.getLineCount()
      if @editor.getPath().endsWith('.ttslua')
        row = 0
        functions = []
        while (row < @lineCount)
          line = @editor.lineTextForBufferRow(row)
          m = line.match(/^\s*function\s+([^\s\(]*)\s*[\(]([^\)]*)\)/)
          if m
            functions.push({functionName:m[1], parameters:m[2], line:row})
          row += 1
        functions.sort (a, b) -> return if a.functionName.toLowerCase() > b.functionName.toLowerCase() then 1 else -1
        @setItems(functions)

  viewForItem: ({functionName, parameters, line}) ->
    li = document.createElement('li')
    addSpan = (classNames, text) ->
      span = document.createElement('span')
      for name in classNames
        span.classList.add(name)
      span.textContent = text
      li.appendChild(span)
    if @showFunctionName
      addSpan(['syntax--keyword', 'syntax--control', 'syntax--lua'], "function ")
    addSpan(['syntax--entity', 'syntax--name', 'syntax--function', 'syntax--lua'], functionName)
    addSpan(['syntax--punctuation', 'syntax--definition', 'syntax--parameters', 'syntax--begin',  'syntax--lua'], '(')
    addSpan(['syntax--variable', 'syntax--parameter', 'syntax--function', 'syntax--lua'], parameters)
    addSpan(['syntax--punctuation', 'syntax--definition', 'syntax--parameters', 'syntax--end',  'syntax--lua'], ')')
    return li

  gotoLine: (line, relative=false) ->
    if relative
      line += @currentRow
    if line < 0
      line = 0
    if line >= @lineCount
      line = @lineCount
    @editor.setCursorBufferPosition([line, 0])
    @editor.scrollToCursorPosition()

  getFilterKey: ->
    return 'functionName'

  getSearchValue: ->
    return @filterEditorView.getText()

  confirmSelection: ->
    m = @getSearchValue().match(/^([-+]?)([0-9]+)$/)
    if m
      if m[1]
        @gotoLine(parseInt(m[1]+m[2]), true)
      else
        @gotoLine(parseInt(m[2])-1)
      @cancelled()
    else
      item = @getSelectedItem()
      if item?
        @confirmed(item)
      else
        @cancel()

  confirmed: (item)->
    if @editor
      @gotoLine(item.line)
    @cancelled()

  cancelled: ->
    @items = []
    @panel.hide()
    if @pane
      @pane.activate()

  destroy: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @detach()

  toggle: ->
    if @panel?.isVisible()
      @panel?.show()
    else
      @storeFocusedElement()
      @panel.show()
      @focusFilterEditor()
