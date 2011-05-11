async           = require "async"
fs              = require "fs"
{testCase}      = require "nodeunit"

{prepareFixtures, fixturePath, createConfiguration} = require "./lib/test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "gatherApplicationRoots returns directories and symlinks to directories": (test) ->
    test.expect 1
    configuration = createConfiguration hostRoot: fixturePath("configuration")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same roots,
        "directory":            fixturePath("configuration/directory")
        "www.directory":        fixturePath("configuration/www.directory")
        "symlink-to-directory": fixturePath("apps/hello")
        "symlink-to-symlink":   fixturePath("apps/hello")
      test.done()

  "gatherApplicationRoots with non-existent root": (test) ->
    test.expect 2
    configuration = createConfiguration hostRoot: fixturePath("tmp/pow")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same {}, roots
      fs.lstat fixturePath("tmp/pow"), (err, stat) ->
        test.ok stat.isDirectory()
        test.done()

  "findApplicationRootForHost matches hostnames to application roots": (test) ->
    configuration   = createConfiguration hostRoot: fixturePath("configuration")
    matchHostToRoot = (host, fixtureRoot) -> (proceed) ->
      configuration.findApplicationRootForHost host, (err, domain, root) ->
        if fixtureRoot
          test.same "dev", domain
          test.same fixturePath(fixtureRoot), root
        else
          test.ok !root
        proceed()

    test.expect 14
    async.parallel [
      matchHostToRoot "directory.dev",            "configuration/directory"
      matchHostToRoot "sub.directory.dev",        "configuration/directory"
      matchHostToRoot "www.directory.dev",        "configuration/www.directory"
      matchHostToRoot "asset0.www.directory.dev", "configuration/www.directory"
      matchHostToRoot "symlink-to-directory.dev", "apps/hello"
      matchHostToRoot "symlink-to-symlink.dev",   "apps/hello"
      matchHostToRoot "directory"
      matchHostToRoot "nonexistent.dev"
    ], test.done

  "findApplicationRootForHost with alternate domain": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["dev.local"]
    test.expect 3
    configuration.findApplicationRootForHost "directory.dev.local", (err, domain, root) ->
      test.same "dev.local", domain
      test.same fixturePath("configuration/directory"), root
      configuration.findApplicationRootForHost "directory.dev", (err, domain, root) ->
        test.ok !root
        test.done()

  "findApplicationRootForHost with multiple domains": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["test", "dev"]
    test.expect 4
    configuration.findApplicationRootForHost "directory.dev", (err, domain, root) ->
      test.same "dev", domain
      test.same fixturePath("configuration/directory"), root
      configuration.findApplicationRootForHost "directory.dev", (err, domain, root) ->
        test.same "dev", domain
        test.same fixturePath("configuration/directory"), root
        test.done()

  "findApplicationRootForHost with default host": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration-with-default")
    test.expect 2
    configuration.findApplicationRootForHost "missing.dev", (err, domain, root) ->
      test.same "dev", domain
      test.same fixturePath("apps/hello"), root
      test.done()

  "findApplicationRootForHost with ext domain": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["dev"], extDomains: ["me"]
    test.expect 2
    configuration.findApplicationRootForHost "directory.me", (err, domain, root) ->
      test.same "me", domain
      test.same fixturePath("configuration/directory"), root
      test.done()

  "getLogger returns the same logger instance": (test) ->
    configuration = createConfiguration()
    logger = configuration.getLogger "test"
    test.expect 2
    test.ok logger is   configuration.getLogger "test"
    test.ok logger isnt configuration.getLogger "test2"
    test.done()

  "getLogger returns a logger with the specified log root": (test) ->
    test.expect 2

    configuration = createConfiguration()
    logger = configuration.getLogger "test"
    test.same fixturePath("tmp/logs/test.log"), logger.path

    configuration = createConfiguration logRoot: fixturePath("tmp/log2")
    logger = configuration.getLogger "test"
    test.same fixturePath("tmp/log2/test.log"), logger.path

    test.done()
