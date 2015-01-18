url = require 'url'

normalizeURL = (uri) ->
  parsed = url.parse uri
  parsed.path

parse = (uri) ->
  parsed = url.parse uri, true
  delete parsed.search
  parsed

stringify = (uri) ->
  url.format uri

module.exports = 
  normalizeURL: normalizeURL
  parse: parse
  stringify: stringify


