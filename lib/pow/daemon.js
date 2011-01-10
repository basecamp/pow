(function() {
  var Daemon, DnsServer, EventEmitter, HttpServer;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  HttpServer = require("./http_server");
  DnsServer = require("./dns_server");
  EventEmitter = require("events").EventEmitter;
  module.exports = Daemon = (function() {
    __extends(Daemon, EventEmitter);
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
        this.started = true;
        return this.emit("start");
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
        var close;
        try {
          close = function() {
            server.removeListener("close", close);
            return callback(null);
          };
          server.on("close", close);
          return server.close();
        } catch (err) {
          return callback(err);
        }
      };
      return stopServer(this.httpServer, __bind(function() {
        return stopServer(this.dnsServer, __bind(function() {
          this.stopping = false;
          this.started = false;
          return this.emit("stop");
        }, this));
      }, this));
    };
    return Daemon;
  })();
}).call(this);
