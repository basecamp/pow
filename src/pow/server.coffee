http = require 'http'
nack = require 'nack/pool'

{BufferedReadStream} = require 'nack/buffered'

idle = 1000 * 60 * 15

exports.Server = class Server
  constructor: (@configuration) ->
    @applications = {}
    @server = http.createServer (req, res) =>
      @onRequest req, res

  listen: (port) ->
    @server.listen port

  close: ->
    @server.close()

  applicationForConfig: (config) ->
    @applications[config] ?= nack.createPool config, size: 3, idle: idle

  onRequest: (req, res) ->
    reqBuf = new BufferedReadStream req
    host = req.headers.host.replace /:.*/, ""
    @configuration.findPathForHost host, (path) =>
      if app = @applicationForConfig path
        app.proxyRequest reqBuf, res
        reqBuf.flush()
      else
        @respondWithError res, "unknown host #{req.headers.host}"

  respondWithError: (res, err) ->
    res.writeHead 500, "Content-Type": "text/html"
    res.write "<h1>500 Internal Server Error</h1><p>#{err}</p>"
    res.end()
