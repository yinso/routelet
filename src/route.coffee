pathToRegExp = require 'path-to-regexp'
loglet = require 'loglet'
# express compatible route.

class Route
  constructor: (@path) ->
    @keys = []
    @regex = pathToRegExp @path, @keys
  match: (url) ->
    if @path == '/'
      return {}
    result = @regex.exec url
    if result instanceof Array
      @mapParams result
    else
      result
  # reverse would be cool but for now let's not worry about it... not until I want to write my own...
  mapParams: (result) ->
    params = {}
    for i in [1...result.length]
      params[@keys[i - 1].name] = result[i]
    params

module.exports = Route
