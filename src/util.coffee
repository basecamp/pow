fs    = require "fs"
path  = require "path"
async = require "async"

{Stream} = require 'stream'

exports.escapeHTML = (string) ->
  string.toString()
    .replace(/&/g,  "&amp;")
    .replace(/</g,  "&lt;")
    .replace(/>/g,  "&gt;")
    .replace(/\"/g, "&quot;")

exports.mkdirp = (dirname, callback) ->
  fs.lstat (p = path.normalize dirname), (err, stats) ->
    if err
      paths = [p].concat(p = path.dirname p until p in ["/", "."])
      async.forEachSeries paths.reverse(), (p, next) ->
        path.exists p, (exists) ->
          if exists then next()
          else fs.mkdir p, 0755, (err) ->
            if err then callback err
            else next()
      , callback
    else if stats.isDirectory()
      callback()
    else
      callback "file exists"

exports.pause = (stream) ->
  queue = []

  onData  = (args...) -> queue.push ['data', args...]
  onEnd   = (args...) -> queue.push ['end', args...]
  onClose = -> removeListeners()

  removeListeners = ->
    stream.removeListener 'data', onData
    stream.removeListener 'end', onEnd
    stream.removeListener 'close', onClose

  stream.on 'data', onData
  stream.on 'end', onEnd
  stream.on 'close', onClose

  ->
    removeListeners()

    for args in queue
      stream.emit args...

exports.LineBuffer = class LineBuffer extends Stream
  constructor: (@stream) ->
    @readable = true
    @_buffer = ""

    # Buffer `data` and `end` events from `@stream`
    self = this
    @stream.on 'data', (args...) -> self.write args...
    @stream.on 'end',  (args...) -> self.end args...

  write: (chunk) ->
    # Write chunk to string buffer
    @_buffer += chunk

    # Check for `\n` in buffer
    while (index = @_buffer.indexOf("\n")) != -1
      line     = @_buffer[0...index]
      @_buffer = @_buffer[index+1...@_buffer.length]

      # Emit `data` line as a single line
      @emit 'data', line

  end: (args...) ->
    if args.length > 0
      @write args...

    @emit 'end'
