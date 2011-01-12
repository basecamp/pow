(function() {
  var HttpServer, connect, dirname, escapeHTML, exec, fs, getHost, join, nack, o, pause, sourceScriptEnv, sys, x, _ref;
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
  exec = require("child_process").exec;
  connect = require("connect");
  nack = require("nack");
  pause = require("nack/util").pause;
  _ref = require("path"), dirname = _ref.dirname, join = _ref.join;
  getHost = function(req) {
    return req.headers.host.replace(/:.*/, "");
  };
  escapeHTML = function(string) {
    return string.toString().replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\"/g, "&quot;");
  };
  sourceScriptEnv = function(script, callback) {
    var command;
    command = "source " + script + " > /dev/null;\n" + process.execPath + " -e 'JSON.stringify(process.env)'";
    return exec(command, {
      cwd: dirname(script)
    }, function(err, stdout) {
      if (err) {
        return callback(err);
      }
      try {
        return callback(null, JSON.parse(stdout));
      } catch (exception) {
        return callback(exception);
      }
    });
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
    __extends(HttpServer, connect.Server);
    function HttpServer(configuration) {
      this.configuration = configuration;
      this.handleNonexistentDomain = __bind(this.handleNonexistentDomain, this);;
      this.handleApplicationException = __bind(this.handleApplicationException, this);;
      this.handleRequest = __bind(this.handleRequest, this);;
      this.closeApplications = __bind(this.closeApplications, this);;
      HttpServer.__super__.constructor.call(this, [o(this.handleRequest), x(this.handleApplicationException), o(this.handleNonexistentDomain)]);
      this.handlers = {};
      this.on("close", this.closeApplications);
    }
    HttpServer.prototype.getHandlerForHost = function(host, callback) {
      return this.configuration.findApplicationRootForHost(host, __bind(function(err, root) {
        if (err) {
          return callback(err);
        }
        return this.getHandlerForRoot(root, callback);
      }, this));
    };
    HttpServer.prototype.getHandlerForRoot = function(root, callback) {
      var handler;
      if (!root) {
        return;
      }
      if (handler = this.handlers[root]) {
        return callback(null, handler);
      } else {
        return this.getEnvForRoot(root, __bind(function(err, env) {
          if (err) {
            return callback(err);
          }
          return callback(null, this.handlers[root] = {
            root: root,
            app: this.createApplication(join(root, "config.ru"), env),
            env: env
          });
        }, this));
      }
    };
    HttpServer.prototype.getEnvForRoot = function(root, callback) {
      var path;
      path = join(root, ".powrc");
      return fs.stat(path, function(err) {
        if (err) {
          return callback(null, {});
        } else {
          return sourceScriptEnv(path, callback);
        }
      });
    };
    HttpServer.prototype.createApplication = function(configurationPath, env) {
      var app;
      app = nack.createServer(configurationPath, {
        idle: this.configuration.timeout,
        env: env
      });
      sys.pump(app.pool.stdout, process.stdout);
      sys.pump(app.pool.stderr, process.stdout);
      return app;
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
    HttpServer.prototype.handleRequest = function(req, res, next) {
      var host, resume;
      host = getHost(req);
      resume = pause(req);
      req.pow = {
        host: host
      };
      return this.getHandlerForHost(host, __bind(function(err, handler) {
        req.pow.handler = handler;
        if (handler && !err) {
          return this.restartIfNecessary(handler, __bind(function() {
            req.proxyMetaVariables = {
              SERVER_PORT: this.configuration.dstPort.toString()
            };
            try {
              return handler.app.handle(req, res, next);
            } finally {
              resume();
            }
          }, this));
        } else {
          next(err);
          return resume();
        }
      }, this));
    };
    HttpServer.prototype.restartIfNecessary = function(_arg, callback) {
      var app, root;
      root = _arg.root, app = _arg.app;
      return fs.unlink(join(root, "tmp/restart.txt"), function(err) {
        if (err) {
          return callback();
        } else {
          app.pool.once("exit", callback);
          return app.pool.quit();
        }
      });
    };
    HttpServer.prototype.handleApplicationException = function(err, req, res, next) {
      var _ref;
      if (!((_ref = req.pow) != null ? _ref.handler : void 0)) {
        return next();
      }
      res.writeHead(500, "Content-Type", "text/html; charset=utf8");
      return res.end("<!doctype html>\n<html>\n<head>\n  <title>Pow: Error Starting Application</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n    }\n    h1, h2, pre {\n      margin: 0;\n      padding: 15px 30px;\n    }\n    h1, h2 {\n      font-family: Helvetica, sans-serif;\n    }\n    h1 {\n      font-size: 36px;\n      background: #eeedea;\n      color: #c00;\n      border-bottom: 1px solid #999090;\n    }\n    h2 {\n      font-size: 18px;\n      font-weight: normal;\n    }\n  </style>\n</head>\n<body>\n  <h1>Pow can&rsquo;t start your application.</h1>\n  <h2><code>" + (escapeHTML(req.pow.handler.root)) + "</code> raised an exception during boot.</h2>\n  <pre><strong>" + (escapeHTML(err)) + "</strong>" + (escapeHTML("\n" + err.stack)) + "</pre>\n</body>\n</html>");
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
        "Content-Type": "text/html; charset=utf8"
      });
      return res.end("<!doctype html>\n<html>\n<head>\n  <title>Pow: No Such Application</title>\n  <style>\n    body {\n      margin: 0;\n      padding: 0;\n    }\n    h1, h2 {\n      margin: 0;\n      padding: 15px 30px;\n      font-family: Helvetica, sans-serif;\n    }\n    h1 {\n      font-size: 36px;\n      background: #eeedea;\n      color: #000;\n      border-bottom: 1px solid #999090;\n    }\n    h2 {\n      font-size: 18px;\n      font-weight: normal;\n    }\n  </style>\n</head>\n<body>\n  <h1>This domain isn&rsquo;t set up yet.</h1>\n  <h2>Symlink your application to <code>" + (escapeHTML(path)) + "</code> first.</h2>\n</body>\n</html>");
    };
    return HttpServer;
  })();
}).call(this);
