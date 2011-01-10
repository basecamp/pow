(function() {
  var HttpServer, connect, fs, join, nack;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  fs = require("fs");
  join = require("path").join;
  connect = require("connect");
  nack = require("nack");
  module.exports = HttpServer = (function() {
    __extends(HttpServer, connect.Server);
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.closeApplications = __bind(this.closeApplications, this);;
      this.handleRequest = __bind(this.handleRequest, this);;
      this.handlers = {};
      HttpServer.__super__.constructor.call(this, [
        this.handleRequest, connect.errorHandler({
          showStack: true
        })
      ]);
      this.on("close", this.closeApplications);
    }
    HttpServer.prototype.getHandlerForHost = function(host, callback) {
      return this.configuration.findApplicationRootForHost(host, __bind(function(err, root) {
        if (err) {
          return callback(err);
        }
        return callback(null, this.getHandlerForRoot(root));
      }, this));
    };
    HttpServer.prototype.getHandlerForRoot = function(root) {
      var _base;
      return (_base = this.handlers)[root] || (_base[root] = {
        root: root,
        app: nack.createServer(join(root, "config.ru"), {
          idle: this.configuration.timeout
        })
      });
    };
    HttpServer.prototype.handleRequest = function(req, res, next) {
      var host, pause;
      pause = connect.utils.pause(req);
      host = req.headers.host.replace(/:.*/, "");
      return this.getHandlerForHost(host, __bind(function(err, handler) {
        return this.restartIfNecessary(handler, __bind(function() {
          pause.end();
          if (err) {
            return next(err);
          }
          req.proxyMetaVariables = this.configuration.dstPort;
          handler.app.handle(req, res, next);
          return pause.resume();
        }, this));
      }, this));
    };
    HttpServer.prototype.closeApplications = function() {
      var app, root, _ref, _results;
      _ref = this.handlers;
      _results = [];
      for (root in _ref) {
        app = _ref[root].app;
        _results.push(app.pool.quit());
      }
      return _results;
    };
    HttpServer.prototype.restartIfNecessary = function(_arg, callback) {
      var app, root;
      root = _arg.root, app = _arg.app;
      return fs.unlink(join(root, "tmp/restart.txt"), function(err) {
        if (err) {
          return callback();
        } else {
          app.pool.onNext("exit", callback);
          return app.pool.quit();
        }
      });
    };
    return HttpServer;
  })();
}).call(this);
