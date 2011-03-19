(function() {
  var RackHandler, async, basename, bufferLines, dirname, envFilenames, exec, fs, getEnvForRoot, join, nack, path, pause, sourceScriptEnv, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  path = require("path");
  fs = require("fs");
  nack = require("nack");
  _ref = require("./util"), bufferLines = _ref.bufferLines, pause = _ref.pause;
  _ref2 = require("path"), join = _ref2.join, dirname = _ref2.dirname, basename = _ref2.basename;
  exec = require("child_process").exec;
  sourceScriptEnv = function(script, env, callback) {
    var command;
    command = "source '" + script + "' > /dev/null;\n'" + process.execPath + "' -e 'JSON.stringify(process.env)'";
    return exec(command, {
      cwd: dirname(script),
      env: env
    }, function(err, stdout, stderr) {
      if (err) {
        err.message = "'" + script + "' failed to load";
        err.stdout = stdout;
        err.stderr = stderr;
        callback(err);
      }
      try {
        return callback(null, JSON.parse(stdout));
      } catch (exception) {
        return callback(exception);
      }
    });
  };
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
  module.exports = RackHandler = (function() {
    function RackHandler(configuration, root) {
      this.configuration = configuration;
      this.root = root;
      this.logger = this.configuration.getLogger(join("apps", basename(this.root)));
      this.readyCallbacks = [];
    }
    RackHandler.prototype.initialize = function() {
      var createServer, installLogHandlers, processReadyCallbacks;
      if (this.state) {
        return;
      }
      this.state = "initializing";
      createServer = __bind(function() {
        return this.app = nack.createServer(join(this.root, "config.ru"), {
          env: this.env,
          size: this.configuration.workers
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
        bufferLines(this.app.pool.stdout, __bind(function(line) {
          return this.logger.info(line);
        }, this));
        bufferLines(this.app.pool.stderr, __bind(function(line) {
          return this.logger.warning(line);
        }, this));
        this.app.pool.on("worker:spawn", __bind(function(process) {
          return this.logger.debug("nack worker " + process.child.pid + " spawned");
        }, this));
        return this.app.pool.on("worker:exit", __bind(function(process) {
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
    RackHandler.prototype.ready = function(callback) {
      if (this.state === "ready") {
        return callback();
      } else {
        this.readyCallbacks.push(callback);
        return this.initialize();
      }
    };
    RackHandler.prototype.handle = function(req, res, next, callback) {
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
            return this.app.handle(req, res, next);
          } finally {
            resume();
            if (typeof callback == "function") {
              callback();
            }
          }
        }, this));
      }, this));
    };
    RackHandler.prototype.quit = function(callback) {
      if (this.app) {
        if (callback) {
          this.app.pool.once("exit", callback);
        }
        return this.app.pool.quit();
      } else {
        return typeof callback == "function" ? callback() : void 0;
      }
    };
    RackHandler.prototype.restartIfNecessary = function(callback) {
      return fs.stat(join(this.root, "tmp/restart.txt"), __bind(function(err, stats) {
        if (!err && (stats != null ? stats.mtime : void 0) !== this.mtime) {
          this.quit(callback);
        } else {
          callback();
        }
        return this.mtime = stats != null ? stats.mtime : void 0;
      }, this));
    };
    return RackHandler;
  })();
}).call(this);
