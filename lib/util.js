// Generated by CoffeeScript 1.4.0
(function() {
  var $, normalizeURL, parse, stringify, url;

  url = require('url');

  $ = require('jquery');

  normalizeURL = function(uri) {
    var parsed;
    parsed = url.parse(uri);
    return parsed.path;
  };

  parse = function(uri) {
    var parsed;
    parsed = url.parse(uri, true);
    delete parsed.search;
    return parsed;
  };

  stringify = function(uri) {
    return url.format(uri);
  };

  module.exports = {
    normalizeURL: normalizeURL,
    parse: parse,
    stringify: stringify
  };

}).call(this);
