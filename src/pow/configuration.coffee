fs     = require "fs"
{join} = require "path"
async  = require "async"

getFilenamesForHost = (host) ->
  parts = host.split "."
  length = parts.length - 2
  for i in [0..length]
    parts.slice(i, length + 1).join "."

module.exports = class Configuration
  constructor: (options = {}) ->
    @httpPort = options.httpPort ? 20559
    @dnsPort  = options.dnsPort  ? 20560
    @timeout  = options.timeout  ? 15 * 60 * 1000
    @domain   = options.domain   ? "test"
    @root     = options.root     ? join process.env.HOME, ".pow"

  findApplicationRootForHost: (host, callback) ->
    @gatherApplicationRoots (err, roots) =>
      return callback err if err
      for file in getFilenamesForHost host
        if root = roots[file]
          return callback null, root
      callback null

  gatherApplicationRoots: (callback) ->
    roots = {}
    fs.readdir @root, (err, files) =>
      return callback err if err
      async.forEach files, (file, next) =>
        path = join @root, file
        fs.lstat path, (err, stats) ->
          return callback err if err
          if stats.isSymbolicLink()
            fs.readlink path, (err, resolvedPath) ->
              return callback err if err
              roots[file] = resolvedPath
              next()
          else if stats.isDirectory()
            roots[file] = path
            next()
          else
            next()
      , (err) ->
        callback err, roots
