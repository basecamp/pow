fs      = require "fs"
sys     = require "sys"
{exec}  = require "child_process"
{join}  = require "path"
connect = require "connect"
nack    = require "nack"
{pause} = require "nack/util"

getHost = (req) ->
  req.headers.host.replace /:.*/, ""

escapeHTML = (string) ->
  string.toString()
    .replace(/&/g,  "&amp;")
    .replace(/</g,  "&lt;")
    .replace(/>/g,  "&gt;")
    .replace(/\"/g, "&quot;")

sourceScriptEnv = (script, callback) ->
  exec "source #{script}; #{process.argv[0]} -e 'JSON.stringify(process.env)'", (err, stdout) ->
    return callback err if err
    try
      callback null, JSON.parse stdout
    catch exception
      callback exception

# Connect depends on Function.prototype.length to determine
# whether a given middleware is an error handler. These wrappers
# provide compatibility with bound instance methods.
o = (fn) -> (req, res, next)      -> fn req, res, next
x = (fn) -> (err, req, res, next) -> fn err, req, res, next

module.exports = class HttpServer extends connect.Server
  constructor: (@configuration) ->
    super [
      o @handleRequest
      x @handleApplicationException
      o @handleNonexistentDomain
    ]
    @handlers = {}
    @on "close", @closeApplications

  getHandlerForHost: (host, callback) ->
    @configuration.findApplicationRootForHost host, (err, root) =>
      return callback err if err
      @getHandlerForRoot root, callback

  getHandlerForRoot: (root, callback) ->
    return unless root

    @getEnvForRoot root, (err, env) =>
      handler = @handlers[root] ||=
        root: root
        app:  @createApplication(join(root, "config.ru"), env)
        env:  env
      callback null, handler

  getEnvForRoot: (root, callback) ->
    path = join root, ".powrc"
    fs.stat path, (err) ->
      if err
        callback null, {}
      else
        sourceScriptEnv path, callback

  createApplication: (configurationPath, env) ->
    app = nack.createServer configurationPath,
      idle: @configuration.timeout
      env: env
    sys.pump app.pool.stdout, process.stdout
    sys.pump app.pool.stderr, process.stdout
    app

  closeApplications: =>
    for root, {app} of @handlers
      app.pool.quit()

  handleRequest: (req, res, next) =>
    host    = getHost req
    resume  = pause req
    req.pow = {host}

    @getHandlerForHost host, (err, handler) =>
      req.pow.handler = handler

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

  restartIfNecessary: ({root, app}, callback) ->
    fs.unlink join(root, "tmp/restart.txt"), (err) ->
      if err
        callback()
      else
        app.pool.once "exit", callback
        app.pool.quit()

  handleApplicationException: (err, req, res, next) =>
    return next() unless req.pow?.handler

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
        <h2><code>#{escapeHTML req.pow.handler.root}</code> raised an exception during boot.</h2>
        <pre><strong>#{escapeHTML err}</strong>#{escapeHTML "\n" + err.stack}</pre>
      </body>
      </html>
    """

  handleNonexistentDomain: (req, res, next) =>
    return next() unless req.pow
    host = req.pow.host
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
        <h1>This domain isn&rsquo;t set up yet.</h1>
        <h2>Symlink your application to <code>#{escapeHTML path}</code> first.</h2>
      </body>
      </html>
    """
