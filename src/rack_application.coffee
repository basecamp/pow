# The `RackApplication` class is responsible for managing a
# [Nack](http://josh.github.com/nack/) server for a given Rack
# application. Incoming HTTP requests are dispatched to
# `RackApplication` instances by an `HttpServer`, where they are
# subsequently handled by a pool of Nack worker processes. By default,
# Pow tells Nack to use a maximum of two worker processes per
# application, but this can be overridden with the configuration's
# `workers` option.
#
# Before creating the Nack server, Pow executes the `.powrc` and
# `.powenv` scripts if they're present in the application root,
# captures their environment variables, and passes them along to the
# Nack worker processes. This lets you modify your `PATH` to use a
# different Ruby version, for example.
#
# Nack workers remain running until they're killed, restarted (by
# touching the `tmp/restart.txt` file in the application root), or
# until the application has not served requests for the length of time
# specified in the configuration's `timeout` option (15 minutes by
# default).

async = require "async"
path  = require "path"
fs    = require "fs"
nack  = require "nack"

{bufferLines, pause, sourceScriptEnv} = require "./util"
{join, basename} = require "path"

module.exports = class RackApplication
  constructor: (@configuration, @root) ->
    @logger = @configuration.getLogger join "apps", basename @root
    @readyCallbacks = []

  # Collect environment variables from `.powrc` and `.powenv`, in that
  # order, if present. The idea is that `.powrc` files can be checked
  # into a source code repository for global configuration, leaving
  # `.powenv` free for any necessary local overrides.

  envFilenames = [".powrc", ".powenv"]

  getEnvForRoot = (root, callback) ->
    async.reduce envFilenames, {}, (env, filename, callback) ->
      path.exists script = join(root, filename), (exists) ->
        if exists
          sourceScriptEnv script, env, callback
        else
          callback null, env
    , callback

  initialize: ->
    return if @state
    @state = "initializing"

    createServer = =>
      @server = nack.createServer join(@root, "config.ru"),
        env:  @env
        size: @configuration.workers
        idle: @configuration.timeout

    processReadyCallbacks = (err) =>
      readyCallback err for readyCallback in @readyCallbacks
      @readyCallbacks = []

    installLogHandlers = =>
      bufferLines @server.pool.stdout, (line) => @logger.info line
      bufferLines @server.pool.stderr, (line) => @logger.warning line

      @server.pool.on "worker:spawn", (process) =>
        @logger.debug "nack worker #{process.child.pid} spawned"

      @server.pool.on "worker:exit", (process) =>
        @logger.debug "nack worker exited"

    getEnvForRoot @root, (err, @env) =>
      if err
        @state = null
        @logger.error err.message
        @logger.error "stdout: #{err.stdout}"
        @logger.error "stderr: #{err.stderr}"
        processReadyCallbacks err
      else
        createServer()
        installLogHandlers()
        @state = "ready"
        processReadyCallbacks()

  ready: (callback) ->
    if @state is "ready"
      callback()
    else
      @readyCallbacks.push callback
      @initialize()

  handle: (req, res, next, callback) ->
    resume = pause req
    @ready (err) =>
      return next err if err
      @restartIfNecessary =>
        req.proxyMetaVariables =
          SERVER_PORT: @configuration.dstPort.toString()
        try
          @server.handle req, res, next
        finally
          resume()
          callback?()

  quit: (callback) ->
    if @server
      @server.pool.once "exit", callback if callback
      @server.pool.quit()
    else
      callback?()

  restartIfNecessary: (callback) ->
    fs.stat join(@root, "tmp/restart.txt"), (err, stats) =>
      if not err and stats?.mtime isnt @mtime
        @quit callback
      else
        callback()
      @mtime = stats?.mtime
