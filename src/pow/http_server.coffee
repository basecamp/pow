fs      = require "fs"
{join}  = require "path"
sys     = require "sys"
connect = require "connect"
nack    = require "nack"

module.exports = class HttpServer extends connect.Server
  constructor: (@configuration) ->
    @handlers = {}
    super [@handleRequest, connect.errorHandler showStack: true]
    @on "close", @closeApplications

  getHandlerForHost: (host, callback) ->
    @configuration.findApplicationRootForHost host, (err, root) =>
      return callback err if err
      callback null, @getHandlerForRoot root

  getHandlerForRoot: (root) ->
    @handlers[root] ||=
      root: root
      app:  @createApplication(join(root, "config.ru"))

  createApplication: (configurationPath) ->
    app = nack.createServer(configurationPath, idle: @configuration.timeout)
    sys.pump app.pool.stdout, process.stdout
    sys.pump app.pool.stderr, process.stdout
    app

  handleRequest: (req, res, next) =>
    pause = connect.utils.pause req
    host  = req.headers.host.replace /:.*/, ""
    @getHandlerForHost host, (err, handler) =>
      @restartIfNecessary handler, =>
        pause.end()
        return next err if err
        req.proxyMetaVariables =
          SERVER_PORT: @configuration.dstPort.toString()
        handler.app.handle req, res, next
        pause.resume()

  closeApplications: =>
    for root, {app} of @handlers
      app.pool.quit()

  restartIfNecessary: ({root, app}, callback) ->
    fs.unlink join(root, "tmp/restart.txt"), (err) ->
      if err
        callback()
      else
        app.pool.onNext "exit", callback
        app.pool.quit()
