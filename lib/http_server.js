(function() {
  var HttpServer, RackHandler, connect, dirname, escapeHTML, fs, getHost, join, o, pause, sys, x, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  fs = require("fs");
  sys = require("sys");
  connect = require("connect");
  pause = require("./util").pause;
  RackHandler = require("./rack_handler");
  _ref = require("path"), dirname = _ref.dirname, join = _ref.join;
  getHost = function(req) {
    return req.headers.host.replace(/:.*/, "");
  };
  escapeHTML = function(string) {
    return string.toString().replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\"/g, "&quot;");
  };
  o = function(fn) {
    return function(req, res, next) {
      return fn(req, res, next);
    };
  };
  x = function(fn) {
    return function(err, req, res, next) {
      return fn(err, req, res, next);
    };
  };
  module.exports = HttpServer = (function() {
    __extends(HttpServer, connect.HTTPServer);
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.handleNonexistentDomain = __bind(this.handleNonexistentDomain, this);;
      this.handleApplicationException = __bind(this.handleApplicationException, this);;
      this.handleRackRequest = __bind(this.handleRackRequest, this);;
      this.handleStaticRequest = __bind(this.handleStaticRequest, this);;
      this.findApplicationRoot = __bind(this.findApplicationRoot, this);;
      this.logRequest = __bind(this.logRequest, this);;
      this.closeApplications = __bind(this.closeApplications, this);;
      HttpServer.__super__.constructor.call(this, [o(this.logRequest), o(this.findApplicationRoot), o(this.handleStaticRequest), o(this.handleRackRequest), x(this.handleApplicationException)]);
      this.staticHandlers = {};
      this.rackHandlers = {};
      this.accessLog = this.configuration.getLogger("access");
      this.on("close", this.closeApplications);
    }
    HttpServer.prototype.closeApplications = function() {
      var handler, root, _ref, _results;
      _ref = this.rackHandlers;
      _results = [];
      for (root in _ref) {
        handler = _ref[root];
        _results.push(handler.quit());
      }
      return _results;
    };
    HttpServer.prototype.logRequest = function(req, res, next) {
      this.accessLog.info("[" + req.socket.remoteAddress + "] " + req.method + " " + req.headers.host + " " + req.url);
      return next();
    };
    HttpServer.prototype.findApplicationRoot = function(req, res, next) {
      var host, resume;
      host = getHost(req);
      resume = pause(req);
      return this.configuration.findApplicationRootForHost(host, __bind(function(err, root) {
        if (err) {
          next(err);
          return resume();
        } else {
          req.pow = {
            host: host,
            root: root
          };
          if (!root) {
            this.handleNonexistentDomain(req, res, next);
            return resume();
          } else {
            req.pow.resume = resume;
            return next();
          }
        }
      }, this));
    };
    HttpServer.prototype.handleStaticRequest = function(req, res, next) {
      var handler, root, _base, _ref, _ref2;
      if ((_ref = req.method) !== "GET" && _ref !== "HEAD") {
        return next();
      }
      if (!req.pow) {
        return next();
      }
      root = req.pow.root;
      handler = (_ref2 = (_base = this.staticHandlers)[root]) != null ? _ref2 : _base[root] = connect.static(join(root, "public"));
      return handler(req, res, function() {
        next();
        return req.pow.resume();
      });
    };
    HttpServer.prototype.handleRackRequest = function(req, res, next) {
      var handler, root, _base, _ref;
      if (!req.pow) {
        return next();
      }
      root = req.pow.root;
      handler = (_ref = (_base = this.rackHandlers)[root]) != null ? _ref : _base[root] = new RackHandler(this.configuration, root);
      return handler.handle(req, res, next, req.pow.resume);
    };
    HttpServer.prototype.handleApplicationException = function(err, req, res, next) {
      if (!req.pow) {
        return next();
      }
      res.writeHead(500, {
        "Content-Type": "text/html; charset=utf8",
        "X-Pow-Handler": "ApplicationException"
      });
      return res.end("<!doctype html>\n<html>\n<head>\n  <title>Pow: Error Starting Application</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n    }\n    h1, h2, pre {\n      margin: 0;\n      padding: 15px 30px;\n    }\n    h1, h2 {\n      font-family: Helvetica, sans-serif;\n    }\n    h1 {\n      font-size: 36px;\n      background: #eeedea;\n      color: #c00;\n      border-bottom: 1px solid #999090;\n    }\n    h2 {\n      font-size: 18px;\n      font-weight: normal;\n    }\n  </style>\n</head>\n<body>\n  <h1>Pow can&rsquo;t start your application.</h1>\n  <h2><code>" + (escapeHTML(req.pow.root)) + "</code> raised an exception during boot.</h2>\n  <pre><strong>" + (escapeHTML(err)) + "</strong>" + (escapeHTML("\n" + err.stack)) + "</pre>\n</body>\n</html>");
    };
    HttpServer.prototype.handleNonexistentDomain = function(req, res, next) {
      var host, name, path;
      if (!req.pow) {
        return next();
      }
      host = req.pow.host;
      name = host.slice(0, host.length - this.configuration.domain.length - 1);
      path = join(this.configuration.root, name);
      res.writeHead(503, {
        "Content-Type": "text/html; charset=utf8",
        "X-Pow-Handler": "NonexistentDomain"
      });
      return res.end("<!doctype html>\n<html>\n<head>\n  <title>Pow: No Such Application</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n    }\n    h1, h2 {\n      margin: 0;\n      padding: 15px 30px;\n      font-family: Helvetica, sans-serif;\n    }\n    h1 {\n      font-size: 36px;\n      background: #eeedea;\n      color: #000;\n      border-bottom: 1px solid #999090;\n    }\n    h2 {\n      font-size: 18px;\n      font-weight: normal;\n    }\n  </style>\n</head>\n<body>\n  <h1>This domain isn&rsquo;t set up yet.</h1>\n  <h2>Symlink your application to <code>" + (escapeHTML(path)) + "</code> first.</h2>\n</body>\n</html>");
    };
    return HttpServer;
  })();
}).call(this);
