{EventEmitter} = require "events"
HttpServer     = require "./http_server"
DnsServer      = require "./dns_server"

module.exports = class Daemon extends EventEmitter
  constructor: (@configuration) ->
    @httpServer = new HttpServer @configuration
    @dnsServer  = new DnsServer @configuration
    process.on "SIGINT",  @stop
    process.on "SIGTERM", @stop
    process.on "SIGQUIT", @stop

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
      @emit "start"

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

  stop: =>
    return if @stopping or !@started
    @stopping = true

    stopServer = (server, callback) ->
      try
        close = ->
          server.removeListener "close", close
          callback null
        server.on "close", close
        server.close()
      catch err
        callback err

    stopServer @httpServer, =>
      stopServer @dnsServer, =>
        @stopping = false
        @started  = false
        @emit "stop"
