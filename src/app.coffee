Router = require './router'
Request = require './request'
$ = require 'jquery'
require 'bootstrap'
loglet = require 'loglet'
util = require './util'
errorlet = require 'errorlet'
_ = require 'underscore'
History = require './history'
Validator = require 'checklet'
{EventEmitter} = require 'events'

isFunction = (o) ->
  typeof(o) == 'function' or o instanceof Function

aryToObj = (ary, obj = {}) ->
  for {name, value} in ary 
    if obj.hasOwnProperty(name)
      if obj[name] instanceof Array
        obj[name].push value
      else
        obj[name] = [ obj[name], value ]
    else
      obj[name] = value
  obj

$.fn.formValue = (evt = {}) ->
  obj = aryToObj($(this).serializeArray())
  if evt.hasOwnProperty('target')
    obj[evt.target.name] = evt.target.value
  obj

defaultOptions = 
  pageID: '#main'
  modalID: '#myModal'
  stateKeys: 
    continue: '*cnt'
    layout: '*l'
  everyReq: {}


class Application extends EventEmitter
  @Router: Router
  @Validator: Validator
  @create: (options = {}) ->
    new @ options
  constructor: (options = {}) ->
    @options = _.extend {}, defaultOptions, options
    @$ = $
    @location = util.parse window.location.href
    @router = new Router()
    @options.modalID ||= '#myModal'
    # I think the idea is to have some sort of timestamp... 
    # also trying to figure out whether or not something has 
  initialize: (options, cb) ->
    app = @
    $ = app.$
    $ () ->
      app.history = new History $, app.location.path
      #window.onerror = (evt) ->
      #  loglet.log 'uncaught exception', arguments
      app.initializeWidgets()
      $(document)
        .on 'inserted', (evt, res, options = {}) ->
          app.initializeWidgets res.elements
          if options.url
            app.history.pushStateIf options, null, options.url, res.request.popState
          false
        .on 'submit', 'form', (evt) ->
          app.onFormSubmit @, evt
          false
        .on 'click', 'a', (evt) ->
          loglet.log 'a.click', @, app.isExternalURL $(@).prop('href')
          if app.isExternalURL $(@).prop('href')
            window.open $(@).prop('href'), '_blank'
            false
          else
            req = Request.fromAnchor @, evt, app
            app.dispatch req
            false
      app.history.on 'popstate', (evt) ->
        loglet.log 'window.popState', evt
        req = Request.fromPopState evt, app
        app.dispatch req
      if isFunction(cb)
        cb app
    app
  _add: (verb, routePath, middlewares, handle) ->
    if typeof(routePath) != 'string'
      @_add verb, '/', [routePath].concat(middlewares), handle
    else
      @router._add verb, routePath, middlewares, handle
    @
  use: (routePath, middlewares..., handle) ->
    @_add /^.+$/, routePath, middlewares, handle
  get: (routePath, middlewares..., handle) ->
    @_add /^get$/, routePath, middlewares, handle
  post: (routePath, middlewares..., handle) -> # this is something that we would want to do *before* post? not too certain what the deal will be...
    @_add /^post$/, routePath, middlewares, handle
  put: (routePath, middlewares..., handle) ->
    @_add /^put$/, routePath, middlewares, handle
  delete: (routePath, middlewares..., handle) ->
    @_add /^delete$/, routePath, middlewares, handle
  # but this is not the problem... what we want to do is to actually bind the 
  dispatch: (req, cb = () ->) ->
    @router.dispatch req, cb
  # I want this to 
  initializeWidgets: (elts = @$(document)) ->
    @initializeForms elts
    @initializeAnchors elts
  initializeForms: (elts) ->
    app = @
    elts.find('form')
      .each (i, form) ->
        app.bindForm form
  bindForm: (form) ->
    app = @
    $ = @$
    obj = {}
    bindElement = (elt) ->
      if $(elt).data('validate')
        validator = Validator.make $(elt).data('validate')
        validator.on 'validate-error', (err) ->
          app.emit 'validate-error', elt, err
        $(elt).on 'blur', (evt) ->
          validator.validate $(elt).val()
        obj[$(elt).prop('name')] = validator
    for elt in form.elements
      bindElement elt
    formValidator = Validator.make {object: obj}
    formValidator.on 'validate-error', (err) ->
      #loglet.error 'form-validate', err
      app.raiseFormError form, err
    #formValidator.on 'validate-ok', (err) ->
    #  app.raiseFormError form, err
    $(form).data '_validator', formValidator
  onFormSubmit: (form, evt) ->
    try 
      app = @
      $ = @$
      validator = $(form).data('_validator')
      data = $(form).formValue(evt)
      loglet.log 'onFormSubmit', form, evt, data
      validator.async data, (err) =>
        try 
          if err 
            app.raiseFormError form, err
          else
            req = Request.fromForm form, evt, app
            loglet.log 'onFormSubmit.OK', req, evt
            app.dispatch req
        catch e 
          loglet.error 'onFormSubmit.dispatch.error', e
    catch e
      loglet.error e
  raiseFormError: (form, err) ->
    for key, error of err.errors or {}
      elt = form.elements[key]
      if elt
        @emit 'validate-error', elt, error
  isExternalURL: (href) ->
    parsed = util.parse href
    @location.host != parsed.host
  initializeAnchors: (elts) ->
    app = @
    elts.find('a')
      .each (i, anchor) ->
        if app.isExternalURL app.$(anchor).prop('href')
          $(anchor).addClass 'external'
      ###
      .on 'click', (evt) ->
        loglet.log 'a.click', @, app.isExternalURL $(@).prop('href')
        if app.isExternalURL $(@).prop('href')
          window.open $(@).prop('href'), '_blank'
          false
        else
          req = Request.fromAnchor @, evt, app
          app.dispatch req
          false
      ###
  normalizeData: (data = {}) ->
    state = {}
    state[@options.stateKeys.layout] = false
    data = _.extend {}, @options.everyReq or {}, state, data
    data
  modal: (res) ->
    $ = @$

module.exports = Application
