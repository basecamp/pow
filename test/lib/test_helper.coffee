fs     = require "fs"
http   = require "http"
{exec} = require "child_process"
{join} = require "path"

{Configuration} = require "../.."

exports.merge = merge = (objects...) ->
  result = {}
  for object in objects
    for key, value of object
      result[key] = value
  result

exports.fixturePath = fixturePath = (path) ->
  join fs.realpathSync(join __dirname, ".."), "fixtures", path

defaultEnvironment =
  POW_HOST_ROOT: fixturePath "tmp"
  POW_LOG_ROOT:  fixturePath "tmp/logs"

exports.createConfiguration = (env = {}) ->
  new Configuration merge defaultEnvironment, env

exports.prepareFixtures = (callback) ->
  rm_rf fixturePath("tmp"), ->
    mkdirp fixturePath("tmp"), ->
      callback()

exports.rm_rf = rm_rf = (path, callback) ->
  exec "rm -rf #{path}", callback

exports.mkdirp = mkdirp = (path, callback) ->
  exec "mkdir -p #{path}", callback

exports.touch = touch = (path, callback) ->
  exec "touch #{path}", callback

exports.swap = swap = (path1, path2, callback) ->
  unswap = (callback) ->
    swap path2, path1, callback

  exec """
    mv #{path1} #{path1}.swap;
    mv #{path2} #{path1};
    mv #{path1}.swap #{path2}
  """, (err) ->
    callback err, unswap

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
    , server

exports.createRequester = createRequester = (port) ->
  (method, path, headers, callback) ->
    callback = headers unless callback
    client   = http.createClient port
    request  = client.request method, path, headers

    if data = headers.data
      delete headers.data
      request.write data

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
