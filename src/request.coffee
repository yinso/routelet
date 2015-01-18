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
  @fromAnchor: (form, evt, app) ->
    new @ 
      method: 'get'
      url: $(form).prop('href')
      lang: $(form).prop('hreflang') or 'en' 
      type: $(form).prop('type') or 'text/html'
      download: $(form).prop('download') or false
      media: $(form).prop('media') 
      rel: $(form).prop('rel')
      target: $(form).prop('target')
      app: app
  @fromPopState: (evt, app) ->
    new @
      method: 'get'
      url: evt.originalEvent.state?.url or evt.originalEvent.explicitOriginalTarget.location.href
      app: app
      popState: evt.originalEvent.state
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
  post: (cb) ->
    $ = @app.$
    req = @
    data = @app.normalizeData @body
    $.ajax 
      type: 'post'
      url: @url
      headers: @headers
      data: data
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
  get: (cb) ->
    $ = @app.$
    req = @
    data = @app.normalizeData @body
    $.ajax 
      type: 'get'
      url: @url
      headers: @headers
      data: data
      success: (data, status, xhr) ->
        try 
          res = Response.createSuccess req, xhr, data
          cb null, res
        catch e
          cb e
      error: (xhr, status, error) ->
        loglet.log 'request.get', req.url, status, error
        try
          res = Response.createError req, xhr, error
          cb null, res
        catch e
          cb e

module.exports = Request
