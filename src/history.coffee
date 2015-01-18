{EventEmitter} = require 'events'
_ = require 'underscore'
loglet = require 'loglet'

class HistoryEntry
  constructor: (state, @title, @url) ->
    _.extend @, state
    @__ts = new Date()
  compare: (entry) ->
    if @__ts < entry.__ts
      -1
    else if @__ts == entry.__ts
      0
    else
      1

class History extends EventEmitter
  constructor: (@$, url) ->
    @inner = []
    @current = 0
    entry = @addState {}, null, url
    if history.replaceState
      history.replaceState entry, null, url
    @$(window)
      .on 'popstate', (evt) =>
        loglet.log 'History.onPopState', evt
        entry = evt.originalEvent.state
        if entry
          index = @findState entry
          # why do I care about the state? even by finding state though we won't know for sure we are moving forward or backward...
          # not unless we have the ability to carry through the full state throughout the handling chain.
          evt.historyIndex = index
          evt.historyDirection = if index > @current then 'forward' else 'backward'
          evt.historyObject = @
          @emit 'popstate', evt
    @$(document)
      .on 'click', 'a', (evt) =>
        @clearForward()
        true # continue to the next handler in chain.
  clearForward: () ->
    @inner.splice @current, @inner.length - @current
    return
  findState: (entry) ->
    @inner.indexOf(entry)
  addState: (state, title, url) ->
    # what do we want to do? we want
    # even same URL is not a gaurantee that things will be forward forward though...
    entry = new HistoryEntry(state, title, url)
    @inner.push entry
    @current = @inner.length - 1
    entry
  pushState: (state, title, url) ->
    entry = @addState state, title, url
    history.pushState entry, title, url
  pushStateIf: (state, title, url, popState) ->
    if not popState
      loglet.log 'History.pushState', url, state
      @pushState state, title, url
  replaceState: (state, title, url) ->
    history.replaceState state, title, url
  back: () ->
    history.back()
  forward: () ->
    history.forward()


module.exports = History
