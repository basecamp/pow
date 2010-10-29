connect = require 'connect'
fs      = require 'fs'
nack    = require 'nack'
path    = require 'path'
sys     = require 'sys'

idle = 1000 * 60 * 15

process.env['RACK_ENV'] = 'development'

exports.Server = class Server
  constructor: (@configuration) ->
    @applications = {}
    @server = connect.createServer connect.logger(),
      @onRequest.bind(@),
      connect.errorHandler dumpExceptions: true

  listen: (port) ->
    @server.listen port

    process.on 'SIGINT',  () => @close()
    process.on 'SIGTERM', () => @close()
    process.on 'SIGQUIT', () => @close()

  close: ->
    return if @closing
    @closing = true

    for config, app of @applications
      app.close()

    @server.close()

    process.nextTick () ->
      process.exit 0

  createApplicationPool: (config) ->
    root = path.dirname config
    app  = nack.createServer config, idle: idle

    # TODO: Pump this to a file
    sys.pump app.pool.stdout, process.stdout
    sys.pump app.pool.stderr, process.stdout

    fs.watchFile "#{root}/tmp/restart.txt", (curr, prev) ->
      app.pool.quit()

    app

  applicationForConfig: (config) ->
    if config
      @applications[config] ?= @createApplicationPool config

  onRequest: (req, res, next) ->
    pause = connect.utils.pause req
    host = req.headers.host.replace /:.*/, ""
    @configuration.findPathForHost host, (path) =>
      pause.end()
      if app = @applicationForConfig path
        app.handle req, res, next
        pause.resume()
      else
        next new Error "unknown host #{req.headers.host}"
