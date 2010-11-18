(function() {
  var _ref, exec, util;
  util = require(process.binding('natives').util ? 'util' : 'sys');
  _ref = require('child_process');
  exec = _ref.exec;
  exports.forwardPort = function(port, callback) {
    return exec("ipfw add fwd 127.0.0.1," + (port) + " tcp from any to any dst-port 80 in", function(error, stdout, stderr) {
      util.print(stdout);
      util.print(stderr);
      if (typeof error !== "undefined" && error !== null) {
        callback(1);
      }
      return exec("sysctl -w net.inet.ip.forwarding=1", function(error, stdout, stderr) {
        util.print(stdout);
        util.print(stderr);
        if (typeof error !== "undefined" && error !== null) {
          callback(1);
        }
        return callback(0);
      });
    });
  };
}).call(this);
