{Pool}      = require "./pool"
http        = require "http"
{HttpProxy} = require "http-proxy"

exports.Server = class Server
  constructor: (@configuration) ->
    @pool = new Pool
    @server = http.createServer (req, res) =>
      @onRequest req, res

  listen: (port) ->
    unless @interval
      @server.listen port
      @interval = setInterval (=> @reapIdleApplications()), 1000

  close: ->
    if @interval
      @server.close()
      clearInterval @interval
      @interval = false

  onRequest: (req, res, proxy) ->
    host  = req.headers.host.replace /:.*/, ""
    proxy = new HttpProxy
    proxy.watch req, res
    @configuration.findPathForHost host, (path) =>
      if path
        @pool.handle path, (port) ->
          console.log "handle path = #{path}, port = #{port}"
          proxy.proxyRequest port, "0.0.0.0", req, res
      else
        @respondWithError res, "unknown host #{req.headers.host}"

  respondWithError: (res, err) ->
    res.writeHead 500, "Content-Type": "text/html"
    res.write "<h1>500 Internal Server Error</h1><p>#{err}</p>"
    res.end()

  reapIdleApplications: ->
    application.kill() for application in @pool.getIdleApplications()
