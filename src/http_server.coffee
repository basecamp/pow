# Where the magic happens.
#
# Pow's `HttpServer` runs as your user and listens on a high port
# (20559 by default) for HTTP requests. (An `ipfw` rule forwards
# incoming requests on port 80 to your Pow instance.) Requests work
# their way through a middleware stack and are served to your browser
# as static assets, Rack requests, or error pages.

fs                  = require "fs"
sys                 = require "sys"
connect             = require "connect"
RackApplication     = require "./rack_application"

{dirname, join}     = require "path"
{pause, escapeHTML} = require "./util"

# `HttpServer` is a subclass of
# [Connect](http://senchalabs.github.com/connect/)'s `HTTPServer` with
# a custom set of middleware and a reference to a Pow `Configuration`.
module.exports = class HttpServer extends connect.HTTPServer

  # Connect depends on Function.prototype.length to determine
  # whether a given middleware is an error handler. These wrappers
  # provide compatibility with bound instance methods.
  o = (fn) -> (req, res, next)      -> fn req, res, next
  x = (fn) -> (err, req, res, next) -> fn err, req, res, next

  # Create an HTTP server for the given configuration. This sets up
  # the middleware stack, gets a `Logger` instace for the global
  # access log, and registers a handler to close any running
  # applications when the server shuts down.
  constructor: (@configuration) ->
    super [
      o @logRequest
      o @findApplicationRoot
      o @handleStaticRequest
      o @handleRackRequest
      x @handleApplicationException
    ]

    @staticHandlers = {}
    @rackApplications = {}

    @accessLog = @configuration.getLogger "access"

    @on "close", =>
      for root, application of @rackApplications
        application.quit()

  # The first middleware in the stack logs each incoming request's
  # source address, method, hostname, and path to the access log
  # (`~/Library/Logs/Pow/access.log` by default).
  logRequest: (req, res, next) =>
    @accessLog.info "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
    next()

  # After the request has been logged, attempt to match its hostname
  # to a Rack application using the server's configuration. If an
  # application is found, annotate the request object with the
  # application's root path so we can use it further down the
  # stack. If no application is found, render an error page indicating
  # that the hostname is not yet configured.
  findApplicationRoot: (req, res, next) =>
    host   = req.headers.host.replace /:.*/, ""
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

  # If this is a `GET` or `HEAD` request matching a file in the
  # application's `public/` directory, serve the file directly.
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

  # Otherwise, pass the request to the `RackApplication` instance for
  # the matched application.
  handleRackRequest: (req, res, next) =>
    return next() unless req.pow

    root = req.pow.root
    application = @rackApplications[root] ?= new RackApplication @configuration, root
    application.handle req, res, next, req.pow.resume

  # If there's an exception thrown while handling a request, show a
  # nicely formatted error page along with the full backtrace.
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

  # Show a friendly message when accessing a hostname that hasn't been
  # set up with Pow yet.
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
