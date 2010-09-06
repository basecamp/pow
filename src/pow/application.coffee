sys = require "sys"
{spawn} = require "child_process"
path = require "path"
{UnicornProcess} = require "../unicorn"

exports.Application = class Application
  constructor: (@path) ->
    @requests = []
    @lastAccess = new Date

  run: (exitCallback) ->
    unless @process
      @exitCallback = exitCallback
      @process = new UnicornProcess @path
      @process.run path.join(__dirname, "../../bin/pow_unicorn")

      @process.on "ready", (port) =>
        console.log "ready #{port}"
        @onReady port

      @process.on "workerSpawn", (id, pid) ->
        console.log "workerSpawn=#{id} #{pid}"

      @process.on "workerExit", (id) ->
        console.log "workerExit=#{id}"

      @process.on "exit", (exitCode) =>
        console.log "exit #{exitCode}"
        @onExit exitCode

  onReady: (port) ->
    @port = port
    @ready = true
    process.nextTick =>
      @drainQueue()

  onExit: (code) ->
    @exitCallback code
    @exitCallback = @process = @port = @ready = false

  drainQueue: ->
    console.log "drainQueue: @requests = #{sys.inspect @requests}"
    if request = @requests.shift()
      request @port
      process.nextTick =>
        @drainQueue()

  handle: (request) ->
    @lastAccess = new Date
    if @ready
      request @port
    else
      @requests.push request

  isIdle: ->
    new Date - @lastAccess > 1000 * 60 * 15  # 15 minutes

  kill: ->
    @process.kill() if @process

