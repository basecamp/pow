(function() {
  var RackApplication, async, basename, bufferLines, fs, join, nack, path, pause, sourceScriptEnv, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  path = require("path");
  fs = require("fs");
  nack = require("nack");
  _ref = require("./util"), bufferLines = _ref.bufferLines, pause = _ref.pause, sourceScriptEnv = _ref.sourceScriptEnv;
  _ref2 = require("path"), join = _ref2.join, basename = _ref2.basename;
  module.exports = RackApplication = (function() {
    var envFilenames, getEnvForRoot;
    function RackApplication(configuration, root) {
      this.configuration = configuration;
      this.root = root;
      this.logger = this.configuration.getLogger(join("apps", basename(this.root)));
      this.readyCallbacks = [];
    }
    envFilenames = [".powrc", ".powenv"];
    getEnvForRoot = function(root, callback) {
      return async.reduce(envFilenames, {}, function(env, filename, callback) {
        var script;
        return path.exists(script = join(root, filename), function(exists) {
          if (exists) {
            return sourceScriptEnv(script, env, callback);
          } else {
            return callback(null, env);
          }
        });
      }, callback);
    };
    RackApplication.prototype.initialize = function() {
      var createServer, installLogHandlers, processReadyCallbacks;
      if (this.state) {
        return;
      }
      this.state = "initializing";
      createServer = __bind(function() {
        return this.server = nack.createServer(join(this.root, "config.ru"), {
          env: this.env,
          size: this.configuration.workers,
          idle: this.configuration.timeout
        });
      }, this);
      processReadyCallbacks = __bind(function(err) {
        var readyCallback, _i, _len, _ref;
        _ref = this.readyCallbacks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          readyCallback = _ref[_i];
          readyCallback(err);
        }
        return this.readyCallbacks = [];
      }, this);
      installLogHandlers = __bind(function() {
        bufferLines(this.server.pool.stdout, __bind(function(line) {
          return this.logger.info(line);
        }, this));
        bufferLines(this.server.pool.stderr, __bind(function(line) {
          return this.logger.warning(line);
        }, this));
        this.server.pool.on("worker:spawn", __bind(function(process) {
          return this.logger.debug("nack worker " + process.child.pid + " spawned");
        }, this));
        return this.server.pool.on("worker:exit", __bind(function(process) {
          return this.logger.debug("nack worker exited");
        }, this));
      }, this);
      return getEnvForRoot(this.root, __bind(function(err, env) {
        this.env = env;
        if (err) {
          this.state = null;
          this.logger.error(err.message);
          this.logger.error("stdout: " + err.stdout);
          this.logger.error("stderr: " + err.stderr);
          return processReadyCallbacks(err);
        } else {
          createServer();
          installLogHandlers();
          this.state = "ready";
          return processReadyCallbacks();
        }
      }, this));
    };
    RackApplication.prototype.ready = function(callback) {
      if (this.state === "ready") {
        return callback();
      } else {
        this.readyCallbacks.push(callback);
        return this.initialize();
      }
    };
    RackApplication.prototype.handle = function(req, res, next, callback) {
      var resume;
      resume = pause(req);
      return this.ready(__bind(function(err) {
        if (err) {
          return next(err);
        }
        return this.restartIfNecessary(__bind(function() {
          req.proxyMetaVariables = {
            SERVER_PORT: this.configuration.dstPort.toString()
          };
          try {
            return this.server.handle(req, res, next);
          } finally {
            resume();
            if (typeof callback == "function") {
              callback();
            }
          }
        }, this));
      }, this));
    };
    RackApplication.prototype.quit = function(callback) {
      if (this.server) {
        if (callback) {
          this.server.pool.once("exit", callback);
        }
        return this.server.pool.quit();
      } else {
        return typeof callback == "function" ? callback() : void 0;
      }
    };
    RackApplication.prototype.restartIfNecessary = function(callback) {
      return fs.stat(join(this.root, "tmp/restart.txt"), __bind(function(err, stats) {
        if (!err && (stats != null ? stats.mtime : void 0) !== this.mtime) {
          this.quit(callback);
        } else {
          callback();
        }
        return this.mtime = stats != null ? stats.mtime : void 0;
      }, this));
    };
    return RackApplication;
  })();
}).call(this);
