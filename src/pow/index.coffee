{Server} = require "./server"
{Configuration} = require "./configuration"

exports.Server = Server
exports.Configuration = Configuration

exports.run = (port, configurationPath) ->
  configuration = new Configuration configurationPath
  server = new Server configuration
  server.listen port
  server
