async         = require "async"
fs            = require "fs"
http          = require "http"
express       = require "express"
{testCase}    = require "nodeunit"
Configuration = require "pow/configuration"
RackHandler   = require "pow/rack_handler"

{prepareFixtures, fixturePath, touch, serve} = require "test_helper"

serveApp = (path, callback) ->
  configuration = new Configuration root: fixturePath("apps"), logRoot: fixturePath("tmp/logs")
  handler       = new RackHandler configuration, fixturePath(path)
  server        = express.createServer()

  server.get "/", (req, res, next) ->
    handler.handle req, res, next

  serve server, (request, done) ->
    callback request, (callback) ->
      done -> handler.quit callback

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "handling a request": (test) ->
    test.expect 1
    serveApp "apps/hello", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello", body
        done -> test.done()

  "handling multiple requests": (test) ->
    test.expect 2
    serveApp "apps/pid", (request, done) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        request "GET", "/", (body) ->
          test.same pid, parseInt body
          done -> test.done()

  "handling a request, restart, request": (test) ->
    test.expect 3
    serveApp "apps/pid", (request, done) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        touch fixturePath("apps/pid/tmp/restart.txt"), ->
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.ok pid isnt newpid
            done -> test.done()

  "custom environment": (test) ->
    test.expect 1
    serveApp "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello Pow", body
        done -> test.done()
