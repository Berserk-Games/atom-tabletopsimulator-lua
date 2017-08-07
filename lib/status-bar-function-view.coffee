class StatusBarFunctionView extends HTMLElement
  init: ->
    @classList.add('status-bar-function', 'inline-block')
    @activate()

  activate: ->
    #@intervalId = setInterval @updateClock.bind(@), 100
    return true

  deactivate: ->
    #clearInterval @intervalId
    return false

  updateFunction: (functionName) ->
    @textContent = functionName

module.exports = document.registerElement('status-bar-function', prototype: StatusBarFunctionView.prototype, extends: 'div')
