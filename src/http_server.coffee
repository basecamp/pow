# Where the magic happens.
#
# Pow's `HttpServer` runs as your user and listens on a high port
# (20559 by default) for HTTP requests. (An `ipfw` rule forwards
# incoming requests on port 80 to your Pow instance.) Requests work
# their way through a middleware stack and are served to your browser
# as static assets, Rack requests, or error pages.

fs              = require "fs"
sys             = require "sys"
connect         = require "connect"
PowApplication  = require "./pow_application"
RackApplication = require "./rack_application"

{pause} = require "./util"
{dirname, join, exists} = require "path"

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
      o @annotateRequest
      o @handlePowRequest
      o @findApplicationRoot
      o @handleStaticRequest
      o @findRackApplication
      o @handleApplicationRequest
      x @handleApplicationException
    ]

    @staticHandlers = {}
    @rackApplications = {}
    @powApplication = new PowApplication @configuration, this

    @accessLog = @configuration.getLogger "access"
    @debugLog = @configuration.getLogger "debug"

    @on "close", =>
      for root, application of @rackApplications
        application.quit()

  # The first middleware in the stack logs each incoming request's
  # source address, method, hostname, and path to the access log
  # (`~/Library/Logs/Pow/access.log` by default).
  logRequest: (req, res, next) =>
    @accessLog.info "[#{req.socket.remoteAddress}] #{req.method} #{req.headers.host} #{req.url}"
    next()

  # Annotate the request object with a `pow` property whose value is
  # an object that will hold the request's normalized hostname, root
  # path, and application, if any. (Only the `pow.host` property is
  # set here.)
  annotateRequest: (req, res, next) =>
    host = req.headers.host?.replace /:.*/, ""

    for domain in @configuration.domains
      if domain is host?.slice -domain.length
        hostWithoutDomain = host.slice 0, -domain.length - 1

    req.pow = {host, hostWithoutDomain}
    @debugLog.debug "url = #{req.url}, req.pow = #{JSON.stringify req.pow}"
    next()

  handlePowRequest: (req, res, next) =>
    if req.pow.hostWithoutDomain is "pow"
      @powApplication.handle req, res, next
      @debugLog.debug "sent request to @powApplication"
    else
      next()

  # After the request has been annotated, attempt to match its
  # hostname to a Rack application using the server's
  # configuration. If an application is found, annotate the request
  # object with the application's root path so we can use it further
  # down the stack. If no application is found, render an error page
  # indicating that the hostname is not yet configured.
  findApplicationRoot: (req, res, next) =>
    resume = pause req

    @configuration.findApplicationRootForHost req.pow.host, (err, domain, root) =>
      if err
        next err
        resume()
      else
        if req.pow.root = root
          req.pow.domain = domain
          req.pow.resume = resume
          next()
        else
          @handleNonexistentDomain req, res, next
          resume()

  # If this is a `GET` or `HEAD` request matching a file in the
  # application's `public/` directory, serve the file directly.
  handleStaticRequest: (req, res, next) =>
    unless req.method in ["GET", "HEAD"]
      return next()

    unless root = req.pow.root
      return next()

    handler = @staticHandlers[root] ?= connect.static join(root, "public")
    handler req, res, ->
      next()
      req.pow.resume()

  # Check to see if the application root contains a `config.ru`
  # file. If it does, find the existing `RackApplication` instance for
  # the root, or create and cache a new one. Then annotate the request
  # object with the application so it can be handled by
  # `handleApplicationRequest`.
  findRackApplication: (req, res, next) =>
    return next() unless root = req.pow.root

    exists join(root, "config.ru"), (rackConfigExists) =>
      if rackConfigExists
        req.pow.application = @rackApplications[root] ?=
          new RackApplication @configuration, root

      # If `config.ru` isn't present but there's an existing
      # `RackApplication` for the root, terminate the application and
      # remove it from the cache.
      else if application = @rackApplications[root]
        delete @rackApplications[root]
        application.quit()

      next()

  # If the request object is annotated with an application, pass the
  # request off to the application's `handle` method.
  handleApplicationRequest: (req, res, next) =>
    if application = req.pow.application
      application.handle req, res, next, req.pow.resume
    else
      next()

  # Render `templateName` to the given `res` response with the given
  # `status` code and `context` values.
  render: (res, status, templateName, context = {}) ->
    template = require "./templates/http_server/#{templateName}.html"
    res.writeHead status, "Content-Type": "text/html; charset=utf8", "X-Pow-Template": templateName
    res.end template context

  # If there's an exception thrown while handling a request, show a
  # nicely formatted error page along with the full backtrace.
  handleApplicationException: (err, req, res, next) =>
    return next() unless root = req.pow.root
    @render res, 500, "application_exception", {err, root}

  # Show a friendly message when accessing a hostname that hasn't been
  # set up with Pow yet.
  handleNonexistentDomain: (req, res, next) =>
    @render res, 503, "nonexistent_domain", path: req.pow.hostWithoutDomain
