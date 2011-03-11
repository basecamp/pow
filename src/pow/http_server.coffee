fs          = require "fs"
sys         = require "sys"
connect     = require "connect"
{pause}     = require "./util"
RackHandler = require "./rack_handler"

{dirname, join}  = require "path"

getHost = (req) ->
  req.headers.host.replace /:.*/, ""

escapeHTML = (string) ->
  string.toString()
    .replace(/&/g,  "&amp;")
    .replace(/</g,  "&lt;")
    .replace(/>/g,  "&gt;")
    .replace(/\"/g, "&quot;")

# Connect depends on Function.prototype.length to determine
# whether a given middleware is an error handler. These wrappers
# provide compatibility with bound instance methods.
o = (fn) -> (req, res, next)      -> fn req, res, next
x = (fn) -> (err, req, res, next) -> fn err, req, res, next

module.exports = class HttpServer extends connect.HTTPServer
  constructor: (@configuration) ->
    super [
      o @logRequest
      o @findApplicationRoot
      o @handleStaticRequest
      o @handleRackRequest
      x @handleApplicationException
    ]
    @staticHandlers = {}
    @rackHandlers   = {}
    @accessLog = @configuration.getLogger "access"
    @on "close", @closeApplications

  closeApplications: =>
    for root, handler of @rackHandlers
      handler.quit()

  logRequest: (req, res, next) =>
    @accessLog.info "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
    next()

  findApplicationRoot: (req, res, next) =>
    host   = getHost req
    resume = pause req

    @configuration.findApplicationRootForHost host, (err, root) =>
      if err
        next err
        resume()
      else
        req.pow = {host, root}
        if not root
          @handleNonexistentDomain req, res, next
          resume()
        else
          req.pow.resume = resume
          next()

  handleStaticRequest: (req, res, next) =>
    unless req.method in ["GET", "HEAD"]
      return next()

    unless req.pow
      return next()

    root = req.pow.root
    handler = @staticHandlers[root] ?= connect.static join(root, "public")
    handler req, res, ->
      next()
      req.pow.resume()

  handleRackRequest: (req, res, next) =>
    return next() unless req.pow

    root = req.pow.root
    handler = @rackHandlers[root] ?= new RackHandler @configuration, root
    handler.handle req, res, next, req.pow.resume

  handleApplicationException: (err, req, res, next) =>
    return next() unless req.pow

    res.writeHead 500, "Content-Type": "text/html; charset=utf8", "X-Pow-Handler": "ApplicationException"
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
        <h2><code>#{escapeHTML req.pow.root}</code> raised an exception during boot.</h2>
        <pre><strong>#{escapeHTML err}</strong>#{escapeHTML "\n" + err.stack}</pre>
      </body>
      </html>
    """

  handleNonexistentDomain: (req, res, next) =>
    return next() unless req.pow
    host = req.pow.host
    name = host.slice 0, host.length - @configuration.domain.length - 1
    path = join @configuration.root, name

    res.writeHead 503, "Content-Type": "text/html; charset=utf8", "X-Pow-Handler": "NonexistentDomain"
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
