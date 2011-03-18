# Pow's `Logger` wraps the
# [Log.js](https://github.com/visionmedia/log.js) library in a class
# that adds log file autovivification. The log file you specify is
# automatically created the first time you call a log method.

fs        = require "fs"
{dirname} = require "path"
Log       = require "log"
{mkdirp}  = require "./util"

module.exports = class Logger
  # Log level method names that will be forwarded to the underlying
  # `Log` instance.
  @LEVELS: ["debug", "info", "notice", "warning", "error",
            "critical", "alert", "emergency"]

  # Create a `Logger` that writes to the file at the given path and
  # log level. The logger begins life in the uninitialized state.
  constructor: (@path, @level = "debug") ->
    @readyCallbacks = []

  # Invoke `callback` if the logger's state is ready. Otherwise, queue
  # the callback to be invoked when the logger becomes ready, then
  # start the initialization process.
  ready: (callback) ->
    if @state is "ready"
      callback.call @
    else
      @readyCallbacks.push callback
      unless @state
        @state = "initializing"
        # Make the log file's directory if it doesn't already
        # exist. Reset the logger's state if an error is thrown.
        mkdirp dirname(@path), (err) =>
          if err
            @state = null
          else
            # Open a write stream for the log file and create the
            # underlying `Log` instance. Then set the logger state to
            # ready and invoke all queued callbacks.
            @stream = fs.createWriteStream @path, flags: "a"
            @stream.on "open", =>
              @log = new Log @level, @stream
              @state = "ready"
              for callback in @readyCallbacks
                callback.call @
              @readyCallbacks = []

# Define the log level methods as wrappers around the corresponding
# `Log` methods passing through `ready`.
for level in Logger.LEVELS then do (level) ->
  Logger::[level] = (args...) ->
    @ready -> @log[level].apply @log, args
