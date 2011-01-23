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
    test.expect 4

    configuration = new Configuration root: fixturePath("tmp"), domain: "powtest"
    dnsServer = new DnsServer configuration
    dnsServer.listen 0, ->
      {address, port} = dnsServer.address()

      resolve = (domain, callback) ->
        cmd = "dig -p #{port} @#{address} #{domain} +noall +answer +comments"
        exec cmd, (err, stdout, stderr) ->
          status = stdout.match(/status: (.*?),/)?[1]
          answer = stdout.match(/IN\tA\t([\d.]+)/)?[1]
          callback status, answer

      testResolves = (host, expectedStatus, expectedAnswer) ->
        (callback) -> resolve host, (status, answer) ->
          test.same [expectedStatus, expectedAnswer], [status, answer]
          callback()

      async.parallel [
        testResolves "hello.powtest", "NOERROR", "127.0.0.1"
        testResolves "a.b.c.powtest", "NOERROR", "127.0.0.1"
        testResolves "powtest.",      "NOERROR", "127.0.0.1"
        testResolves "foo.",          "NXDOMAIN"
      ], test.done
