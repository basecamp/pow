http          = require "http"
Configuration = require "pow/configuration"
HttpServer    = require "pow/http_server"
async         = require "async"
{testCase}    = require "nodeunit"

{prepareFixtures, fixturePath, serve} = require "test_helper"

serveRoot = (root, options, callback) ->
  unless callback
    callback = options
    options  = {}
  configuration = new Configuration
    root:    fixturePath(root),
    logRoot: fixturePath("tmp/logs")
    dstPort: options.dstPort ? 80
  serve new HttpServer(configuration), callback

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "serves requests from multiple apps": (test) ->
    test.expect 4
    serveRoot "apps", (request, done) ->
      async.parallel [
        (proceed) ->
          request "GET", "/", host: "hello.test", (body) ->
            test.same "Hello", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "www.hello.test", (body) ->
            test.same "Hello", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "env.test", (body) ->
            test.same "Hello Pow", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "pid.test", (body) ->
            test.ok body.match /^\d+$/
            proceed()
      ], ->
        done -> test.done()

  "responds with a custom 503 when a domain isn't configured": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/redirect", host: "nonexistent.test", (body, response) ->
        test.same 503, response.statusCode
        test.same "NonexistentDomain", response.headers["x-pow-handler"]
        done -> test.done()

  "responds with a custom 500 when an app can't boot": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/", host: "error.test", (body, response) ->
        test.same 500, response.statusCode
        test.same "ApplicationException", response.headers["x-pow-handler"]
        done -> test.done()

  "respects public-facing port in redirects": (test) ->
    test.expect 2
    async.series [
      (proceed) ->
        serveRoot "apps", dstPort: 80, (request, done) ->
          request "GET", "/redirect", host: "hello.test", (body, response) ->
            test.same "http://hello.test/", response.headers.location
            done proceed
      (proceed) ->
        serveRoot "apps", dstPort: 81, (request, done) ->
          request "GET", "/redirect", host: "hello.test", (body, response) ->
            test.same "http://hello.test:81/", response.headers.location
            done proceed
    ], test.done
