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
    contentType = xhr.getResponseHeader('Content-Type')
    uri = xhr.getResponseHeader('X-URL')
    resetModal = _hasResetModal xhr
    clientRedirect = xhr.getResponseHeader('X-CLIENT-REDIRECT')
    if clientRedirect
      # we want to now cause a client-side redirect...
      new @ {redirectURL: clientRedirect, request: req, url: uri, resetModal: resetModal}
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
  normalizeURL: (uri) ->
    parsed = util.parse uri
    delete parsed.query[@request.app.options.stateKeys.layout]
    util.stringify parsed
  render: () ->
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
      @page()
  modal: (modalID = @request.app.options.modalID) ->
    app = @request.app
    $ = app.$
    if not @elements
      throw errorlet.create {error: 'modal_not_a_visual_response'}
    else
      app.setPageMode 'modal'
      $("#{modalID} .modal-body").fadeOut 'slow', () =>
        $("#{modalID} .modal-body")
          .empty()
          .append(@elements)
          .fadeIn('slow')
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
  page: () ->
    app = @request.app
    $ = app.$
    pageID = app.options.pageID
    app.setPageMode 'page'
    $(pageID).fadeOut 'slow', () =>
      $(pageID)
        .empty()
        .append(@elements)
        .fadeIn('slow')
        .trigger 'inserted', [@, {url: @url, page: pageID}]

module.exports = Response
