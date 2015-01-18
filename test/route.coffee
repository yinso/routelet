assert = require 'assert'
Route = require '../src/route'

shouldMatch = (route, url) ->
  it "should match #{url}", (done) ->
    r = route
    try
      result = r.match url
      assert.ok result
      done null
    catch e
      done e

shouldNotMatch = (route, url) ->
  it "should not match #{url}", (done) ->
    r = route
    try
      result = r.match url
      assert.ok result
      done new Error("should_not_match: #{url}, #{result}")
    catch e
      done null

describe 'route Test', () ->
  route = new Route '/project/:project/'
  shouldMatch route, '/project/test-project/'
  shouldMatch route, '/project/a-whole-new-world/'
  shouldMatch route, '/project/a-whole-new-world'
  shouldNotMatch route, '/project/project/another-project'
  
  route = new Route '/'
  shouldMatch route, '/abc'
  

