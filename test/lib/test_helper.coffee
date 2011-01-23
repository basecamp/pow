fs     = require "fs"
http   = require "http"
{exec} = require "child_process"
{join} = require "path"

exports.fixturePath = fixturePath = (path) ->
  join fs.realpathSync(join __dirname, ".."), "fixtures", path

exports.prepareFixtures = (callback) ->
  rm_rf fixturePath("tmp"), ->
    mkdirp fixturePath("tmp"), ->
      callback()

exports.rm_rf = rm_rf = (path, callback) ->
  exec "rm -rf #{path}", (err) ->
    if err then callback err
    else callback()

exports.mkdirp = mkdirp = (path, callback) ->
  exec "mkdir -p #{path}", (err) ->
    if err then callback err
    else callback()

exports.touch = touch = (path, callback) ->
  exec "touch #{path}", (err) ->
    if err then callback err
    else callback()

exports.serve = serve = (server, callback) ->
  server.listen 0, ->
    request = createRequester server.address().port
    callback request, (callback) ->
      server.close()
      callback()

exports.createRequester = createRequester = (port) ->
  (method, path, headers, callback) ->
    callback = headers unless callback
    client   = http.createClient port
    request  = client.request method, path, headers
    request.end()
    request.on "response", (response) ->
      body = ""
      response.on "data", (chunk) -> body += chunk.toString "utf8"
      response.on "end", ->
        callback body, response
