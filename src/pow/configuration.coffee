{join} = require "path"
fs = require "fs"

class Finalizer
  @from: (finalizerOrCallback) ->
    if finalizerOrCallback instanceof Finalizer
      finalizerOrCallback
    else
      new Finalizer(finalizerOrCallback ? ->)

  constructor: (callback) ->
    @callback = callback
    @count = 0
    @done = no

  increment: ->
    return if @done
    @count += 1

  decrement: ->
    return if @done
    if (@count -= 1) <= 0
      @done = yes
      @callback()

exports.Configuration = class Configuration
  constructor: (root) ->
    @root = root

  findPathForHost: (host, callback) ->
    @gather (paths) =>
      for filename in @getFilenamesForHost host
        if path = paths[filename]
          return callback path
      callback false

  gather: (callback) ->
    paths = {}

    finalizer = new Finalizer -> callback paths
    finalizer.increment()

    fs.readdir @root, (err, filenames) =>
      throw err if err
      for filename in filenames then do (filename) =>
        finalizer.increment()
        path = join(@root, filename)
        fs.lstat path, (err, stats) ->
          throw err if err
          if stats.isSymbolicLink()
            finalizer.increment()
            fs.readlink path, (err, resolvedPath) ->
              paths[filename] = join(resolvedPath, "config.ru")
              finalizer.decrement()
          finalizer.decrement()
      finalizer.decrement()

  getFilenamesForHost: (host) ->
    parts = host.split "."
    length = parts.length - 2
    for i in [0..length]
      parts.slice(i, length + 1).join "."
