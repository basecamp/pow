(function() {
  var Daemon, DnsServer, HttpServer;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  HttpServer = require("./http_server");
  DnsServer = require("./dns_server");
  module.exports = Daemon = (function() {
    function Daemon(configuration) {
      this.configuration = configuration;
      this.httpServer = new HttpServer(this.configuration);
      this.dnsServer = new DnsServer(this.configuration);
    }
    Daemon.prototype.start = function() {
      var dnsPort, flunk, httpPort, pass, startServer, _ref;
      if (this.starting || this.started) {
        return;
      }
      this.starting = true;
      startServer = function(server, port, callback) {
        try {
          return server.listen(port, function() {
            return callback(null);
          });
        } catch (err) {
          return callback(err);
        }
      };
      pass = __bind(function() {
        this.starting = false;
        return this.started = true;
      }, this);
      flunk = __bind(function(err) {
        this.starting = false;
        try {
          this.httpServer.close();
        } catch (_e) {}
        try {
          return this.dnsServer.close();
        } catch (_e) {}
      }, this);
      _ref = this.configuration, httpPort = _ref.httpPort, dnsPort = _ref.dnsPort;
      return startServer(this.httpServer, httpPort, __bind(function(err) {
        if (err) {
          return flunk(err);
        } else {
          return startServer(this.dnsServer, dnsPort, __bind(function(err) {
            if (err) {
              return flunk(err);
            } else {
              return pass();
            }
          }, this));
        }
      }, this));
    };
    Daemon.prototype.stop = function() {
      var stopServer;
      if (this.stopping || !this.started) {
        return;
      }
      this.stopping = true;
      stopServer = function(server, callback) {
        try {
          server.on("close", function() {
            return callback(null);
          });
          return server.close();
        } catch (err) {
          return callback(err);
        }
      };
      return stopServer(this.httpServer, __bind(function() {
        return stopServer(this.dnsServer, __bind(function() {
          this.stopping = false;
          return this.started = false;
        }, this));
      }, this));
    };
    return Daemon;
  })();
}).call(this);
