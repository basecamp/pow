# Pow's `mDnsServer` is designed to respond to mDNS `A` queries with
# `127.0.0.1` for all subdomains of the specified top-level domain.
# We can't use mDNSResponder as it will not register addition `A`
# records. Stricly, the mDNS draft recommends 

# XXX: We SHOULD listen on each interface seperately so we can
# respond with the appropriate IP to the multicast address over
# that interface. For now, it's hacked a little and will look up
# the address we'd use to contact the sender via `route` and
# `ifconfig`.

ndns   = require "ndns"
util   = require "util"
{exec} = require "child_process"

module.exports = class mDnsServer extends ndns.Server
  # Create a `mDnsServer` with the given `Configuration` instance. The
  # server installs a single event handler for responding to mDNS
  # queries.
  constructor: (@configuration) ->
    super "udp4"
    @logger = @configuration.getLogger 'mdns'
    @on "request", @handleRequest

  # `lookupHostname` looks up our hostname that should be
  # registered as an mDNS address. Can be overridden by
  # `@configuration.mDnsHost`.
  lookupHostname: (callback) ->
    if @configuration.mDnsHost != null
      callback? null, @configuration.mDnsHost
    else
      exec "scutil --get LocalHostName", (error, stdout, stderr) =>
        if error
          @logger.warning "Couldn't query local hostname. scutil said: #{util.inspect stdout} and #{util.inspect stderr}"
          callback? true
        else
          hostname = stdout.trim()
          callback? null, hostname
  
  lookupAddressToContactInterfacePattern = /interface:\s+(\S+)/i
  lookupAddressToContactAddressPattern = /inet\s+(\d+\.\d+\.\d+\.\d+)/i
  lookupAddressToContact: (address, callback) ->
    # XXX: We can't actually do this... it needs to be scoped by interface and things.
    # ("default" used to be "#{address}")
    # Only one address can be published per interface due to multicasting.
    # Node also currently has no nice way to inspect interfaces, etc.
    exec "route get default", (error, stdout, stderr) =>
      interface = stdout.match(lookupAddressToContactInterfacePattern)?[1]
      if error or not interface
        @logger.warning "Couldn't query route for #{address}. route said: #{util.inspect stdout} and #{util.inspect stderr}"
        callback? true, null
      else
        exec "ifconfig #{interface}", (error, stdout, stderr) =>
          myAddress = stdout.match(lookupAddressToContactAddressPattern)?[1]
          if error or not myAddress
            @logger.warning "Couldn't query address for #{interface}. ifconfig said: #{util.inspect stdout} and #{util.inspect stderr}"
            callback? true, null
          else
            callback? null, myAddress

  # The `listen` method is just a wrapper around `bind` that makes
  # `mDnsServer` quack like a `HttpServer` (for initialization, at
  # least).
  listen: (port, callback) ->
    @lookupHostname (error, hostname) =>
      # listen to queries for A records matching *.hostname.local
      @pattern = /// (^|\.) #{hostname} \. #{@configuration.mDnsDomain} \.? ///i
      
      @logger.debug "multicasting on #{@configuration.mDnsAddress}"
      @setTTL 255
      @setMulticastTTL 255
      @setMulticastLoopback true
      @addMembership @configuration.mDnsAddress
      
      @logger.debug "binding to port #{@configuration.mDnsPort}"
      @bind @configuration.mDnsPort
      
      mDnsHost = "#{hostname}.#{@configuration.mDnsDomain}".toLowerCase()
      @logger.debug "adding mDNS domain #{util.inspect mDnsHost} to configuration"
      @configuration.domains.push mDnsHost
      
      callback?()

  # Each incoming mDNS request ends up here. If it's an `A` query
  # and the domain name is a subdomain of our mDNS name, we respond
  # with find the IP used to route to the receiver. All other
  # requests are ignored.
  handleRequest: (req, res) =>
    q = req.question[0] ? {}

    if q.type is ndns.ns_t.a and q.class is ndns.ns_c.in and @pattern.test q.name
      res.header = req.header
      res.question = req.question
      res.header.aa = 1
      res.header.qr = 1
      
      @lookupAddressToContact req.rinfo.address, (error, myAddress) =>
        if error
          @logger.warning "couldn't find my address to talk to #{req.rinfo.address}"
        else
          res.addRR ndns.ns_s.an, q.name, ndns.ns_t.a, ndns.ns_c.in, 600, myAddress
          res.sendTo this, @configuration.mDnsPort, @configuration.mDnsAddress, (error) =>
            if error
              @logger.warning "couldn't send mdns response: #{util.inspect error}"
          
  # TODO: Hostname change monitoring
  
  # TODO: Goodbye messages
