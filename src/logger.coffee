fs        = require "fs"
{dirname} = require "path"
Log       = require "log"
{mkdirp}  = require "./util"

module.exports = class Logger
  @LEVELS: ["debug", "info", "notice", "warning", "error", "critical", "alert", "emergency"]

  constructor: (@path, @level = "debug") ->
    @pause()

  pause: ->
    @buffer ||= []

  resume: ->
    return unless @buffer
    for level, args in @buffer
      @log[level](args...)
    @buffer = null

  open: (callback) ->
    if @stream
      callback.call @
    else
      mkdirp dirname(@path), (err) =>
        return if err
        @stream = fs.createWriteStream @path, flags: "a"
        @stream.on "open", =>
          @log = new Log @level, @stream
          @resume()
          callback.call @

  perform: (level, args...) =>
    if @buffer
      @buffer.push [level, args]
    else
      @log[level].apply @log, args

for level in Logger.LEVELS then do (level) ->
  Logger::[level] = (args...) ->
    @open -> @perform level, args
