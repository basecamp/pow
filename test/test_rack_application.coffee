async             = require "async"
connect           = require "connect"
fs                = require "fs"
http              = require "http"
{testCase}        = require "nodeunit"
{RackApplication} = require ".."

{prepareFixtures, fixturePath, createConfiguration, touch, swap, serve} = require "./lib/test_helper"

serveApp = (path, callback) ->
  configuration = createConfiguration
    POW_HOST_ROOT: fixturePath("apps")
    POW_RVM_PATH:  fixturePath("fake-rvm")
    POW_WORKERS:   1

  @application = new RackApplication configuration, fixturePath(path)
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

  "handling a request when restart.txt is present and the worker has timed out": (test) ->
    serveApp "apps/pid", (request, done, app) ->
      request "GET", "/", (body) ->
        test.ok pid = parseInt body
        app.pool.quit ->
          touch restart = fixturePath("apps/pid/tmp/restart.txt"), ->
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink restart, -> test.done()

  "handling a request, always_restart.txt present, request": (test) ->
    test.expect 3
    always_restart = fixturePath("apps/pid/tmp/always_restart.txt")
    serveApp "apps/pid", (request, done) ->
      fs.unlink always_restart, ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          touch always_restart, ->
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink always_restart, -> test.done()

  "always_restart.txt present, handling a request, request": (test) ->
    test.expect 3
    touch always_restart = fixturePath("apps/pid/tmp/always_restart.txt"), ->
      serveApp "apps/pid", (request, done) ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.ok pid isnt newpid
            done -> fs.unlink always_restart, -> test.done()

  "always_restart.txt present, handling a request, touch restart.txt, request": (test) ->
    test.expect 3
    touch always_restart = fixturePath("apps/pid/tmp/always_restart.txt"), ->
      serveApp "apps/pid", (request, done) ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          touch restart = fixturePath("apps/pid/tmp/restart.txt"), ->
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink always_restart, fs.unlink restart, -> test.done()

  "handling the initial request when restart.txt and always_restart.txt is present": (test) ->
    test.expect 3
    touch always_restart = fixturePath("apps/pid/tmp/always_restart.txt"), ->
      touch restart = fixturePath("apps/pid/tmp/restart.txt"), ->
        serveApp "apps/pid", (request, done) ->
          request "GET", "/", (body) ->
            test.ok pid = parseInt body
            request "GET", "/", (body) ->
              test.ok newpid = parseInt body
              test.ok pid isnt newpid
              done -> fs.unlink restart, fs.unlink always_restart, -> test.done()

  "always_restart.txt present, handling a request, request, request": (test) ->
    test.expect 5
    touch always_restart = fixturePath("apps/pid/tmp/always_restart.txt"), ->
      serveApp "apps/pid", (request, done) ->
        request "GET", "/", (body) ->
          test.ok pid = parseInt body
          request "GET", "/", (body) ->
            test.ok newpid = parseInt body
            test.ok pid isnt newpid
            request "GET", "/", (body) ->
              test.ok newerpid = parseInt body
              test.ok newpid isnt newerpid
              done -> fs.unlink always_restart, -> test.done()

  "custom environment": (test) ->
    test.expect 3
    serveApp "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        env = JSON.parse body
        test.same "Hello Pow", env.POW_TEST
        test.same "Overridden by .powenv", env.POW_TEST2
        test.same "Hello!", env.POW_TEST3
        done -> test.done()

  "custom environments are reloaded after a restart": (test) ->
    serveApp "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        test.same "Hello!", JSON.parse(body).POW_TEST3
        powenv1 = fixturePath("apps/env/.powenv")
        powenv2 = fixturePath("apps/env/.powenv2")
        swap powenv1, powenv2, (err, unswap) ->
          touch restart = fixturePath("apps/env/tmp/restart.txt"), ->
            request "GET", "/", (body) ->
              test.same "Goodbye!", JSON.parse(body).POW_TEST3
              done -> unswap -> fs.unlink restart, -> test.done()

  "custom worker/timeout values are loaded": (test) ->
    serveApp "apps/env", (request, done) ->
      request "GET", "/", (body) ->
        test.same @application.pool.processOptions.idle, 900 * 1000
        test.same @application.pool.workers.length, 1
        powenv1 = fixturePath("apps/env/.powenv")
        powenv2 = fixturePath("apps/env/.powenv2")
        swap powenv1, powenv2, (err, unswap) ->
          touch restart = fixturePath("apps/env/tmp/restart.txt"), ->
            request "GET", "/", (body) ->
              test.same @application.pool.processOptions.idle, 500 * 1000
              test.same @application.pool.workers.length, 3
              done -> unswap -> fs.unlink restart, -> test.done()

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

