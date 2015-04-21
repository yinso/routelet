loglet = require 'loglet'
_ = require 'underscore'
util = require './util'
errorlet = require 'errorlet'

_hasResetModal = (xhr) ->
  header = xhr.getResponseHeader('X-RESET-MODAL')
  loglet.log '_hasResetModal', xhr.url, header
  if header then true else false

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
    contentType = xhr.getResponseHeader('content-type')
    uri = xhr.getResponseHeader('X-URL')
    resetModal = _hasResetModal xhr
    clientRedirect = xhr.getResponseHeader('X-CLIENT-REDIRECT')
    if clientRedirect
      # we want to now cause a client-side redirect...
      new @ {redirectURL: clientRedirect, request: req, url: uri, resetModal: resetModal}
    else if not contentType # no content type there might not be anything to show
      throw errorlet.create {error: 'unknown_data_type', contentType: contentType, url: uri, data: data, resetModal: resetModal}
    else if contentType.match /^text\/html/i
      new @ {elements: $(data), request: req, url: uri, resetModal: resetModal}
    else if contentType.match /^application\/json/i
      obj = 
        if data instanceof Object then data else JSON.parse(data)
      new @ {data: obj, request: req, url: uri, resetModal: resetModal}
    else
      throw errorlet.create {error: 'unknown_data_type', contentType: contentType, url: uri, data: data, resetModal: resetModal}
  @createError: (req, xhr, data) ->
    contentType = xhr.getResponseHeader('Content-Type')
    error = errorlet.create {error: 'http_response_error', statusCode: xhr.status}
    if not contentType
      new @ {error: error, request: req, url: req.url}
    else if contentType.match /^application\/json/i
      try 
        obj = JSON.parse(data)
        for key, val of obj
          error[key] = val
        new @ {error: error, request: req, url: req.url}
      catch e
        error.data = data
    else if contentType.match /^text\/html/i
      loglet.log 'error.html', req.url, contentType, data
      new @ {error: error, elements: $(data), request: req, url: req.url}
    else
      new @ {error: error, request: req, url: req.url}
  constructor: (@options) ->
    _.extend @, @options
    @url = @normalizeURL @url
  normalizeURL: (uri) ->
    parsed = util.parse uri
    delete parsed.query[@request.app.options.stateKeys.layout]
    util.stringify parsed
  render: (elementID = null) ->
    # we go to modal for the following reasons... 
    # modal 
    loglet.log 'Response.render.resetModal', @resetModal, @request.app.pageMode
    if @resetModal
      @request.app.setPageMode 'page'
    if @redirectURL
      @redirect @redirectURL
    else if @request.properties.hasOwnProperty('modal') or @request.app.pageMode == 'modal'
      @modal @request.properties.modal
    else
      @page(elementID)
  modal: (modalID = @request.app.options.modalID) ->
    app = @request.app
    $ = app.$
    if not @elements
      throw errorlet.create {error: 'modal_not_a_visual_response'}
    else
      app.setPageMode 'modal'
      $("#{modalID} .modal-body").fadeOut 'fast', () =>
        $("#{modalID} .modal-body")
          .empty()
          .append(@elements)
          .fadeIn('fast')
          .trigger('inserted', @)
      title = @elements.find("div.title").text()
      @elements.find("div.title").empty()
      $("#{modalID} .modal-title")
        .empty()
        .text title
      $(modalID).focus() # needed to ensure the modal still receive events.
  redirect: (uri, data = {}) ->
    parsed = util.parse uri
    _.extend parsed.query, data
    normalized = util.stringify(parsed)
    @request.app.dispatch normalized
  renderWidget: (elementID) ->
    app = @request.app
    $ = app.$
    $(elementID).fadeOut 'fast', () =>
      $(elementID)
        .empty()
        .append(@elements)
        .fadeIn('fast')
  page: (elementID = @request.app.options.pageID) ->
    app = @request.app
    $ = app.$
    app.setPageMode 'page'
    $(elementID).fadeOut 'fast', () =>
      $(elementID)
        .empty()
        .append(@elements)
        .fadeIn('fast')
        .trigger 'inserted', [@, {url: @url, page: elementID}]

module.exports = Response
