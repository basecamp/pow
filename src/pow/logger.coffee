fs        = require "fs"
{dirname} = require "path"
Log       = require "log"
{mkdirp}  = require "./util"

module.exports = class Logger
  @LEVELS: ["debug", "info", "notice", "warning", "error", "critical", "alert", "emergency"]

  constructor: (@path, @level = "debug") ->
    @pause()
    mkdirp dirname(@path), (err) =>
      return if err
      @stream = fs.createWriteStream @path, flags: "a"
      @stream.on "open", =>
        @log = new Log @level, @stream
        @resume()

  pause: ->
    @buffer ||= []

  resume: ->
    return unless @buffer
    for level, args in @buffer
      @log[level](args...)
    @buffer = null

for method in Logger.LEVELS then do (method) ->
  Logger::[method] = ->
    if @buffer
      @buffer.push method, arguments
    else
      @log[method].apply @log, arguments
