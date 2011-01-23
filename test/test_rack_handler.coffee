async         = require "async"
fs            = require "fs"
http          = require "http"
express       = require "express"
{testCase}    = require "nodeunit"
Configuration = require "pow/configuration"
RackHandler   = require "pow/rack_handler"

{prepareFixtures, fixturePath, touch} = require "test_helper"

serve = (path, callback) ->
  handler = handlerFor path
  server  = express.createServer()
  server.get "/", (req, res, next) ->
    handler.handle req, res, next
  server.listen 0, ->
    request = createRequester server.address().port
    callback request, (callback) ->
      server.close()
      handler.quit callback

createRequester = (port) ->
  (method, path, headers, callback) ->
    callback = headers unless callback
    client   = http.createClient port
    request  = client.request method, path, headers
    request.end()
    request.on "response", (response) ->
      body = ""
      response.on "data", (chunk) -> body += chunk.toString "utf8"
      response.on "end", ->
        callback body, response

handlerFor = (path) ->
  configuration = new Configuration root: fixturePath("apps"), logRoot: fixturePath("tmp/logs")
  new RackHandler configuration, fixturePath(path)

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "handling a request": (test) ->
    test.expect 1
    serve "apps/hello", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello", body
        done -> test.done()

  "handling multiple requests": (test) ->
    test.expect 2
    serve "apps/pid", (request, done) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        request "GET", "/", (body) ->
          test.ok pid is parseInt body
          done -> test.done()

  "handling a request, restart, request": (test) ->
    test.expect 3
    serve "apps/pid", (request, done) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        touch fixturePath("apps/pid/tmp/restart.txt"), ->
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.ok pid isnt newpid
            done -> test.done()

  "custom environment": (test) ->
    test.expect 1
    serve "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello Pow", body
        done -> test.done()
