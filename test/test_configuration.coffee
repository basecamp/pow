{exec}     = require "child_process"
fs         = require "fs"
{join}     = require "path"
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

  "gatherApplicationRoots with non-existent root": (test) ->
    test.expect 2
    configuration = new Configuration root: fixturePath("tmp/pow")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same {}, roots
      fs.lstat fixturePath("tmp/pow"), (err, stat) ->
        test.ok stat.isDirectory()
        test.done()

  "gatherApplicationRoots returns directories and symlinks to directories": (test) ->
    test.expect 1
    configuration = new Configuration root: fixturePath("configuration")
    configuration.gatherApplicationRoots (err, roots) ->
      test.same roots,
        'directory':            fixturePath('configuration/directory')
        'symlink-to-directory': fixturePath('apps/hello')
        'symlink-to-symlink':   fixturePath('apps/hello')
      test.done()
