async         = require "async"
fs            = require "fs"
http          = require "http"
express       = require "express"
{testCase}    = require "nodeunit"
Configuration = require "pow/configuration"
RackHandler   = require "pow/rack_handler"

{prepareFixtures, fixturePath} = require "test_helper"

PORT = 20561

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "handling a request": (test) ->
    test.expect 1

    configuration = new Configuration root: fixturePath("apps"), logRoot: fixturePath("tmp/logs")

    handler = new RackHandler configuration, fixturePath("apps/hello")
    server  = express.createServer()
    server.get "/", (req, res, next) -> handler.handle req, res, next
    server.listen PORT, ->
      client  = http.createClient PORT
      request = client.request "GET", "/", host: "hello.test"
      request.end()
      request.on "response", (response) ->
        body = ""
        response.on "data", (chunk) -> body += chunk.toString "utf8"
        response.on "end", ->
          test.same "Hello", body
          server.close()
          test.done()
