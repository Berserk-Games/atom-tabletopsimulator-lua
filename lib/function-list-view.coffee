{$$, View} = require 'space-pen'
{SelectListView} = require 'atom-space-pen-views'
path = require 'path'

module.exports =
class FunctionListView extends SelectListView
  maxItems: 99999
  minFilterLength: 3

  initialize: (functionByName, fileMap) ->
    super
    @addClass 'tabletopsimulator-lua-goto-function'
    @editor = atom.workspace.getActiveTextEditor()
    @pane = atom.workspace.paneForItem(@editor)
    @currentRow = @editor.getCursorBufferPosition().row
    @panel = atom.workspace.addModalPanel(item: this, visible: false)
    @showFunctionName = atom.config.get('tabletopsimulator-lua.editor.showFunctionInGoto')
    @functionByName = functionByName
    @fileMap = fileMap
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
    lineCount = @editor.getLineCount()
    if line >= lineCount
      line = lineCount - 1
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
        filepath = @editor.getPath()
        row = parseInt(m[2]) - 1
        if @fileMap
          walkFileMap = (r, node) ->
            offset = 0
            if node.startRow <= r <= node.endRow
              for child in node.children
                if child.endRow < r
                  offset += (child.endRow - child.startRow) + 1
                else if r >= child.startRow
                  return walkFileMap(r, child)
              # not in any children, so is only in this file
            return [node.path, r - (node.startRow + offset)]
          [filepath, row] = walkFileMap(row, @fileMap)
        if filepath and filepath != @editor.getPath()
          console.log "Opening file in Go To Function", filepath
          atom.workspace.open(filepath, {initialLine: row, initialColumn: 0}).then (editor) ->
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
