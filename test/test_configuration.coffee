async           = require "async"
fs              = require "fs"
{testCase}      = require "nodeunit"

{prepareFixtures, fixturePath, createConfiguration} = require "./lib/test_helper"

module.exports = testCase
  setUp: (proceed) ->
    prepareFixtures proceed

  "gatherHostConfigurations returns directories and symlinks to directories": (test) ->
    test.expect 1
    configuration = createConfiguration hostRoot: fixturePath("configuration")
    configuration.gatherHostConfigurations (err, hosts) ->
      test.same hosts,
        "directory":            { root: fixturePath("configuration/directory") }
        "www.directory":        { root: fixturePath("configuration/www.directory") }
        "symlink-to-directory": { root: fixturePath("apps/hello") }
        "symlink-to-symlink":   { root: fixturePath("apps/hello") }
        "port-number":          { url:  "http://localhost:3333" }
        "remote-host":          { url:  "http://pow.cx/" }
      test.done()

  "gatherHostConfigurations with non-existent host": (test) ->
    test.expect 2
    configuration = createConfiguration hostRoot: fixturePath("tmp/pow")
    configuration.gatherHostConfigurations (err, hosts) ->
      test.same {}, hosts
      fs.lstat fixturePath("tmp/pow"), (err, stat) ->
        test.ok stat.isDirectory()
        test.done()

  "findHostConfiguration matches hostnames to application roots": (test) ->
    configuration   = createConfiguration hostRoot: fixturePath("configuration")
    matchHostToRoot = (host, fixtureRoot) -> (proceed) ->
      configuration.findHostConfiguration host, (err, domain, conf) ->
        if fixtureRoot
          test.same "dev", domain
          test.same { root: fixturePath(fixtureRoot) }, conf
        else
          test.ok !conf
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

  "findHostConfiguration with alternate domain": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["dev.local"]
    test.expect 3
    configuration.findHostConfiguration "directory.dev.local", (err, domain, conf) ->
      test.same "dev.local", domain
      test.same fixturePath("configuration/directory"), conf.root
      configuration.findHostConfiguration "directory.dev", (err, domain, conf) ->
        test.ok !conf
        test.done()

  "findHostConfiguration with multiple domains": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["test", "dev"]
    test.expect 4
    configuration.findHostConfiguration "directory.dev", (err, domain, conf) ->
      test.same "dev", domain
      test.same fixturePath("configuration/directory"), conf.root
      configuration.findHostConfiguration "directory.dev", (err, domain, conf) ->
        test.same "dev", domain
        test.same fixturePath("configuration/directory"), conf.root
        test.done()

  "findHostConfiguration with default host": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration-with-default")
    test.expect 2
    configuration.findHostConfiguration "missing.dev", (err, domain, conf) ->
      test.same "dev", domain
      test.same fixturePath("apps/hello"), conf.root
      test.done()

  "findHostConfiguration with ext domain": (test) ->
    configuration = createConfiguration hostRoot: fixturePath("configuration"), domains: ["dev"], extDomains: ["me"]
    test.expect 2
    configuration.findHostConfiguration "directory.me", (err, domain, conf) ->
      test.same "me", domain
      test.same fixturePath("configuration/directory"), conf.root
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
