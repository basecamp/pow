# The `Configuration` class encapsulates various options for a Pow
# daemon (port numbers, directories, etc.). It's also responsible for
# creating `Logger` instances and mapping hostnames to application
# root paths.

fs                = require "fs"
path              = require "path"
async             = require "async"
Logger            = require "./logger"
{mkdirp}          = require "./util"
{sourceScriptEnv} = require "./util"

module.exports = class Configuration
  # The user configuration file, `~/.powconfig`, is evaluated on
  # boot.  You can configure options such as the top-level domain,
  # number of workers, the worker idle timeout, and listening ports.
  #
  #     export POW_DOMAINS=dev,test
  #     export POW_WORKERS=3
  #
  # See the `Configuration` constructor for a complete list of
  # environment options.
  @userConfigurationPath: path.join process.env['HOME'], ".powconfig"

  # Evaluates the user configuration script and calls the `callback`
  # with the environment variables if the config file exists. Any
  # script errors are passed along in the first argument. (No error
  # occurs if the file does not exist.)
  @loadUserConfigurationEnvironment: (callback) ->
    path.exists p = @userConfigurationPath, (exists) ->
      if exists
        sourceScriptEnv p, {}, callback
      else
        callback null, {}

  # Creates a Configuration object after evaluating the user
  # configuration file. Any environment variables in `~/.powconfig`
  # affect the process environment and will be copied to spawned
  # subprocesses.
  @getUserConfiguration: (callback) ->
    @loadUserConfigurationEnvironment (err, env) ->
      if err
        callback err
      else
        for key, value of env
          process.env[key] = value

        callback null, new Configuration

  # Pass in any options you'd like to override when creating a
  # `Configuration` instance. Valid options and their defaults:
  constructor: (options = {}) ->
    # `bin`: the path to `pow` binary. This should automatically be
    # configured correctly.
    @bin      = options.bin      ? process.env['POW_BIN']       ? path.join(__dirname, "../bin/pow")

    # `dstPort`: the public port Pow expects to be forwarded or
    # otherwise proxied for incoming HTTP requests. Defaults to `80`.
    @dstPort  = options.dstPort  ? process.env['POW_DST_PORT']  ? 80

    # `httpPort`: the TCP port Pow opens for accepting incoming HTTP
    # requests. Defaults to `20559`.
    @httpPort = options.httpPort ? process.env['POW_HTTP_PORT'] ? 20559

    # `dnsPort`: the UDP port Pow listens on for incoming DNS
    # queries. Defaults to `20560`.
    @dnsPort  = options.dnsPort  ? process.env['POW_DNS_PORT']  ? 20560

    # `mDnsPort`: the UDP port Pow listens on for incoming DNS
    # queries. Defaults to `5353`.
    @mDnsPort  = options.mDnsPort ? process.env['POW_MDNS_PORT']  ? 5353

    # `mDnsPort`: the UDP port Pow listens on for incoming DNS
    # queries. Defaults to `5353`.
    @mDnsAddress = options.mDnsAddress ? process.env['POW_MDNS_ADDRESS']  ? "224.0.0.251"
    
    # `mDnsDomain`: the mDNS domain name. Defaults to `local`.
    @mDnsDomain = options.mDnsDomain ? process.env['POW_MDNS_DOMAIN'] ? 'local'
    
    # `mDnsHost`: the mDNS hostname portion responded to.
    # Defaults to system hostname.
    @mDnsHost = options.mDnsHost ? process.env['POW_MDNS_HOST'] ? null

    # `timeout`: how long (in milliseconds) to leave inactive Rack
    # applications running before they're killed. Defaults to 15
    # minutes.
    @timeout  = options.timeout  ? process.env['POW_TIMEOUT']   ? 15 * 60 * 1000

    # `workers`: the maximum number of worker processes to spawn for
    # any given application. Defaults to `2`.
    @workers  = options.workers  ? process.env['POW_WORKERS']   ? 2

    # `domain`: the top-level domains for which Pow will respond to DNS
    # `A` queries with `127.0.0.1`. Defaults to `dev`.
    domain    = options.domain   ? process.env['POW_DOMAIN']    ? "dev"

    # `domains`: alias for `domain`
    @domains  = options.domains  ? process.env['POW_DOMAINS']   ? domain

    # Allow for comma seperated domain list: "dev,test"
    @domains  = if @domains.split then @domains.split(",") else @domains

    # `hostRoot`: path to the directory containing symlinks to
    # applications that will be served by Pow. Defaults to
    # `~/Library/Application Support/Pow/Hosts`.
    @hostRoot = options.hostRoot ? process.env['POW_HOST_ROOT'] ? libraryPath "Application Support", "Pow", "Hosts"

    # `logRoot`: path to the directory that Pow will use to store its
    # log files. Defaults to `~/Library/Logs/Pow`.
    @logRoot  = options.logRoot  ? process.env['POW_LOG_ROOT']  ? libraryPath "Logs", "Pow"

    # `rvmPath`: path to the rvm initialization script. Defaults to
    # `~/.rvm/scripts/rvm`.
    @rvmPath  = options.rvmPath  ? process.env['POW_RVM_PATH']  ? path.join process.env.HOME, ".rvm/scripts/rvm"

    # ---
    @loggers  = {}

  # Retrieve a `Logger` instance with the given `name`.
  getLogger: (name) ->
    @loggers[name] ||= new Logger path.join @logRoot, name + ".log"

  # Search `hostRoot` for symlinks or directories matching the domain
  # specified by `host`. If a match is found, the matching domain name
  # and host are passed as second and third arguments to `callback`.
  # If no match is found, `callback` is called without any arguments.
  # If an error is raised, `callback` is called with the error as its
  # first argument.
  findApplicationRootForHost: (host, callback) ->
    @gatherApplicationRoots (err, roots) =>
      return callback err if err
      for domain in @domains
        for file in getFilenamesForHost host, domain
          if root = roots[file]
            return callback null, domain, root

      if root = roots["default"]
        return callback null, @domains[0], root

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
          name = file.toLowerCase()
          fs.lstat root, (err, stats) ->
            if stats?.isSymbolicLink()
              fs.realpath root, (err, resolvedPath) ->
                if err then next()
                else fs.lstat resolvedPath, (err, stats) ->
                  roots[name] = resolvedPath if stats?.isDirectory()
                  next()
            else if stats?.isDirectory()
              roots[name] = root
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
# `asset0.37s.basecamp.dev` will produce `["asset0.37s.basecamp",
# "37s.basecamp", "basecamp"]`, and `basecamp.dev` will produce
# `["basecamp"]`.
getFilenamesForHost = (host, domain) ->
  host = host.toLowerCase()
  if host.slice(-domain.length - 1) is ".#{domain}"
    parts  = host.slice(0, -domain.length - 1).split "."
    length = parts.length
    for i in [0...length]
      parts.slice(i, length).join "."
  else
    []
