http            = require "http"
{HttpServer}    = require ".."
async           = require "async"
{testCase}      = require "nodeunit"

{prepareFixtures, fixturePath, createConfiguration, swap, serve} = require "./lib/test_helper"

serveRoot = (root, options, callback) ->
  unless callback
    callback = options
    options  = {}
  configuration = createConfiguration
    hostRoot: fixturePath(root),
    dstPort:  options.dstPort ? 80
  if root is "proxies"
    # there's a proxy setup in this dir to 14136
    # let's create an app for it
    appOnPort = http.createServer (req, res) ->
      res.writeHead 200, 'Content-Type': 'text/plain'
      res.end "I'm on a port"
    appOnPort.listen 14136, ->
      serve new HttpServer(configuration), (request, done, server) ->
        callback request, (callback) ->
          appOnPort.close()
          done(callback)
        , server
  else
    serve new HttpServer(configuration), callback

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "serves requests from multiple apps": (test) ->
    test.expect 4
    serveRoot "apps", (request, done) ->
      async.parallel [
        (proceed) ->
          request "GET", "/", host: "hello.dev", (body) ->
            test.same "Hello", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "www.hello.dev", (body) ->
            test.same "Hello", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "env.dev", (body) ->
            test.same "Hello Pow", JSON.parse(body).POW_TEST
            proceed()
        (proceed) ->
          request "GET", "/", host: "pid.dev", (body) ->
            test.ok body.match /^\d+$/
            proceed()
      ], ->
        done -> test.done()

  "serves requests for proxied apps": (test) ->
    test.expect 1
    serveRoot "proxies", (request, done) ->
      request "GET", "/", host: "port.dev", (body) ->
        test.same "I'm on a port", body
        done -> test.done()

  "responds with a custom 503 when a domain isn't configured": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/redirect", host: "nonexistent.dev", (body, response) ->
        test.same 503, response.statusCode
        test.same "application_not_found", response.headers["x-pow-template"]
        done -> test.done()

  "responds with a custom 500 when an app can't boot": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/", host: "error.dev", (body, response) ->
        test.same 500, response.statusCode
        test.same "error_starting_application", response.headers["x-pow-template"]
        done -> test.done()

  "recovering from a boot error": (test) ->
    test.expect 3
    config = fixturePath "apps/error/config.ru"
    ok = fixturePath "apps/error/ok.ru"
    serveRoot "apps", (request, done) ->
      request "GET", "/", host: "error.dev", (body, response) ->
        test.same 500, response.statusCode
        swap config, ok, (err, unswap) ->
          request "GET", "/", host: "error.dev", (body, response) ->
            test.same 200, response.statusCode
            test.same "OK", body
            done -> unswap -> test.done()

  "respects public-facing port in redirects": (test) ->
    test.expect 2
    async.series [
      (proceed) ->
        serveRoot "apps", dstPort: 80, (request, done) ->
          request "GET", "/redirect", host: "hello.dev", (body, response) ->
            test.same "http://hello.dev/", response.headers.location
            done proceed
      (proceed) ->
        serveRoot "apps", dstPort: 81, (request, done) ->
          request "GET", "/redirect", host: "hello.dev", (body, response) ->
            test.same "http://hello.dev:81/", response.headers.location
            done proceed
    ], test.done

  "serves static assets in public/": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/robots.txt", host: "hello.dev", (body, response) ->
        test.same 200, response.statusCode
        test.same "User-Agent: *\nDisallow: /\n", body
        done -> test.done()

  "serves static assets from non-Rack applications": (test) ->
    test.expect 3
    async.series [
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "static.dev", (body, response) ->
            test.same 200, response.statusCode
            test.same "<!doctype html>\nhello world!\n", body
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/nonexistent", host: "static.dev", (body, response) ->
            test.same 404, response.statusCode
            done proceed
    ], test.done

  "passes urls with .. through to the application": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/..", host: "hello.dev", (body, response) ->
        test.same 200, response.statusCode
        test.same "..", body
        done -> test.done()

  "post request": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "POST", "/post", host: "hello.dev", data: "foo=bar", (body, response) ->
        test.same 200, response.statusCode
        test.same "foo=bar", body
        done -> test.done()

  "hostnames are case-insensitive": (test) ->
    test.expect 6
    async.series [
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "Capital.dev", (body, response) ->
            test.same 200, response.statusCode
            test.ok !response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "capital.dev", (body, response) ->
            test.same 200, response.statusCode
            test.ok !response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "CAPITAL.DEV", (body, response) ->
            test.same 200, response.statusCode
            test.ok !response.headers["x-pow-template"]
            done proceed
    ], test.done

  "request to unsupported domain shows the welcome page": (test) ->
    test.expect 10
    async.series [
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", {}, (body, response) ->
            test.same 200, response.statusCode
            test.same "welcome", response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "dev", (body, response) ->
            test.same 200, response.statusCode
            test.same "welcome", response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "dev.", (body, response) ->
            test.same 200, response.statusCode
            test.same "welcome", response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "127.0.0.1", (body, response) ->
            test.same 200, response.statusCode
            test.same "welcome", response.headers["x-pow-template"]
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/", host: "localhost", (body, response) ->
            test.same 200, response.statusCode
            test.same "welcome", response.headers["x-pow-template"]
            done proceed
    ], test.done

  "request without host header serves the default app": (test) ->
    test.expect 2
    serveRoot "configuration-with-default", (request, done) ->
      request "GET", "/", {}, (body, response) ->
        test.same 200, response.statusCode
        test.same "Hello", body
        done -> test.done()

  "serves /favicon.ico for the welcome page and static sites": (test) ->
    test.expect 4
    async.series [
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/favicon.ico", host: "static.dev", (body, response) ->
            test.same 200, response.statusCode
            test.same "", body
            done proceed
      (proceed) ->
        serveRoot "apps", (request, done) ->
          request "GET", "/favicon.ico", host: "localhost", (body, response) ->
            test.same 200, response.statusCode
            test.same "", body
            done proceed
    ], test.done

  "shows a warning for a Rails app without config.ru": (test) ->
    test.expect 2
    serveRoot "apps", (request, done) ->
      request "GET", "/", host: "rails.dev", (body, response) ->
        test.same 503, response.statusCode
        test.same "rackup_file_missing", response.headers["x-pow-template"]
        done -> test.done()

  "http://pow/config.json": (test) ->
    test.expect 2
    serveRoot "apps", (request, done, server) ->
      request "GET", "/config.json", host: "pow", (body, response) ->
        test.same 200, response.statusCode
        test.same server.configuration.toJSON(), JSON.parse body
        done -> test.done()

  "http://pow/status.json": (test) ->
    test.expect 2
    serveRoot "apps", (request, done, server) ->
      request "GET", "/status.json", host: "pow", (body, response) ->
        test.same 200, response.statusCode
        test.same server.toJSON(), JSON.parse body
        done -> test.done()
