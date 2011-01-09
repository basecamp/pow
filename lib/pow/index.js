(function() {
  var Configuration, NameServer, WebServer;
  Configuration = require("./configuration").Configuration;
  NameServer = require("./name_server").NameServer;
  WebServer = require("./web_server").WebServer;
  exports.Configuration = Configuration;
  exports.NameServer = NameServer;
  exports.WebServer = WebServer;
  exports.defaultOptions = {
    httpPort: 20559,
    dnsPort: 20560,
    configurationPath: process.env.HOME + "/.pow"
  };
  exports.run = function(options) {
    var configuration, configurationPath, dnsPort, httpPort, nameServer, webServer, _ref;
    if (options == null) {
      options = {};
    }
    _ref = Object.create(exports.defaultOptions, options), httpPort = _ref.httpPort, dnsPort = _ref.dnsPort, configurationPath = _ref.configurationPath;
    configuration = new Configuration(configurationPath);
    nameServer = new NameServer;
    webServer = new WebServer(configuration);
    nameServer.listen(dnsPort);
    webServer.listen(httpPort);
    return {
      nameServer: nameServer,
      webServer: webServer
    };
  };
}).call(this);
