fs     = require "fs"
{exec} = require "child_process"
{join} = require "path"

exports.fixturePath = fixturePath = (path) ->
  join fs.realpathSync(join __dirname, ".."), "fixtures", path

exports.prepareFixtures = (callback) ->
  rm_rf fixturePath("tmp"), ->
    mkdirp fixturePath("tmp"), ->
      callback()

exports.rm_rf = rm_rf = (path, callback) ->
  exec "rm -rf #{path}", (err, stdout, stderr) ->
    if err then callback err
    else callback()

exports.mkdirp = mkdirp = (path, callback) ->
  exec "mkdir -p #{path}", (err, stdout, stderr) ->
    if err then callback err
    else callback()
