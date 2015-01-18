Route = require './route'
util = require './util'
_ = require 'underscore'
async = require 'async'
loglet = require 'loglet'

# we do have very specific sets of requirements...
# 1 - next('route') -> allows to jump across routes.
# we can make use of the length field to determine the arguments. 
# 2 - handle
# 3 - middleware
# 4 - error handler
# so when we do series, we basically need to do the following. 
# 1- separate the error handler from the actual handler.
# 2 - chain each one separately. 
# 3 - chain them together...

series = (tasks, cb) ->
  
# 1 -> there are 2 large   

class Router
  @create: () ->
    new @()
  constructor: () ->
    @table = []
  use: (routePath, middleware..., handle) ->
    @_add /^.+$/, routePath, middleware, handle
  get: (routePath, middleware..., handle) ->
    @_add /^get$/, routePath, middleware, handle
  post: (routePath, middleware..., handle) ->
    @_add /^post$/, routePath, middleware, handle
  put: (routePath, middleware..., handle) ->
    @_add /^put$/, routePath, middleware, handle
  delete: (routePath, middleware..., handle) ->
    @_add /^delete$/, routePath, middleware, handle
  _add: (verb, routePath, middleware, handle) ->
    route = new Route routePath 
    handlers = []
    errorHandlers = []
    for task in middleware.concat(handle)
      if task.length > 2 # [ req ], [ req, next ], or [ err, req, next ]
        errorHandlers.push task
      else
        handlers.push task
    @table.push {verb: verb, route: route, handlers: handlers, errorHandlers: errorHandlers}
  match: (req) -> # we might be returning something that's different from one param to the next param??? not too certain!
    result = []
    normalized = util.normalizeURL req.url
    for {verb, route, handlers, errorHandlers} in @table
      if req.method.match verb
        params = route.match normalized
        if params
          result.push {params: params, handlers: handlers, errorHandlers: errorHandlers}
    result
  dispatch: (req, cb = () ->) ->
    routes = @match req
    loglet.log 'Router.run', req, routes
    @_runRoutes routes, 0, null, req, cb
  # when we jump route we might have jump to an error route... so it's something we need to make sure 
  # we preserve 
  _runRoutes: (routes, i, err, req, cb) ->
    if i < routes.length 
      if err 
        # we will run error routes...
        errorHelper = (handler, next) ->
          handler err, req, next
        async.eachSeries routes[i].errorHandlers, errorHelper, (err) =>
          if err == 'route'
            @_runRoutes routes, i + 1, null, req, cb
          else if err 
            @_runRoutes routes, i + 1, err, req, cb
          else
            @_runRoutes routes, i + 1, null, req, cb
      else
        helper = (handler, next) ->
          handler req, next
        req.params = routes[i].params or {}
        async.eachSeries routes[i].handlers, helper, (err) =>
          if err == 'route'
            @_runRoutes routes, i + 1, null, req, cb
          else if err
            if routes[i].errorHandlers.length > 0 
              @_runRoutes routes, i, err, req, cb
            else
              @_runRoutes routes, i + 1, err, req, cb
          else
            @_runRoutes routes, i + 1, null, req, cb
    else
      cb null

module.exports = Router