{DnsServer}     = require ".."
async           = require "async"
{exec}          = require "child_process"
{testCase}      = require "nodeunit"

{prepareFixtures, createConfiguration} = require "./lib/test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "responds to all A queries for the configured domain": (test) ->
    test.expect 12

    exec "which dig", (err) ->
      if err
        console.warn "Skipping test, system is missing `dig`"
        test.expect 0
        test.done()
      else
        configuration = createConfiguration POW_DOMAINS: "powtest,powdev"
        dnsServer = new DnsServer configuration
        address = "0.0.0.0"
        port = 20561

        dnsServer.listen port, ->
          resolve = (domain, callback) ->
            cmd = "dig -p #{port} @#{address} #{domain} +noall +answer +comments"
            exec cmd, (err, stdout, stderr) ->
              status = stdout.match(/status: (.*?),/)?[1]
              answer = stdout.match(/IN\tA\t([\d.]+)/)?[1]
              callback err, status, answer

          testResolves = (host, expectedStatus, expectedAnswer) ->
            (callback) -> resolve host, (err, status, answer) ->
              test.ifError err
              test.same [expectedStatus, expectedAnswer], [status, answer]
              callback()

          async.parallel [
            testResolves "hello.powtest", "NOERROR", "127.0.0.1"
            testResolves "hello.powdev",  "NOERROR", "127.0.0.1"
            testResolves "a.b.c.powtest", "NOERROR", "127.0.0.1"
            testResolves "powtest.",      "NOERROR", "127.0.0.1"
            testResolves "powdev.",       "NOERROR", "127.0.0.1"
            testResolves "foo.",          "NXDOMAIN"
          ], ->
            dnsServer.close()
            test.done()
