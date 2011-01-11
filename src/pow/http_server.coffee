fs      = require "fs"
{join}  = require "path"
sys     = require "sys"
connect = require "connect"
nack    = require "nack"

getHost = (req) ->
  req.headers.host.replace /:.*/, ""

module.exports = class HttpServer extends connect.Server
  constructor: (@configuration) ->
    super [
      @handleRequest
      connect.errorHandler showStack: true
      @handleNonexistentDomain
    ]
    @handlers = {}
    @on "close", @closeApplications

  getHandlerForHost: (host, callback) ->
    @configuration.findApplicationRootForHost host, (err, root) =>
      return callback err if err
      callback null, @getHandlerForRoot root

  getHandlerForRoot: (root) ->
    return unless root
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
    host  = getHost req
    @getHandlerForHost host, (err, handler) =>
      return next err unless handler
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

  handleNonexistentDomain: (req, res, next) =>
    host = getHost req
    name = host.slice 0, host.length - @configuration.domain.length - 1
    path = join @configuration.root, name

    res.writeHead 503, "Content-Type": "text/html; charset=utf8"
    res.end """
      <!doctype html>
      <html>
      <head>
        <style>
          body {
            margin: 0;
            padding: 0;
          }
          h1, h2 {
            margin: 0;
            padding: 15px 30px;
            font-family: Helvetica, sans-serif;
          }
          h1 {
            font-size: 36px;
            background: #eeedea;
            color: #000;
            border-bottom: 1px solid #999090;
          }
          h2 {
            font-size: 18px;
            font-weight: normal;
          }
        </style>
      </head>
      <body>
        <h1>This domain hasn&rsquo;t been set up yet.</h1>
        <h2>Symlink your application to <code>#{path}</code> first.</h2>
      </body>
      </html>
    """
