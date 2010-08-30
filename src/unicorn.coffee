path           = require "path"
sys            = require "sys"
{spawn}        = require "child_process"
{EventEmitter} = require "events"
{LineBuffer}   = require "../vendor/linebuffer"
bundler        = require "./bundler"

bufferLinesFrom = (stream, encoding, callback) ->
  lineBuffer = new LineBuffer
  lineBuffer.setEncoding encoding
  stream.on "data", (data) ->
    lineBuffer.write data
  lineBuffer.on "data", callback

exports.UnicornProcess = class UnicornProcess extends EventEmitter
  constructor: (@filename) ->
    @path = path.dirname(@filename)
    super

  run: (options) ->
    unless @running
      @running = true
      @options = options || {}
      @cmd = "unicorn"
      @args = []

      path.exists path.join(@path, "Gemfile"), (exists) =>
        if exists
          bundler.hasGem name: "unicorn", cwd: @path, (hasGem) =>
            if hasGem
              @cmd = "bundle"
              @args = ["exec", "unicorn"]
            @spawn()
        else
          @spawn()

  kill: ->
    @process.kill() if @process

  spawn: ->
    unless @process
      @args.push "-p", @options.port || 0
      @args.push "-E", "development"
      @process = spawn @cmd, @args, cwd: @path

      bufferLinesFrom @process.stdout, "ascii", (line) =>
        console.log "[stdout] #{sys.inspect line}"
        @onStdoutLine line

      bufferLinesFrom @process.stderr, "ascii", (line) =>
        console.log "[stderr] #{sys.inspect line}"
        @onStderrLine line

      @process.on "exit", (exitCode) =>
        @onProcessExit exitCode

  onStdoutLine: (line) ->

  onStderrLine: (line) ->
    if @ready
      @lookForWorkerSpawnedLine line
      @lookForWorkerReadyLine line
    else if @port
      @lookForMasterReadyLine line
    else
      @lookForListenLine line

  onProcessExit: (exitCode) ->
    @emit "exit", exitCode
    @options = @cmd = @args = @process = @port = @ready = false

  lookForListenLine: (string) ->
    if match = string.match /listening on addr=[^:]+:(\d+) fd=\d+$/m
      @port = parseInt(match[1])

  lookForMasterReadyLine: (string) ->
    if match = string.match /master process ready$/m
      @ready = true
      @emit "ready", @port

  lookForWorkerSpawnedLine: (string) ->
    if match = string.match /worker=(\d+) spawned pid=(\d+)$/m
      @emit "workerSpawn", parseInt(match[1]), parseInt(match[2])

  lookForWorkerReadyLine: (string) ->
    if match = string.match /worker=(\d+) ready$/m
      @emit "workerReady", parseInt(match[1])
