{$$, View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'
path = require 'path'

module.exports =
class FunctionListView extends SelectListView
  maxItems: 99999
  minFilterLength: 3

  initialize: (functionByName, expandedLineNumbers) ->
    super
    @editor = atom.workspace.getActiveTextEditor()
    @pane = atom.workspace.paneForItem(@editor)
    @currentRow = @editor.getCursorBufferPosition().row
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @showFunctionName = atom.config.get('tabletopsimulator-lua.editor.showFunctionInGoto')
    @addClass 'tabletopsimulator-lua-goto-function'
    @functionByName = functionByName
    @expandedLineNumbers = expandedLineNumbers
    @addItems()

  addItems: () =>
    functions = []
    for functionName, functionDescription of @functionByName
      functions.push(functionDescription)
    functions.sort (a, b) -> return if a.functionName.toLowerCase() > b.functionName.toLowerCase() then 1 else -1
    @setItems(functions)

  viewForItem: ({functionName, parameters, filepath, line}) ->
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
    addSpan(['syntax--comment', 'syntax--lua', 'right'], path.basename(filepath.replace(/\.ttslua$/,'')))
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
        row = parseInt(m[2])-1
        currentFile = @editor.getPath()
        currentRow = 0
        offset = 0
        if @expandedLineNumbers
          for filepath, lineNumbers of @expandedLineNumbers
            if filepath != currentFile and lineNumbers.startRow > currentRow and
               row >= lineNumbers.startRow and row < lineNumbers.endRow
              currentRow = lineNumbers.startRow
              currentFile = filepath
            else if lineNumbers.endRow < row
              offset += (lineNumbers.endRow - lineNumbers.startRow) + 1
        if currentFile != @editor.getPath()
          row -= (currentRow + offset)
          atom.workspace.open(currentFile, {initialLine: row, initialColumn: 0}).then (editor) ->
            editor.setCursorBufferPosition([row, 0])
            editor.scrollToCursorPosition()
        else
          @gotoLine(row)
      @cancelled()
    else
      item = @getSelectedItem()
      if item?
        @confirmed(item)
      else
        @cancel()

  confirmed: (item)->
    if @editor and @editor.getPath() == item.filepath
      @gotoLine(item.line)
    else
      atom.workspace.open(item.filepath, {initialLine: item.line, initialColumn: 0}).then (editor) ->
        editor.setCursorBufferPosition([item.line, 0])
        editor.scrollToCursorPosition()
    @cancelled()


  cancelled: ->
    @items = []
    @panel.hide()
    #@focusStoredElement()
    if @pane
      @pane.activate()

  destroy: ->
    @subscriptions?.dispose()
    @subscriptions = null
    @detach()

  toggle: (searchText = '') ->
    if @panel?.isVisible()
      @panel?.show()
    else
      #@storeFocusedElement()
      @filterEditorView.setText(searchText)
      @filterEditorView.model.selectAll()
      @panel.show()
      @focusFilterEditor()
