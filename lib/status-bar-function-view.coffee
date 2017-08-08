{Disposable} = require 'atom'

module.exports =
class StatusBarFunctionView extends HTMLElement
  init: ->
    @classList.add('status-bar-function', 'inline-block')

    @link1 = document.createElement('a')
    @link1.classList.add('status-bar-function-link', 'root-item', 'inline-block')
    @link1.addEventListener('click', clickHandler)
    @clickSubscription1 = new Disposable => @link1.removeEventListener('click', clickHandler)
    @appendChild(@link1)

    @spacer1 = document.createElement('span')
    @spacer1.classList.add('status-bar-function-spacer', 'inline-block')
    @appendChild(@spacer1)

    @link2 = document.createElement('a')
    @link2.classList.add('status-bar-function-link', 'inline-block')
    @link2.addEventListener('click', clickHandler)
    @clickSubscription2 = new Disposable => @link2.removeEventListener('click', clickHandler)
    @appendChild(@link2)

    @spacer2 = document.createElement('span')
    @spacer2.classList.add('status-bar-function-spacer', 'inline-block')
    @appendChild(@spacer2)

    @link3 = document.createElement('a')
    @link3.classList.add('status-bar-function-link', 'inline-block')
    @link3.addEventListener('click', clickHandler)
    @clickSubscription3 = new Disposable => @link3.removeEventListener('click', clickHandler)
    @appendChild(@link3)

    @activate()

  activate: ->
    #@intervalId = setInterval @updateClock.bind(@), 100
    return true

  deactivate: ->
    #clearInterval @intervalId
    return false

  destroy: ->
    @clickSubscription1?.dispose()
    @clickSubscription2?.dispose()
    @clickSubscription3?.dispose()

  updateFunction: (names, rows) ->
    @link1.textContent = ""
    @link2.textContent = ""
    @link3.textContent = ""
    @spacer1.textContent = ""
    @spacer2.textContent = ""
    @link1.target = -1
    @link2.target = -1
    @link3.target = -1
    if names
      if names.length >= 1
        @link1.textContent = names[0]
        @link1.target = rows[0]
      if names.length > 3
        @spacer1.textContent = '…'
        @link2.textContent = names[names.length-2]
        @link2.target = rows[rows.length-2]
        @spacer2.textContent = '→'
        @link3.textContent = names[names.length-1]
        @link3.target = rows[rows.length-1]
      else
        if names.length >= 2
          @spacer1.textContent = '→'
          @link2.textContent = names[1]
          @link2.target = rows[1]
        if names.length == 3
          @spacer2.textContent = '→'
          @link3.textContent = names[2]
          @link3.target = rows[2]

  clickHandler = (event) =>
    row = parseInt(event.target.target)
    if row >= 0
      editor = atom.workspace.getActiveTextEditor()
      if event.shiftKey
        startRow = row
        lastRow = editor.getLastBufferRow()
        line = editor.lineTextForBufferRow(row)
        m = line.match(/^(\s*)function/)
        indent = m[1].length
        while row <= lastRow
          line = editor.lineTextForBufferRow(row)
          m = line.match(/^(\s*)end($|\s|--)/)
          if m and m[1].length == indent
            editor.setCursorBufferPosition([row, editor.lineTextForBufferRow(row).length])
            editor.selectToBufferPosition([startRow, 0])
            return
          row += 1
      else
        editor.setCursorBufferPosition([row, 0])


module.exports = document.registerElement('status-bar-function', prototype: StatusBarFunctionView.prototype, extends: 'div')
