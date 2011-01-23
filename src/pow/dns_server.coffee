ndns = require "ndns"

compilePattern = (domain) ->
  /// \. #{domain} \.? $ ///

module.exports = class DnsServer extends ndns.Server
  constructor: (@configuration) ->
    super "udp4"
    @pattern = compilePattern @configuration.domain
    @on "request", @handleRequest

  listen: (port, callback) ->
    @bind port
    callback?()

  handleRequest: (req, res) =>
    res.header = req.header
    res.question = req.question
    res.header.aa = 1
    res.header.qr = 1
    {typeName, className, name} = req.question[0] ? {}

    if typeName is "A" and className is "IN" and @pattern.test name
      res.header.ancount = 1
      res.addRR name, ndns.ns_t.a, ndns.ns_c.in, 600, "127.0.0.1"
    else
      res.header.ancount = 0
      res.header.rcode = ndns.ns_rcode.nxdomain

    res.send()
