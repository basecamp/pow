(function() {
  var Configuration, Daemon, flag, _ref;
  _ref = require(".."), Daemon = _ref.Daemon, Configuration = _ref.Configuration;
  process.title = "pow";
  flag = process.argv[2];
  Configuration.getUserConfiguration(function(err, configuration) {
    var daemon;
    if (err) {
      throw err;
    }
    if (flag === "--install" || flag === "-i") {
      return configuration.install(function(err) {
        if (err) {
          throw err;
        }
      });
    } else {
      daemon = new Daemon(configuration);
      return daemon.start();
    }
  });
}).call(this);
