# Pow's `DnsServer` is designed to respond to DNS `A` queries with
# `127.0.0.1` for all subdomains of the specified top-level domain.
# When used in conjunction with Mac OS X's [/etc/resolver
# system](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/resolver.5.html),
# there's no configuration needed to add and remove host names for
# local web development.

dnsserver = require "dnsserver"

NS_T_A  = 1
NS_C_IN = 1
NS_RCODE_NXDOMAIN = 3

module.exports = class DnsServer extends dnsserver.Server
  # Create a `DnsServer` with the given `Configuration` instance. The
  # server installs a single event handler for responding to DNS
  # queries.
  constructor: (@configuration) ->
    super
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
    pattern = @configuration.dnsDomainPattern

    q = req.question ? {}

    if q.type is NS_T_A and q.class is NS_C_IN and pattern.test q.name
      res.addRR q.name, NS_T_A, NS_C_IN, 600, "127.0.0.1"
    else
      res.header.rcode = NS_RCODE_NXDOMAIN

    res.send()
