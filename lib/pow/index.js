(function() {
  var Configuration, Server;
  Server = require("./server").Server;
  Configuration = require("./configuration").Configuration;
  exports.Server = Server;
  exports.Configuration = Configuration;
  exports.run = function(port, configurationPath) {
    var configuration, server;
    configuration = new Configuration(configurationPath);
    server = new Server(configuration);
    server.listen(port);
    return server;
  };
}).call(this);
