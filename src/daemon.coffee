# A `Daemon` is the root object in a Pow process. It's responsible for
# starting and stopping an `HttpServer` and a `DnsServer` in tandem.

{EventEmitter} = require "events"
HttpServer     = require "./http_server"
DnsServer      = require "./dns_server"
fs             = require "fs"
path           = require "path"

module.exports = class Daemon extends EventEmitter
  # Create a new `Daemon` with the given `Configuration` instance.
  constructor: (@configuration) ->
    # `HttpServer` and `DnsServer` instances are created accordingly.
    @httpServer = new HttpServer @configuration
    @dnsServer  = new DnsServer @configuration
    # The daemon stops in response to `SIGINT`, `SIGTERM` and
    # `SIGQUIT` signals.
    process.on "SIGINT",  @stop
    process.on "SIGTERM", @stop
    process.on "SIGQUIT", @stop

    # Watch for changes to the host root directory once the daemon has
    # started. When the directory changes and the `restart.txt` file
    # is present, remove it and emit a `restart` event.
    hostRoot = @configuration.hostRoot
    @restartFilename = path.join hostRoot, "restart.txt"
    @on "start", => @watcher = fs.watch hostRoot, persistent: false, @hostRootChanged
    @on "stop", => @watcher?.close()

  hostRootChanged: =>
    fs.exists @restartFilename, (exists) =>
      @restart() if exists

  # Remove the `~/.pow/restart.txt` file, if present, and emit a
  # `restart` event. The `pow` command observes this event and
  # terminates the process in response, causing Launch Services to
  # restart the server.
  restart: ->
    fs.unlink @restartFilename, (err) =>
      @emit "restart" unless err

  # Start the daemon if it's stopped. The process goes like this:
  #
  # * First, start the HTTP server. If the HTTP server can't boot,
  #   emit an `error` event and abort.
  # * Next, start the DNS server. If the DNS server can't boot, stop
  #   the HTTP server, emit an `error` event and abort.
  # * If both servers start up successfully, emit a `start` event and
  #   mark the daemon as started.
  start: ->
    return if @starting or @started
    @starting = true

    startServer = (server, port, callback) -> process.nextTick ->
      try
        server.on 'error', callback

        server.once 'listening', ->
          server.removeListener 'error', callback
          callback()

        server.listen port

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
      @emit "error", err

    {httpPort, dnsPort} = @configuration
    startServer @httpServer, httpPort, (err) =>
      if err then flunk err
      else startServer @dnsServer, dnsPort, (err) =>
        if err then flunk err
        else pass()

  # Stop the daemon if it's started. This means calling `close` on
  # both servers in succession, beginning with the HTTP server, and
  # waiting for the servers to notify us that they're done. The daemon
  # emits a `stop` event when this process is complete.
  stop: =>
    return if @stopping or !@started
    @stopping = true

    stopServer = (server, callback) -> process.nextTick ->
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
