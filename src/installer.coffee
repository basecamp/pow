async    = require "async"
fs       = require "fs"
path     = require "path"
{mkdirp} = require "./util"
{spawn}  = require "child_process"
sys      = require "sys"

resolverSource = require "./resolver"
firewallSource = require "./cx.pow.firewall.plist"
daemonSource   = require "./cx.pow.powd.plist"

chown = (path, owner, callback) ->
  error = ""
  chown = spawn "chown", [owner, path]
  chown.stderr.on "data", (data) -> error += data.toString "utf8"
  chown.on "exit", (code) -> callback error, code is 0

class InstallerFile
  constructor: (@path, source, @root = false) ->
    @source = source.trim()

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

  vivifyPath: (callback) =>
    mkdirp path.dirname(@path), callback

  writeFile: (callback) =>
    fs.writeFile @path, @source, "utf8", callback

  setOwnership: (callback) =>
    if @root
      chown @path, "root:wheel", callback
    else
      callback false

  install: (callback) ->
    async.series [
      @vivifyPath,
      @writeFile,
      @setOwnership
    ], callback

module.exports = class Installer
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

    new Installer @configuration, files

  @getLocalInstaller: (@configuration) ->
    new Installer @configuration, [
      new InstallerFile "#{process.env.HOME}/Library/LaunchAgents/cx.pow.powd.plist",
        daemonSource(@configuration)
    ]

  constructor: (@configuration, @files = []) ->

  getStaleFiles: (callback) ->
    async.select @files, (file, proceed) ->
      file.isStale proceed
    , callback

  needsRootPrivileges: (callback) ->
    @getStaleFiles (files) ->
      async.detect files, (file, proceed) ->
        proceed file.root
      , (result) ->
        callback result?

  install: (callback) ->
    @getStaleFiles (files) ->
      async.forEach files, (file, proceed) ->
        file.install (err) ->
          sys.puts file.path unless err
          proceed err
      , callback
