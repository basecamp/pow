fs     = require "fs"
http   = require "http"
{exec} = require "child_process"
{join} = require "path"

{Configuration} = require "../.."

process.env["RUBYOPT"] = "-rubygems"

exports.createConfiguration = (options = {}) ->
  options.hostRoot ?= fixturePath("tmp")
  options.logRoot  ?= fixturePath("tmp/logs")
  new Configuration options

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

exports.debug = debug = ->
  if process.env.DEBUG
    console.error.apply console, arguments

exports.serve = serve = (server, callback) ->
  server.listen 0, ->
    port = server.address().port
    debug "server listening on port #{port}"
    request = createRequester server.address().port
    callback request, (callback) ->
      debug "server on port #{port} is closing"
      server.close()
      callback()

exports.createRequester = createRequester = (port) ->
  (method, path, headers, callback) ->
    callback = headers unless callback
    client   = http.createClient port
    request  = client.request method, path, headers
    request.end()
    debug "client requesting #{method} #{path} on port #{port}"
    request.on "response", (response) ->
      body = ""
      response.on "data", (chunk) ->
        debug "client received #{chunk.length} bytes from server on port #{port}"
        body += chunk.toString "utf8"
      response.on "end", ->
        debug "client disconnected from server on port #{port}"
        callback body, response
