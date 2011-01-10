{join}  = require "path"
connect = require "connect"
nack    = require "nack"

module.exports = class HttpServer extends connect.Server
  constructor: (@configuration) ->
    @handlers = {}
    super [@handleRequest, connect.errorHandler dumpExceptions: true]

  getHandlerForHost: (host, callback) ->
    @configuration.findApplicationRootForHost host, (err, root) =>
      return callback err if err
      callback null, @getHandlerForRoot root

  getHandlerForRoot: (root) ->
    @handlers[root] ||= nack.createServer join(root, "config.ru"),
      idle: @configuration.timeout

  handleRequest: (req, res, next) =>
    pause = connect.utils.pause req
    host  = req.headers.host.replace /:.*/, ""
    @getHandlerForHost host, (err, handler) ->
      pause.end()
      return next err if err
      req.proxyMetaVariables = SERVER_PORT: '80'
      handler.handle req, res, next
      pause.resume()
