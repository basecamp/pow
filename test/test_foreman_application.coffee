async                = require "async"
connect              = require "connect"
fs                   = require "fs"
http                 = require "http"
{testCase}           = require "nodeunit"
{HttpServer, ForemanApplication} = require "../lib"

{prepareFixtures, fixturePath, createConfiguration, touch, swap, serve} = require "./lib/test_helper"

serveApp = (path, callback) ->
  configuration = createConfiguration
    hostRoot: fixturePath("apps")
    rvmPath:  fixturePath("fake-rvm")
    workers:  1

  application = new ForemanApplication configuration, fixturePath(path)
  server = connect.createServer()

  server.use (req, res, next) ->
    if req.url is "/"
      application.handle req, res, next
    else
      next()

  serve server, (request, done) ->
    callback request, (callback) ->
      done -> application.quit callback
    , application

serveRoot = (root, options, callback) ->
  unless callback
    callback = options
    options  = {}
  configuration = createConfiguration
    hostRoot: fixturePath(root),
    dstPort:  options.dstPort ? 80
  serve new HttpServer(configuration), callback

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "handling a request": (test) ->
    test.expect 1
    serveApp "apps/hello-node", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello World", body
        done -> test.done()

  "custom Procfile": (test) ->
    test.expect 1
    serveApp "apps/hello-coffee", (request, done) ->
      request "GET", "/", (body, response) ->
        test.same "Hello Procfile.dev!", body
        done -> test.done()

  "warn when there's no 'web' process": (test) ->
    test.expect 3
    serveApp "apps/foreman-noweb", (request, done, application) ->
      request "GET", "/", (body, response) ->
        test.same 500, response.statusCode
        test.same application.state, "terminating"
        test.ok /Foreman didn\'t start any `web` processes. Check your Procfile/(body)
        done -> test.done()

  "starts multiple workers": (test) ->
    test.expect 5
    serveApp "apps/multi-node", (request, done) ->
      ports = {}
      async.parallel [
        (proceed) ->
          request "GET", "/", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
      ], ->
        count = 0
        for own key, value of ports
          count++

        test.ok count > 1, "Should have seen more than 1 backend port: #{JSON.stringify ports}"
        done -> test.done()

  "mounts multiple node apps side-by-side": (test) ->
    test.expect 7
    serveRoot "two-nodes", (request, done) ->
      ports = {}
      async.parallel [
        (proceed) ->
          request "GET", "/", host: "multi-node.dev", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", host: "multi-node.dev", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", host: "multi-node.dev", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", host: "multi-node.dev", (body) ->
            match = /^Hello World from ([0-9]+)/(body)
            test.ok match, "...but was #{body}"
            ports[match[1]] = true if match?[1]?
            proceed()
        (proceed) ->
          request "GET", "/", host: "hello-node.dev", (body) ->
            test.same "Hello World", body
            proceed()
        (proceed) ->
          request "GET", "/", host: "hello-node.dev", (body) ->
            test.same "Hello World", body
            proceed()
      ], ->
        count = 0
        for own key, value of ports
          count++
  
        test.ok count > 1, "Should have seen more than 1 backend port: #{JSON.stringify ports}"
        done -> test.done()

  "handling a request, restart, request": (test) ->
    test.expect 3
    restart = fixturePath("apps/node-restart/tmp/restart.txt")
    serveApp "apps/node-restart", (request, done) ->
      fs.unlink restart, ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          touch restart, ->
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink restart, -> test.done()

  "handling the initial request when restart.txt is present": (test) ->
    test.expect 3
    touch restart = fixturePath("apps/node-restart/tmp/restart.txt"), ->
      serveApp "apps/node-restart", (request, done) ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.same pid, newpid
            done -> fs.unlink restart, -> test.done()

  "handling a request when restart.txt is present and the worker has timed out": (test) ->
    serveApp "apps/node-restart", (request, done, app) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        app.quit ->
          touch restart = fixturePath("apps/node-restart/tmp/restart.txt"), ->
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink restart, -> test.done()

