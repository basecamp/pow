(function() {
  var Server, connect, fs, idle, nack, path, sys;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  }, __hasProp = Object.prototype.hasOwnProperty;
  connect = require('connect');
  fs = require('fs');
  nack = require('nack');
  path = require('path');
  sys = require('sys');
  idle = 1000 * 60 * 15;
  process.env['RACK_ENV'] = 'development';
  exports.Server = (function() {
    Server = function(_arg) {
      this.configuration = _arg;
      this.applications = {};
      this.server = connect.createServer(connect.logger(), this.onRequest.bind(this), connect.errorHandler({
        dumpExceptions: true
      }));
      return this;
    };
    Server.prototype.listen = function(port) {
      this.server.listen(port);
      process.on('SIGINT', __bind(function() {
        return this.close();
      }, this));
      process.on('SIGTERM', __bind(function() {
        return this.close();
      }, this));
      return process.on('SIGQUIT', __bind(function() {
        return this.close();
      }, this));
    };
    Server.prototype.close = function() {
      var _ref, app, config;
      if (this.closing) {
        return null;
      }
      this.closing = true;
      _ref = this.applications;
      for (config in _ref) {
        if (!__hasProp.call(_ref, config)) continue;
        app = _ref[config];
        app.close();
      }
      this.server.close();
      return process.nextTick(function() {
        return process.exit(0);
      });
    };
    Server.prototype.createApplicationPool = function(config) {
      var app, root;
      root = path.dirname(config);
      app = nack.createServer(config, {
        idle: idle
      });
      sys.pump(app.pool.stdout, process.stdout);
      sys.pump(app.pool.stderr, process.stdout);
      fs.watchFile("" + (root) + "/tmp/restart.txt", function(curr, prev) {
        return fs.unlink("" + (root) + "/tmp/restart.txt", function(err) {
          return !err ? app.pool.quit() : null;
        });
      });
      return app;
    };
    Server.prototype.applicationForConfig = function(config) {
      return config ? this.applications[config] = (typeof this.applications[config] !== "undefined" && this.applications[config] !== null) ? this.applications[config] : this.createApplicationPool(config) : null;
    };
    Server.prototype.onRequest = function(req, res, next) {
      var host, pause;
      pause = connect.utils.pause(req);
      host = req.headers.host.replace(/:.*/, "");
      return this.configuration.findPathForHost(host, __bind(function(path) {
        var app;
        pause.end();
        if (app = this.applicationForConfig(path)) {
          app.handle(req, res, next);
          return pause.resume();
        } else {
          return next(new Error("unknown host " + (req.headers.host)));
        }
      }, this));
    };
    return Server;
  })();
}).call(this);
