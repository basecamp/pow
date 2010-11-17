(function() {
  var Configuration, Server, _ref;
  _ref = require("./server");
  Server = _ref.Server;
  _ref = require("./configuration");
  Configuration = _ref.Configuration;
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
