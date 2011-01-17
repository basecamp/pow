fs   = require "fs"
nack = require "nack"

{join, dirname} = require "path"

sourceScriptEnv = (script, callback) ->
  command = """
    source #{script} > /dev/null;
    #{process.execPath} -e 'JSON.stringify(process.env)'
  """
  exec command, cwd: dirname(script), (err, stdout) ->
    return callback err if err
    try
      callback null, JSON.parse stdout
    catch exception
      callback exception

getEnvForRoot = (root, callback) ->
  path = join root, ".powrc"
  fs.stat path, (err) ->
    if err
      callback null, {}
    else
      sourceScriptEnv path, callback

module.exports = class RackHandler
  constructor: (@configuration, @root, callback) ->
    @readyCallbacks = []
    getEnvForRoot @root, (err, @env) =>
      if err
        callback? err
      else
        @app = nack.createServer join(@root, "config.ru"), @env
        callback null, @
        readyCallback() for readyCallback in @readyCallbacks
        @readyCallbacks = []

    # TODO
    # sys.pump app.pool.stdout, process.stdout
    # sys.pump app.pool.stderr, process.stdout

  ready: (callback) ->
    if @app
      callback()
    else
      @readyCallbacks.push callback

  handle: (req, res, next, callback) ->
    @ready => @restartIfNecessary =>
      req.proxyMetaVariables =
        SERVER_PORT: @configuration.dstPort.toString()
      try
        @app.handle req, res, next
      finally
        callback()

  quit: (callback) ->
    if @app
      @app.pool.once "exit", callback if callback
      @app.pool.quit()
    else
      callback?()

  restartIfNecessary: (callback) ->
    fs.unlink join(@root, "tmp/restart.txt"), (err) =>
      if err
        callback()
      else
        @quit callback
