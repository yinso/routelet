loglet = require 'loglet'
_ = require 'underscore'
util = require './util'
errorlet = require 'errorlet'

class Response
  @create: (req, xhr, data) ->
    status = xhr.status
    # 200 family -> all good.
    # 300 will not get this...
    # 400 - client-side error.
    # 500 - server-side error.
    if xhr.status < 400
      @createSuccess req, xhr, data
    else
      @createError req, xhr, data
  @createSuccess: (req, xhr, data) ->
    $ = req.app.$
    contentType = xhr.getResponseHeader('Content-Type')
    uri = xhr.getResponseHeader('X-URL')
    if contentType.match /^text\/html/i
      new @ {elements: $(data), request: req, url: uri}
    else if contentType.match /^application\/json/i
      new @ {data: JSON.parse(data), request: req, url: uri}
    else
      throw errorlet.create {error: 'unknown_data_type', contentType: contentType, url: uri, data: data}
  @createError: (req, xhr, data) ->
    contentType = xhr.getResponseHeader('Content-Type')
    loglet.log 'Response.createError', req.url, data, contentType, xhr
    error = errorlet.create {error: 'http_response_error', statusCode: xhr.status}
    if contentType.match /^application\/json/i
      try 
        obj = JSON.parse(data)
        for key, val of obj
          error[key] = val
        new @ {error: error, request: req}
      catch e
        error.data = data
    else if contentType.match /^text\/html/i
      new @ {error: error, elements: $(data), request: req}
    else
      new @ {error: error, request: req}
  constructor: (@options) ->
    _.extend @, @options
    @url = @normalizeURL @url
    loglet.log 'Response.ctor', @url
  normalizeURL: (uri) ->
    parsed = util.parse uri
    loglet.log 'Response.normalizeURL:before', parsed
    delete parsed.query[@request.app.options.stateKeys.layout]
    loglet.log 'Response.normalizeURL:after', parsed
    util.stringify parsed
  modal: () ->
    app = @request.app
    $ = app.$
    modalID = app.options.modalID
    if not @elements
      throw errorlet.create {error: 'modal_not_a_visual_response'}
    else
      $(modalID).modal
        backdrop: true
        keyboard: true
        show: true
      $("#{modalID} .modal-body .te")
        .empty()
        .append(@elements)
        .trigger('inserted', @)
      $("#{modalID} .modal-title")
        .empty()
        .text $("#{modalID} title").text()
  redirect: (uri, data = {}) ->
    parsed = util.parse uri
    _.extend parsed.query, data
    @request.app.dispatch util.stringify(parsed)
  page: () ->
    app = @request.app
    $ = app.$
    pageID = app.options.pageID
    $(pageID)
      .empty()
      .append(@elements)
      .trigger 'inserted', [@, {url: @url, page: pageID}]

module.exports = Response
