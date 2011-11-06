# The `Installer` class, in conjunction with the private
# `InstallerFile` class, creates and installs local and system
# configuration files if they're missing or out of date. It's used by
# the Pow install script to set up the system for local development.

async    = require "async"
fs       = require "fs"
path     = require "path"
{mkdirp} = require "./util"
{chown}  = require "./util"
util     = require "util"

# Import the Eco templates for the `/etc/resolver` and `launchd`
# configuration files.
resolverSource = require "./templates/installer/resolver"
firewallSource = require "./templates/installer/cx.pow.firewall.plist"
daemonSource   = require "./templates/installer/cx.pow.powd.plist"

# `InstallerFile` represents a single file candidate for installation:
# a pathname, a string of the file's source, and optional flags
# indicating whether the file needs to be installed as root and what
# permission bits it should have.
class InstallerFile
  constructor: (@path, source, @root = false, @mode = 0644) ->
    @source = source.trim()

  # Check to see whether the file actually needs to be installed. If
  # the file exists on the filesystem with the specified path and
  # contents, `callback` is invoked with false. Otherwise, `callback`
  # is invoked with true.
  isStale: (callback) ->
    path.exists @path, (exists) =>
      if exists
        fs.readFile @path, "utf8", (err, contents) =>
          if err
            callback true
          else
            callback @source isnt contents.trim()
      else
        callback true

  # Create all the parent directories of the file's path, if
  # necessary, and then invoke `callback`.
  vivifyPath: (callback) =>
    mkdirp path.dirname(@path), callback

  # Write the file's source to disk and invoke `callback`.
  writeFile: (callback) =>
    fs.writeFile @path, @source, "utf8", callback

  # If the root flag is set for this file, change its ownership to the
  # `root` user and `wheel` group. Then invoke `callback`.
  setOwnership: (callback) =>
    if @root
      chown @path, "root:wheel", callback
    else
      callback false

  # Set permissions on the installed file with `chmod`.
  setPermissions: (callback) =>
    fs.chmod @path, @mode, callback

  # Install a file asynchronously, first by making its parent
  # directory, then writing it to disk, and finally setting its
  # ownership and permission bits.
  install: (callback) ->
    async.series [
      @vivifyPath,
      @writeFile,
      @setOwnership,
      @setPermissions
    ], callback

# The `Installer` class operates on a set of `InstallerFile` instances.
# It can check to see if any files are stale and whether or not root
# access is necessary for installation. It can also install any stale
# files asynchronously.
module.exports = class Installer
  # Factory method that takes a `Configuration` instance and returns
  # an `Installer` for system firewall and DNS configuration files.
  @getSystemInstaller: (@configuration) ->
    files = [
      new InstallerFile "/Library/LaunchDaemons/cx.pow.firewall.plist",
        firewallSource(@configuration),
        true
    ]

    for domain in @configuration.domains
      files.push new InstallerFile "/etc/resolver/#{domain}",
        resolverSource(@configuration),
        true

    new Installer files

  # Factory method that takes a `Configuration` instance and returns
  # an `Installer` for the Pow `launchctl` daemon configuration file.
  @getLocalInstaller: (@configuration) ->
    new Installer [
      new InstallerFile "#{process.env.HOME}/Library/LaunchAgents/cx.pow.powd.plist",
        daemonSource(@configuration)
    ]

  # Create an installer for a set of files.
  constructor: (@files = []) ->

  # Invoke `callback` with an array of any files that need to be
  # installed.
  getStaleFiles: (callback) ->
    async.select @files, (file, proceed) ->
      file.isStale proceed
    , callback

  # Invoke `callback` with a boolean argument indicating whether or
  # not any files need to be installed as root.
  needsRootPrivileges: (callback) ->
    @getStaleFiles (files) ->
      async.detect files, (file, proceed) ->
        proceed file.root
      , (result) ->
        callback result?

  # Installs any stale files asynchronously and then invokes
  # `callback`.
  install: (callback) ->
    @getStaleFiles (files) ->
      async.forEach files, (file, proceed) ->
        file.install (err) ->
          util.puts file.path unless err
          proceed err
      , callback
