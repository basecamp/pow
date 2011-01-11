fs      = require "fs"
{join}  = require "path"
sys     = require "sys"
connect = require "connect"
nack    = require "nack"
{pause} = require "nack/util"

getHost = (req) ->
  req.headers.host.replace /:.*/, ""

# Connect depends on Function.prototype.length to determine
# whether a given middleware is an error handler. These wrappers
# provide compatibility with bound instance methods.
o = (fn) -> (req, res, next)      -> fn req, res, next
x = (fn) -> (err, req, res, next) -> fn err, req, res, next

module.exports = class HttpServer extends connect.Server
  constructor: (@configuration) ->
    super [
      o @handleRequest
      x @handleException
      o @handleNonexistentDomain
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
    host   = getHost req
    resume = pause req
    @getHandlerForHost host, (err, handler) =>
      if handler and not err
        @restartIfNecessary handler, =>
          req.proxyMetaVariables =
            SERVER_PORT: @configuration.dstPort.toString()
          try
            handler.app.handle req, res, next
          finally
            resume()
      else
        next err
        resume()

  closeApplications: =>
    for root, {app} of @handlers
      app.pool.quit()

  restartIfNecessary: ({root, app}, callback) ->
    fs.unlink join(root, "tmp/restart.txt"), (err) ->
      if err
        callback()
      else
        app.pool.once "exit", callback
        app.pool.quit()

  handleException: (err, req, res, next) =>
    host = getHost req
    name = host.slice 0, host.length - @configuration.domain.length - 1
    path = join @configuration.root, name

    res.writeHead 500, "Content-Type", "text/html; charset=utf8"
    res.end """
      <!doctype html>
      <html>
      <head>
        <title>Pow: Error Starting Application</title>
        <style>
          body {
            margin: 0;
            padding: 0;
          }
          h1, h2, pre {
            margin: 0;
            padding: 15px 30px;
          }
          h1, h2 {
            font-family: Helvetica, sans-serif;
          }
          h1 {
            font-size: 36px;
            background: #eeedea;
            color: #c00;
            border-bottom: 1px solid #999090;
          }
          h2 {
            font-size: 18px;
            font-weight: normal;
          }
        </style>
      </head>
      <body>
        <h1>Pow can&rsquo;t start your application.</h1>
        <h2><code>#{path}</code> raised an exception during boot.</h2>
        <pre>#{err.stack}</pre>
      </body>
      </html>
    """

  handleNonexistentDomain: (req, res, next) =>
    host = getHost req
    name = host.slice 0, host.length - @configuration.domain.length - 1
    path = join @configuration.root, name

    res.writeHead 503, "Content-Type": "text/html; charset=utf8"
    res.end """
      <!doctype html>
      <html>
      <head>
        <title>Pow: No Such Application</title>
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
