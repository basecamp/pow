(function() {
  var Configuration, Daemon, _ref;
  _ref = require(".."), Daemon = _ref.Daemon, Configuration = _ref.Configuration;
  process.title = "pow";
  Configuration.getGlobalConfiguration(function(err, configuration) {
    var daemon;
    if (err) {
      throw err;
    }
    daemon = new Daemon(configuration);
    return daemon.start();
  });
}).call(this);
