#$ = require 'jquery'
util = require './util'
_ = require 'underscore'
Response = require './response'
loglet = require 'loglet'
errorlet = require 'errorlet'

default_charset = 'utf-8'
default_form_enctype = 'application/x-www-form-urlencoded'
multipart_form_data = 'multipart/form-data'

class Request
  @fromForm: (form, evt, app) ->
    charset = $(form).prop('accept-charset') or default_charset
    enctype = $(form).prop('enctype') or default_form_enctype
    new @ 
      method: $(form).prop('method')
      url: $(form).prop('action')
      body: $(form).formValue(evt)
      headers: 
        'Content-Type': if enctype == multipart_form_data then false else "#{enctype}; charset=#{charset}" 
      target: $(form).prop('target') or '_self'
      app: app
      properties:  $(form).data()
      element: form
  @fromAnchor: (anchor, evt, app) ->
    new @ 
      method: 'get'
      url: $(anchor).prop('href')
      lang: $(anchor).prop('hreflang') or 'en' 
      type: $(anchor).prop('type') or 'text/html'
      download: $(anchor).prop('download') or false
      media: $(anchor).prop('media') 
      rel: $(anchor).prop('rel')
      target: $(anchor).prop('target')
      app: app
      properties: $(anchor).data()
      element: anchor
  @fromPopState: (state, app) ->
    new @
      method: 'get'
      url: state.url
      app: app
      popState: state
      properties:  {}
  constructor: (params) ->
    _.extend @, params
    parsed = util.parse @url
    @query = _.extend @params or {}, parsed.query or {}
    @headers ||= {}
    @params ||= {}
  header: (key, val) ->
    
  param: (key, val) ->
    if @params.hasOwnProperty(key)
      @params[key]
    else if @body.hasOwnProperty(key)
      @body[key]
    else
      @query[key]
  forward: (cb) ->
    switch @method
      when 'get'
        @get cb
      when 'post'
        @post cb
      else
        cb null, errorlet.create {error: 'unimplemented_http_request', method: @method, request: @}
  request: (options, cb) ->
    $ = @app.$
    req = @
    $.ajax 
      type: options.type or 'post'
      url: options.url or @url
      data: options.data or @app.normalizeData @body
      success: (data, status, xhr) ->
        try 
          res = Response.createSuccess req, xhr, data
          cb null, res
        catch e
          cb e
      error: (xhr, status, error) ->
        try
          res = Response.createError req, xhr, data
          cb null, res
        catch e
          cb e
  post: (cb) ->
    @request {type: 'post', url: @url, headers: @headers, data: @app.normalizeData(@body)}, cb
  get: (cb) ->
    @request {type: 'get', url: @url, headers: @headers, data: @app.normalizeData(@body)}, cb

module.exports = Request
