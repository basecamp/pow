# The `util` module houses a number of utility functions used
# throughout Pow.

fs       = require "fs"
path     = require "path"
async    = require "async"
{exec}   = require "child_process"
{spawn}  = require "child_process"
{Stream} = require 'stream'

# The `LineBuffer` class is a `Stream` that emits a `data` event for
# each line in the stream.
exports.LineBuffer = class LineBuffer extends Stream
  # Create a `LineBuffer` around the given stream.
  constructor: (@stream) ->
    @readable = true
    @_buffer = ""

    # Install handlers for the underlying stream's `data` and `end`
    # events.
    self = this
    @stream.on 'data', (args...) -> self.write args...
    @stream.on 'end',  (args...) -> self.end args...

  # Write a chunk of data read from the stream to the internal buffer.
  write: (chunk) ->
    @_buffer += chunk

    # If there's a newline in the buffer, slice the line from the
    # buffer and emit it. Repeat until there are no more newlines.
    while (index = @_buffer.indexOf("\n")) != -1
      line     = @_buffer[0...index]
      @_buffer = @_buffer[index+1...@_buffer.length]
      @emit 'data', line

  # Process any final lines from the underlying stream's `end`
  # event. If there is trailing data in the buffer, emit it.
  end: (args...) ->
    if args.length > 0
      @write args...
    @emit 'data', @_buffer if @_buffer.length
    @emit 'end'

# Read lines from `stream` and invoke `callback` on each line.
exports.bufferLines = (stream, callback) ->
  buffer = new LineBuffer stream
  buffer.on "data", callback
  buffer

# ---

# Asynchronously and recursively create a directory if it does not
# already exist. Then invoke the given callback.
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

# A wrapper around `chown(8)` for taking ownership of a given path
# with the specified owner string (such as `"root:wheel"`). Invokes
# `callback` with the error string, if any, and a boolean value
# indicating whether or not the operation succeeded.
exports.chown = (path, owner, callback) ->
  error = ""
  chown = spawn "chown", [owner, path]
  chown.stderr.on "data", (data) -> error += data.toString "utf8"
  chown.on "exit", (code) -> callback error, code is 0

# Capture all `data` events on the given stream and return a function
# that, when invoked, replays the captured events on the stream in
# order.
exports.pause = (stream) ->
  unless stream._pausable
    # Patch this stream object to make it nicely pausable
    stream._pausable =
      pauses: 0
      events: ['data', 'end']
      queue:  []
      emit:   stream.emit
      pause:  -> stream._pausable.pauses++
      resume: ->
        if stream._pausable.pauses > 0
          stream._pausable.pauses--

          # No more pauses: empty the queue
          if stream._pausable.pauses == 0
            stream.emit args... for args in stream._pausable.queue
            stream._pausable.queue = []

    # Override stream.emit to emulate pausing
    stream.emit = (event, args...) ->
      if stream._pausable.pauses > 0 and event in stream._pausable.events
        stream._pausable.queue.push [event, args...]
      else
        args.unshift event
        stream._pausable.emit.apply stream, args

  stream._pausable.pause()

  onClose = -> removeListeners()
  stream.on 'close', onClose

  removeListeners = ->
    stream.removeListener 'close', onClose

  ->
    removeListeners()
    stream._pausable.resume()

# Spawn a shell with the given `env` and source the named
# `script`. Then collect its resulting environment variables and pass
# them to `callback` as the second argument. If the script returns a
# non-zero exit code, call `callback` with the error as its first
# argument, and annotate the error with the captured `stdout` and
# `stderr`.
exports.sourceScriptEnv = (script, env, options, callback) ->
  if options.call
    callback = options
    options = {}
  else
    options ?= {}

  command = """
    #{options.before};
    source '#{script}' > /dev/null;
    '#{process.execPath}' -e 'JSON.stringify(process.env)'
  """

  exec command, cwd: path.dirname(script), env: env, (err, stdout, stderr) ->
    if err
      err.message = "'#{script}' failed to load"
      err.stdout = stdout
      err.stderr = stderr
      callback err

    try
      callback null, JSON.parse stdout
    catch exception
      callback exception
