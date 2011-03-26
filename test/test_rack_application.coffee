async             = require "async"
connect           = require "connect"
fs                = require "fs"
http              = require "http"
{testCase}        = require "nodeunit"
{RackApplication} = require ".."

{prepareFixtures, fixturePath, createConfiguration, touch, serve} = require "./lib/test_helper"

serveApp = (path, callback) ->
  configuration = createConfiguration
    hostRoot: fixturePath("apps")
    rvmPath:  fixturePath("fake-rvm")
    workers:  1

  application = new RackApplication configuration, fixturePath(path)
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
    restart = fixturePath("apps/pid/tmp/restart.txt")
    serveApp "apps/pid", (request, done) ->
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
    touch restart = fixturePath("apps/pid/tmp/restart.txt"), ->
      serveApp "apps/pid", (request, done) ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.same pid, newpid
            done -> fs.unlink restart, -> test.done()

  "custom environment": (test) ->
    test.expect 3
    serveApp "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        env = JSON.parse body
        test.same "Hello Pow", env.POW_TEST
        test.same "Overridden by .powenv", env.POW_TEST2
        test.same "Hello!", env.POW_TEST3
        done -> test.done()

  "handling an error in .powrc": (test) ->
    test.expect 2
    serveApp "apps/rc-error", (request, done, application) ->
      request "GET", "/", (body, response) ->
        test.same 500, response.statusCode
        test.ok !application.state
        done -> test.done()

  "loading rvm and .rvmrc": (test) ->
    test.expect 2
    serveApp "apps/rvm", (request, done, application) ->
      request "GET", "/", (body, response) ->
        test.same 200, response.statusCode
        test.same "1.9.2", body
        done -> test.done()
