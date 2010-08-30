{Pool}      = require "./pool"
http        = require "http"
{HttpProxy} = require "http-proxy"

exports.Server = class Server
  constructor: (@configuration) ->
    @pool = new Pool
    @server = http.createServer (req, res) =>
      @onRequest req, res

  listen: (port) ->
    @server.listen port

  onRequest: (req, res, proxy) ->
    if path = @findPathForHost req.headers.host
      proxy = new HttpProxy
      proxy.watch req, res
      @pool.handle path, (port) ->
        console.log "handle path = #{path}, port = #{port}"
        proxy.proxyRequest port, "0.0.0.0", req, res
    else
      @respondWithError res, "unknown host #{req.headers.host}"

  findPathForHost: (host) ->
    for path, hosts of @configuration
      if match(host, against: hosts)
        return path
    false

  respondWithError: (res, err) ->
    res.writeHead 500, "Content-Type": "text/html"
    res.write "<h1>500 Internal Server Error</h1><p>#{err}</p>"
    res.end()

  reapIdleApplications: ->
    application.kill() for application in @pool.getIdleApplications()

match = (hostWithPort, options) ->
  host = hostWithPort.replace /:.*/, ""
  patterns = for pattern in options.against
    pattern.replace(/\./g, "\\.").replace(/\*/g, ".*")
  new RegExp("^#{patterns.join "|"}$", "i").exec host

