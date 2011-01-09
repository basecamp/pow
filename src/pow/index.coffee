{Configuration} = require "./configuration"
{NameServer} = require "./name_server"
{WebServer} = require "./web_server"

exports.Configuration = Configuration
exports.NameServer = NameServer
exports.WebServer = WebServer

exports.defaultOptions =
  httpPort: 20559
  dnsPort:  20560
  configurationPath: process.env.HOME + "/.pow"

exports.run = (options = {}) ->
  {httpPort, dnsPort, configurationPath} = Object.create exports.defaultOptions, options

  configuration = new Configuration configurationPath
  nameServer = new NameServer
  webServer = new WebServer configuration

  nameServer.listen dnsPort
  webServer.listen httpPort

  {nameServer, webServer}
