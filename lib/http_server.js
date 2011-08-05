(function() {
  var HttpServer, RackApplication, connect, dirname, exists, fs, join, pause, sys, version, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  };
  fs = require("fs");
  sys = require("sys");
  connect = require("connect");
  RackApplication = require("./rack_application");
  pause = require("./util").pause;
  _ref = require("path"), dirname = _ref.dirname, join = _ref.join, exists = _ref.exists;
  version = JSON.parse(fs.readFileSync(__dirname + "/../package.json", "utf8")).version;
  module.exports = HttpServer = (function() {
    var o, renderResponse, renderTemplate, x;
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
    renderTemplate = function(templateName, renderContext, yield) {
      var context, key, template, value;
      template = require("./templates/http_server/" + templateName + ".html");
      context = {
        renderTemplate: renderTemplate,
        yield: yield
      };
      for (key in renderContext) {
        value = renderContext[key];
        context[key] = value;
      }
      return template(context);
    };
    renderResponse = function(res, status, templateName, context) {
      if (context == null) {
        context = {};
      }
      res.writeHead(status, {
        "Content-Type": "text/html; charset=utf8",
        "X-Pow-Template": templateName
      });
      return res.end(renderTemplate(templateName, context));
    };
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.handleWelcomeRequest = __bind(this.handleWelcomeRequest, this);
      this.handleApplicationNotFound = __bind(this.handleApplicationNotFound, this);
      this.findRackApplication = __bind(this.findRackApplication, this);
      this.handleStaticRequest = __bind(this.handleStaticRequest, this);
      this.findApplicationRoot = __bind(this.findApplicationRoot, this);
      this.handlePowRequest = __bind(this.handlePowRequest, this);
      this.logRequest = __bind(this.logRequest, this);
      HttpServer.__super__.constructor.call(this, [o(this.logRequest), o(this.annotateRequest), o(this.handlePowRequest), o(this.findApplicationRoot), o(this.handleStaticRequest), o(this.findRackApplication), o(this.handleApplicationRequest), x(this.handleErrorStartingApplication), o(this.handleFaviconRequest), o(this.handleApplicationNotFound), o(this.handleWelcomeRequest), o(this.handleRailsAppWithoutRackupFile), o(this.handleLocationNotFound)]);
      this.staticHandlers = {};
      this.rackApplications = {};
      this.requestCount = 0;
      this.accessLog = this.configuration.getLogger("access");
      this.on("close", __bind(function() {
        var application, root, _ref2, _results;
        _ref2 = this.rackApplications;
        _results = [];
        for (root in _ref2) {
          application = _ref2[root];
          _results.push(application.quit());
        }
        return _results;
      }, this));
    }
    HttpServer.prototype.toJSON = function() {
      return {
        pid: process.pid,
        version: version,
        requestCount: this.requestCount
      };
    };
    HttpServer.prototype.logRequest = function(req, res, next) {
      this.accessLog.info("[" + req.socket.remoteAddress + "] " + req.method + " " + req.headers.host + " " + req.url);
      this.requestCount++;
      return next();
    };
    HttpServer.prototype.annotateRequest = function(req, res, next) {
      var host, _ref2;
      host = (_ref2 = req.headers.host) != null ? _ref2.replace(/(\.$)|(\.?:.*)/, "") : void 0;
      req.pow = {
        host: host
      };
      return next();
    };
    HttpServer.prototype.handlePowRequest = function(req, res, next) {
      if (req.pow.host !== "pow") {
        return next();
      }
      switch (req.url) {
        case "/config.json":
          res.writeHead(200);
          return res.end(JSON.stringify(this.configuration));
        case "/status.json":
          res.writeHead(200);
          return res.end(JSON.stringify(this));
        default:
          return this.handleLocationNotFound(req, res, next);
      }
    };
    HttpServer.prototype.findApplicationRoot = function(req, res, next) {
      var resume;
      resume = pause(req);
      return this.configuration.findApplicationRootForHost(req.pow.host, __bind(function(err, domain, root) {
        if (req.pow.root = root) {
          req.pow.domain = domain;
          req.pow.resume = resume;
        } else {
          resume();
        }
        return next(err);
      }, this));
    };
    HttpServer.prototype.handleStaticRequest = function(req, res, next) {
      var handler, root, _base, _ref2, _ref3;
      if ((_ref2 = req.method) !== "GET" && _ref2 !== "HEAD") {
        return next();
      }
      if (!(root = req.pow.root)) {
        return next();
      }
      if (req.url.match(/\.\./)) {
        return next();
      }
      handler = (_ref3 = (_base = this.staticHandlers)[root]) != null ? _ref3 : _base[root] = connect.static(join(root, "public"));
      return handler(req, res, next);
    };
    HttpServer.prototype.findRackApplication = function(req, res, next) {
      var root;
      if (!(root = req.pow.root)) {
        return next();
      }
      return exists(join(root, "config.ru"), __bind(function(rackConfigExists) {
        var application, _base, _ref2;
        if (rackConfigExists) {
          req.pow.application = (_ref2 = (_base = this.rackApplications)[root]) != null ? _ref2 : _base[root] = new RackApplication(this.configuration, root);
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
    HttpServer.prototype.handleFaviconRequest = function(req, res, next) {
      if (req.url !== "/favicon.ico") {
        return next();
      }
      res.writeHead(200);
      return res.end();
    };
    HttpServer.prototype.handleApplicationNotFound = function(req, res, next) {
      var domain, host, name, pattern, _ref2;
      if (req.pow.root) {
        return next();
      }
      host = req.pow.host;
      pattern = this.configuration.httpDomainPattern;
      if (!(domain = host != null ? (_ref2 = host.match(pattern)) != null ? _ref2[1] : void 0 : void 0)) {
        return next();
      }
      name = host.slice(0, host.length - domain.length);
      if (!name.length) {
        return next();
      }
      return renderResponse(res, 503, "application_not_found", {
        name: name,
        host: host
      });
    };
    HttpServer.prototype.handleWelcomeRequest = function(req, res, next) {
      var domain, domains;
      if (req.pow.root || req.url !== "/") {
        return next();
      }
      domains = this.configuration.domains;
      domain = __indexOf.call(domains, "dev") >= 0 ? "dev" : domains[0];
      return renderResponse(res, 200, "welcome", {
        version: version,
        domain: domain
      });
    };
    HttpServer.prototype.handleRailsAppWithoutRackupFile = function(req, res, next) {
      var root;
      if (!(root = req.pow.root)) {
        return next();
      }
      return exists(join(root, "config/environment.rb"), function(looksLikeRailsApp) {
        if (!looksLikeRailsApp) {
          return next();
        }
        return renderResponse(res, 503, "rackup_file_missing");
      });
    };
    HttpServer.prototype.handleLocationNotFound = function(req, res, next) {
      res.writeHead(404, {
        "Content-Type": "text/html"
      });
      return res.end("<!doctype html><html><body><h1>404 Not Found</h1>");
    };
    HttpServer.prototype.handleErrorStartingApplication = function(err, req, res, next) {
      var home, line, rest, root, stack, stackLines;
      if (!(root = req.pow.root)) {
        return next();
      }
      home = process.env.HOME;
      stackLines = (function() {
        var _i, _len, _ref2, _results;
        _ref2 = err.stack.split("\n");
        _results = [];
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          line = _ref2[_i];
          _results.push(line.slice(0, home.length) === home ? "~" + line.slice(home.length) : line);
        }
        return _results;
      })();
      if (stackLines.length > 10) {
        stack = stackLines.slice(0, 5);
        rest = stackLines.slice(5);
      } else {
        stack = stackLines;
      }
      return renderResponse(res, 500, "error_starting_application", {
        err: err,
        root: root,
        stack: stack,
        rest: rest
      });
    };
    return HttpServer;
  })();
}).call(this);
