net = require "net"
{testCase} = require "nodeunit"
{Configuration, Daemon} = require ".."
{prepareFixtures, fixturePath} = require "./lib/test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "start and stop": (test) ->
    test.expect 2

    configuration = new Configuration hostRoot: fixturePath("tmp"), httpPort: 0, dnsPort: 0
    daemon = new Daemon configuration

    daemon.start()
    daemon.on "start", ->
      test.ok daemon.started
      daemon.stop()
      daemon.on "stop", ->
        test.ok !daemon.started
        test.done()

  # "start rolls back when it can't boot a server": (test) ->
  #   test.expect 2

  #   server = net.createServer()
  #   server.listen 0, ->
  #     port = server.address().port
  #     configuration = new Configuration hostRoot: fixturePath("tmp"), httpPort: port
  #     daemon = new Daemon configuration

  #     daemon.start()
  #     daemon.on "error", (err) ->
  #       test.ok err
  #       test.ok !daemon.started
  #       server.close()
  #       test.done()

module.exports = {}
