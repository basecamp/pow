async = require "async"
path  = require "path"
fs    = require "fs"
nack  = require "nack"

{bufferLines, pause} = require "./util"
{join, dirname, basename} = require "path"
{exec} = require "child_process"

sourceScriptEnv = (script, env, callback) ->
  command = """
    source '#{script}' > /dev/null;
    '#{process.execPath}' -e 'JSON.stringify(process.env)'
  """
  exec command, cwd: dirname(script), env: env, (err, stdout, stderr) ->
    if err
      err.message = "'#{script}' failed to load"
      err.stdout = stdout
      err.stderr = stderr
      callback err

    try
      callback null, JSON.parse stdout
    catch exception
      callback exception

envFilenames = [".powrc", ".powenv"]

getEnvForRoot = (root, callback) ->
  async.reduce envFilenames, {}, (env, filename, callback) ->
    path.exists script = join(root, filename), (exists) ->
      if exists
        sourceScriptEnv script, env, callback
      else
        callback null, env
  , callback

module.exports = class RackApplication
  constructor: (@configuration, @root) ->
    @logger = @configuration.getLogger join "apps", basename @root
    @readyCallbacks = []

  initialize: ->
    return if @state
    @state = "initializing"

    createServer = =>
      @server = nack.createServer join(@root, "config.ru"),
        env:  @env
        size: @configuration.workers

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
