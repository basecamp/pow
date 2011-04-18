(function() {
  var HttpServer, RackApplication, connect, dirname, exists, fs, join, pause, sys, _ref;
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
  RackApplication = require("./rack_application");
  pause = require("./util").pause;
  _ref = require("path"), dirname = _ref.dirname, join = _ref.join, exists = _ref.exists;
  module.exports = HttpServer = (function() {
    var o, x;
    __extends(HttpServer, connect.HTTPServer);
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
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.handleNonexistentDomain = __bind(this.handleNonexistentDomain, this);;
      this.handleApplicationException = __bind(this.handleApplicationException, this);;
      this.handleApplicationRequest = __bind(this.handleApplicationRequest, this);;
      this.findRackApplication = __bind(this.findRackApplication, this);;
      this.handleStaticRequest = __bind(this.handleStaticRequest, this);;
      this.findApplicationRoot = __bind(this.findApplicationRoot, this);;
      this.logRequest = __bind(this.logRequest, this);;
      HttpServer.__super__.constructor.call(this, [o(this.logRequest), o(this.annotateRequest), o(this.findApplicationRoot), o(this.handleStaticRequest), o(this.findRackApplication), o(this.handleApplicationRequest), x(this.handleApplicationException)]);
      this.staticHandlers = {};
      this.rackApplications = {};
      this.accessLog = this.configuration.getLogger("access");
      this.on("close", __bind(function() {
        var application, root, _ref, _results;
        _ref = this.rackApplications;
        _results = [];
        for (root in _ref) {
          application = _ref[root];
          _results.push(application.quit());
        }
        return _results;
      }, this));
    }
    HttpServer.prototype.logRequest = function(req, res, next) {
      this.accessLog.info("[" + req.socket.remoteAddress + "] " + req.method + " " + req.headers.host + " " + req.url);
      return next();
    };
    HttpServer.prototype.annotateRequest = function(req, res, next) {
      var host;
      host = req.headers.host.replace(/:.*/, "");
      req.pow = {
        host: host
      };
      return next();
    };
    HttpServer.prototype.findApplicationRoot = function(req, res, next) {
      var resume;
      resume = pause(req);
      return this.configuration.findApplicationRootForHost(req.pow.host, __bind(function(err, domain, root) {
        if (err) {
          next(err);
          return resume();
        } else {
          if (req.pow.root = root) {
            req.pow.domain = domain;
            req.pow.resume = resume;
            return next();
          } else {
            this.handleNonexistentDomain(req, res, next);
            return resume();
          }
        }
      }, this));
    };
    HttpServer.prototype.handleStaticRequest = function(req, res, next) {
      var handler, root, _base, _ref, _ref2;
      if ((_ref = req.method) !== "GET" && _ref !== "HEAD") {
        return next();
      }
      if (!(root = req.pow.root)) {
        return next();
      }
      handler = (_ref2 = (_base = this.staticHandlers)[root]) != null ? _ref2 : _base[root] = connect.static(join(root, "public"));
      return handler(req, res, function() {
        next();
        return req.pow.resume();
      });
    };
    HttpServer.prototype.findRackApplication = function(req, res, next) {
      var root;
      if (!(root = req.pow.root)) {
        return next();
      }
      return exists(join(root, "config.ru"), __bind(function(rackConfigExists) {
        var application, _base, _ref;
        if (rackConfigExists) {
          req.pow.application = (_ref = (_base = this.rackApplications)[root]) != null ? _ref : _base[root] = new RackApplication(this.configuration, root);
        } else if (application = this.rackApplications[root]) {
          delete this.rackApplications[root];
          application.quit();
        }
        return next();
      }, this));
    };
    HttpServer.prototype.handleApplicationRequest = function(req, res, next) {
      var application;
      if (application = req.pow.application) {
        return application.handle(req, res, next, req.pow.resume);
      } else {
        return next();
      }
    };
    HttpServer.prototype.render = function(res, status, templateName, context) {
      var template;
      if (context == null) {
        context = {};
      }
      template = require("./templates/http_server/" + templateName + ".html");
      res.writeHead(status, {
        "Content-Type": "text/html; charset=utf8",
        "X-Pow-Template": templateName
      });
      return res.end(template(context));
    };
    HttpServer.prototype.handleApplicationException = function(err, req, res, next) {
      var root;
      if (!(root = req.pow.root)) {
        return next();
      }
      return this.render(res, 500, "application_exception", {
        err: err,
        root: root
      });
    };
    HttpServer.prototype.handleNonexistentDomain = function(req, res, next) {
      var host, name;
      host = req.pow.host;
      name = host.slice(0, host.length - this.configuration.domains[0].length - 1);
      return this.render(res, 503, "nonexistent_domain", {
        path: join(this.configuration.root, name)
      });
    };
    return HttpServer;
  })();
}).call(this);
