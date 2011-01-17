fs    = require "fs"
path  = require "path"
async = require "async"

getFilenamesForHost = (host) ->
  parts = host.split "."
  length = parts.length - 2
  for i in [0..length]
    parts.slice(i, length + 1).join "."

mkdirp = (dirname, callback) ->
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

module.exports = class Configuration
  constructor: (options = {}) ->
    @dstPort  = options.dstPort  ? 80
    @httpPort = options.httpPort ? 20559
    @dnsPort  = options.dnsPort  ? 20560
    @timeout  = options.timeout  ? 15 * 60 * 1000
    @domain   = options.domain   ? "test"
    @root     = options.root     ? path.join process.env.HOME, ".pow"

  findApplicationRootForHost: (host, callback) ->
    @gatherApplicationRoots (err, roots) =>
      return callback err if err
      for file in getFilenamesForHost host
        if root = roots[file]
          return callback null, root
      callback null

  gatherApplicationRoots: (callback) ->
    roots = {}
    mkdirp @root, (err) =>
      return callback err if err
      fs.readdir @root, (err, files) =>
        return callback err if err
        async.forEach files, (file, next) =>
          root = path.join @root, file
          fs.lstat root, (err, stats) ->
            return callback err if err
            if stats.isSymbolicLink()
              fs.readlink root, (err, resolvedPath) ->
                return callback err if err
                roots[file] = resolvedPath
                next()
            else if stats.isDirectory()
              roots[file] = root
              next()
            else
              next()
        , (err) ->
          callback err, roots
