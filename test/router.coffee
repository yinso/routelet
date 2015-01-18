Router = require '../src/router'
Request = require '../src/request'
loglet = require 'loglet'

router = new Router()

r1 = (req) ->
  loglet.log 'got here', req.url, req.body, req.query, req.params

router.use '/', (req, next) ->
  loglet.log 'this is always executed?'
  next null

router.use '/', (req, next) ->
  loglet.log 'Yes it is...'

router.use '/abc/:def', r1

router.dispatch new Request {url: '/abc/xyz', method: 'get', body: {}, query: {}, app: {}}
