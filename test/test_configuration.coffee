async           = require "async"
fs              = require "fs"
{testCase}      = require "nodeunit"
{Configuration} = require ".."

{prepareFixtures, fixturePath} = require "./lib/test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

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

  "getLogger returns the same logger instance": (test) ->
    configuration = new Configuration root: fixturePath("tmp")
    logger = configuration.getLogger "test"
    test.expect 2
    test.ok logger is   configuration.getLogger "test"
    test.ok logger isnt configuration.getLogger "test2"
    test.done()

  "getLogger returns a logger with the specified log root": (test) ->
    test.expect 2

    configuration = new Configuration root: fixturePath("tmp")
    logger = configuration.getLogger "test"
    test.same fixturePath("tmp/.log/test.log"), logger.path

    configuration = new Configuration root: fixturePath("tmp/config"), logRoot: fixturePath("tmp/logs")
    logger = configuration.getLogger "test"
    test.same fixturePath("tmp/logs/test.log"), logger.path

    test.done()
