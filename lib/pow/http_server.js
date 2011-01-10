(function() {
  var HttpServer, connect, join, nack;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  join = require("path").join;
  connect = require("connect");
  nack = require("nack");
  module.exports = HttpServer = (function() {
    __extends(HttpServer, connect.Server);
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.handleRequest = __bind(this.handleRequest, this);;
      this.handlers = {};
      HttpServer.__super__.constructor.call(this, [
        this.handleRequest, connect.errorHandler({
          showStack: true
        })
      ]);
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
      return (_base = this.handlers)[root] || (_base[root] = nack.createServer(join(root, "config.ru"), {
        idle: this.configuration.timeout
      }));
    };
    HttpServer.prototype.handleRequest = function(req, res, next) {
      var host, pause;
      pause = connect.utils.pause(req);
      host = req.headers.host.replace(/:.*/, "");
      return this.getHandlerForHost(host, function(err, handler) {
        pause.end();
        if (err) {
          return next(err);
        }
        req.proxyMetaVariables = {
          SERVER_PORT: '80'
        };
        handler.handle(req, res, next);
        return pause.resume();
      });
    };
    return HttpServer;
  })();
}).call(this);
