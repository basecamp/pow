ndns = require "ndns"

TEST_HOST = /\.test\.?$/

exports.NameServer = class NameServer
  constructor: ->
    @server = ndns.createServer "udp4"
    @server.on "request", @onRequest

  listen: (port) ->
    @server.bind port

  onRequest: (req, res) =>
    res.header = req.header
    res.question = req.question
    res.header.qr = 1
    res.header.ancount = 1
    res.header.aa = 1

    {typeName, className, name} = req.question[0] ? {}
    if typeName is "A" and className is "IN" and TEST_HOST.test name
      res.addRR name, ndns.ns_t.a, ndns.ns_c.in, 600, "127.0.0.1"

    res.send()

