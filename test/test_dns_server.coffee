Configuration = require "pow/configuration"
DnsServer     = require "pow/dns_server"
async         = require "async"
{exec}        = require "child_process"
{testCase}    = require "nodeunit"

{prepareFixtures, fixturePath} = require "test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "responds to all A queries for the configured domain": (test) ->
    test.expect 3

    configuration = new Configuration root: fixturePath("tmp"), domain: "powtest"
    dnsServer = new DnsServer configuration
    dnsServer.listen 0, ->
      {address, port} = dnsServer.address()
      resolve = (domain, callback) ->
        exec "dig -p #{port} +short hello.powtest @#{address}", (err, stdout, stderr) ->
          callback stdout.trim()

      async.parallel [
        (o) -> resolve "hello.powtest", (result) -> o test.same "127.0.0.1", result
        (o) -> resolve "a.b.c.powtest", (result) -> o test.same "127.0.0.1", result
        (o) -> resolve "powtest.",      (result) -> o test.same "127.0.0.1", result
      ], test.done
