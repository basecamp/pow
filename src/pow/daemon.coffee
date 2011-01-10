HttpServer = require "./http_server"
DnsServer  = require "./dns_server"

module.exports = class Daemon
  constructor: (@configuration) ->
    @httpServer = new HttpServer @configuration
    @dnsServer  = new DnsServer @configuration

  start: ->
    return if @starting or @started
    @starting = true

    startServer = (server, port, callback) ->
      try
        server.listen port, -> callback null
      catch err
        callback err

    pass = =>
      @starting = false
      @started = true

    flunk = (err) =>
      @starting = false
      try @httpServer.close()
      try @dnsServer.close()

    {httpPort, dnsPort} = @configuration
    startServer @httpServer, httpPort, (err) =>
      if err then flunk err
      else startServer @dnsServer, dnsPort, (err) =>
        if err then flunk err
        else pass()

  stop: ->
    return if @stopping or !@started
    @stopping = true

    stopServer = (server, callback) ->
      try
        server.on "close", -> callback null
        server.close()
      catch err
        callback err

    stopServer @httpServer, =>
      stopServer @dnsServer, =>
        @stopping = false
        @started  = false
