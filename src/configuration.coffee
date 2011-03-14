# The `Configuration` class encapsulates various options for a Pow
# daemon (port numbers, directories, etc.). It's also responsible for
# creating `Logger` instances and mapping hostnames to application
# root paths.

fs       = require "fs"
path     = require "path"
async    = require "async"
Logger   = require "./logger"
{mkdirp} = require "./util"

module.exports = class Configuration
  # Pass in any options you'd like to override when creating a
  # `Configuration` instance. Valid options and their defaults:
  constructor: (options = {}) ->
    # `dstPort`: the public port Pow expects to be forwarded or
    # otherwise proxied for incoming HTTP requests. Defaults to `80`.
    @dstPort  = options.dstPort  ? 80

    # `httpPort`: the TCP port Pow opens for accepting incoming HTTP
    # requests. Defaults to `20559`.
    @httpPort = options.httpPort ? 20559

    # `dnsPort`: the UDP port Pow listens on for incoming DNS
    # queries. Defaults to `20560`.
    @dnsPort  = options.dnsPort  ? 20560

    # `timeout`: how long (in milliseconds) to leave inactive Rack
    # applications running before they're killed. Defaults to 15
    # minutes.
    @timeout  = options.timeout  ? 15 * 60 * 1000

    # `workers`: the maximum number of worker processes to spawn for
    # any given application. Defaults to `2`.
    @workers  = options.workers  ? 2

    # `domain`: the top-level domain for which Pow will respond to DNS
    # `A` queries with `127.0.0.1`. Defaults to `test`.
    @domain   = options.domain   ? "test"

    # `hostRoot`: path to the directory containing symlinks to
    # applications that will be served by Pow. Defaults to
    # `~/Library/Application Support/Pow/Hosts`.
    @hostRoot = options.hostRoot ? libraryPath "Application Support", "Pow", "Hosts"

    # `logRoot`: path to the directory that Pow will use to store its
    # log files. Defaults to `~/Library/Logs/Pow`.
    @logRoot  = options.logRoot  ? libraryPath "Logs", "Pow"

    # ---
    @loggers  = {}

  # Retrieve a `Logger` instance with the given `name`.
  getLogger: (name) ->
    @loggers[name] ||= new Logger path.join @logRoot, name + ".log"

  # Search `hostRoot` for symlinks or directories matching the domain
  # specified by `host`. If a match is found, it's passed to
  # `callback` as a second argument. If no match is found, `callback`
  # is called without any arguments. If an error is raised, `callback`
  # is called with the error as its first argument.
  findApplicationRootForHost: (host, callback) ->
    @gatherApplicationRoots (err, roots) =>
      return callback err if err
      for file in getFilenamesForHost host, @domain
        if root = roots[file]
          return callback null, root
      callback null

  # Asynchronously build a mapping of entries in `hostRoot` to
  # application root paths. For each symlink, store the symlink's name
  # and the real path of the application it points to. For each
  # directory, store the directory's name and its full path. The
  # mapping is passed as an object to the second argument of
  # `callback`. If an error is raised, `callback` is called with the
  # error as its first argument.
  #
  # The mapping object will look something like this:
  #
  #     {
  #       "basecamp":  "/Volumes/37signals/basecamp",
  #       "launchpad": "/Volumes/37signals/launchpad",
  #       "37img":     "/Volumes/37signals/portfolio"
  #     }
  gatherApplicationRoots: (callback) ->
    roots = {}
    mkdirp @hostRoot, (err) =>
      return callback err if err
      fs.readdir @hostRoot, (err, files) =>
        return callback err if err
        async.forEach files, (file, next) =>
          root = path.join @hostRoot, file
          fs.lstat root, (err, stats) ->
            if stats?.isSymbolicLink()
              fs.realpath root, (err, resolvedPath) ->
                if err then next()
                else fs.lstat resolvedPath, (err, stats) ->
                  roots[file] = resolvedPath if stats?.isDirectory()
                  next()
            else if stats?.isDirectory()
              roots[file] = root
              next()
            else
              next()
        , (err) ->
          callback err, roots

# Convenience wrapper for constructing paths to subdirectories of
# `~/Library`.
libraryPath = (args...) ->
  path.join process.env.HOME, "Library", args...

# Strip a trailing `domain` from the given `host`, then generate a
# sorted array of possible entry names for finding which application
# should serve the host. For example, a `host` of
# `asset0.37s.basecamp.test` will produce `["asset0.37s.basecamp",
# "37s.basecamp", "basecamp"]`, and `basecamp.test` will produce
# `["basecamp"]`.
getFilenamesForHost = (host, domain) ->
  if host.slice(-domain.length - 1) is ".#{domain}"
    parts  = host.slice(0, -domain.length - 1).split "."
    length = parts.length
    for i in [0...length]
      parts.slice(i, length).join "."
  else
    []
