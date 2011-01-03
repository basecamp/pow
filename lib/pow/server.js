(function() {
  var Server, connect, fs, idle, nack, path, sys;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  connect = require('connect');
  fs = require('fs');
  nack = require('nack');
  path = require('path');
  sys = require('sys');
  idle = 1000 * 60 * 15;
  process.env['RACK_ENV'] = 'development';
  exports.Server = Server = (function() {
    function Server(configuration) {
      this.configuration = configuration;
      this.applications = {};
      this.server = connect.createServer(this.onRequest.bind(this), connect.errorHandler({
        dumpExceptions: true
      }));
    }
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
      var app, config, _ref;
      if (this.closing) {
        return;
      }
      this.closing = true;
      _ref = this.applications;
      for (config in _ref) {
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
      fs.watchFile("" + root + "/tmp/restart.txt", function(curr, prev) {
        return fs.unlink("" + root + "/tmp/restart.txt", function(err) {
          if (!err) {
            return app.pool.quit();
          }
        });
      });
      return app;
    };
    Server.prototype.applicationForConfig = function(config) {
      var _base, _ref;
      if (config) {
        return (_ref = (_base = this.applications)[config]) != null ? _ref : _base[config] = this.createApplicationPool(config);
      }
    };
    Server.prototype.onRequest = function(req, res, next) {
      var host, pause;
      pause = connect.utils.pause(req);
      host = req.headers.host.replace(/:.*/, "");
      return this.configuration.findPathForHost(host, __bind(function(path) {
        var app;
        pause.end();
        if (app = this.applicationForConfig(path)) {
          req.headers['x-forwarded-port'] = '80';
          app.handle(req, res, next);
          return pause.resume();
        } else {
          return next(new Error("unknown host " + req.headers.host));
        }
      }, this));
    };
    return Server;
  })();
}).call(this);
