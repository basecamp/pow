{exec}     = require "child_process"
fs         = require "fs"
{join}     = require "path"
async      = require "async"
{testCase} = require "nodeunit"

Configuration = require "pow/configuration"

fixturePath = (path) ->
  join fs.realpathSync(__dirname), "fixtures", path

rm_rf = (path, callback) ->
  exec "rm -rf #{path}", (err, stdout, stderr) ->
    if err then callback err
    else callback()

mkdirp = (path, callback) ->
  exec "mkdir -p #{path}", (err, stdout, stderr) ->
    if err then callback err
    else callback()

module.exports = testCase
  setUp: (proceed) ->
    rm_rf fixturePath("tmp"), ->
      mkdirp fixturePath("tmp"), ->
        proceed()

  "gatherApplicationRoots returns directories and symlinks to directories": (test) ->
    test.expect 1
    configuration = new Configuration root: fixturePath("configuration")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same roots,
        "directory":            fixturePath("configuration/directory")
        "www.directory":        fixturePath("configuration/www.directory")
        "symlink-to-directory": fixturePath("apps/hello")
        "symlink-to-symlink":   fixturePath("apps/hello")
      test.done()

  "gatherApplicationRoots with non-existent root": (test) ->
    test.expect 2
    configuration = new Configuration root: fixturePath("tmp/pow")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same {}, roots
      fs.lstat fixturePath("tmp/pow"), (err, stat) ->
        test.ok stat.isDirectory()
        test.done()

  "findApplicationRootForHost matches hostnames to application roots": (test) ->
    configuration   = new Configuration root: fixturePath("configuration")
    matchHostToRoot = (host, fixtureRoot) -> (proceed) ->
      configuration.findApplicationRootForHost host, (err, root) ->
        if fixtureRoot then test.same fixturePath(fixtureRoot), root
        else test.ok !root
        proceed()

    test.expect 8
    async.parallel [
      matchHostToRoot "directory.test",            "configuration/directory"
      matchHostToRoot "sub.directory.test",        "configuration/directory"
      matchHostToRoot "www.directory.test",        "configuration/www.directory"
      matchHostToRoot "asset0.www.directory.test", "configuration/www.directory"
      matchHostToRoot "symlink-to-directory.test", "apps/hello"
      matchHostToRoot "symlink-to-symlink.test",   "apps/hello"
      matchHostToRoot "directory"
      matchHostToRoot "nonexistent.test"
    ], test.done

  "findApplicationRootForHost with alternate domain": (test) ->
    configuration = new Configuration root: fixturePath("configuration"), domain: "dev.local"
    test.expect 2
    configuration.findApplicationRootForHost "directory.dev.local", (err, root) ->
      test.same fixturePath("configuration/directory"), root
      configuration.findApplicationRootForHost "directory.test", (err, root) ->
        test.ok !root
        test.done()
