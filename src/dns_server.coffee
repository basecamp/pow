# Pow's `DnsServer` is designed to respond to DNS `A` queries with
# `127.0.0.1` for all subdomains of the specified top-level domain.
# When used in conjunction with Mac OS X's [/etc/resolver
# system](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/resolver.5.html),
# there's no configuration needed to add and remove host names for
# local web development.

ndns = require "ndns"

module.exports = class DnsServer extends ndns.Server
  # Create a `DnsServer` with the given `Configuration` instance. The
  # server installs a single event handler for responding to DNS
  # queries.
  constructor: (@configuration) ->
    super "udp4"
    @pattern = compilePattern @configuration.domains
    @on "request", @handleRequest

  # The `listen` method is just a wrapper around `bind` that makes
  # `DnsServer` quack like a `HttpServer` (for initialization, at
  # least).
  listen: (port, callback) ->
    @bind port
    callback?()

  # Each incoming DNS request ends up here. If it's an `A` query
  # and the domain name matches the top-level domain specified in our
  # configuration, we respond with `127.0.0.1`. Otherwise, we respond
  # with `NXDOMAIN`.
  handleRequest: (req, res) =>
    res.header = req.header
    res.question = req.question
    res.header.aa = 1
    res.header.qr = 1

    q = req.question[0] ? {}

    if q.type is ndns.ns_t.a and q.class is ndns.ns_c.in and @pattern.test q.name
      res.addRR ndns.ns_s.an, q.name, ndns.ns_t.a, ndns.ns_c.in, 600, "127.0.0.1"
    else
      res.header.rcode = ndns.ns_rcode.nxdomain

    res.send()

# Helper function for compiling a top-level domains into a regular
# expression for matching purposes.
compilePattern = (domains) ->
  /// (^|\.) (#{domains.join("|")}) \.? $ ///
