(function() {
  var RackApplication, async, basename, bufferLines, exists, fs, join, nack, pause, sourceScriptEnv, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  fs = require("fs");
  nack = require("nack");
  _ref = require("./util"), bufferLines = _ref.bufferLines, pause = _ref.pause, sourceScriptEnv = _ref.sourceScriptEnv;
  _ref2 = require("path"), join = _ref2.join, exists = _ref2.exists, basename = _ref2.basename;
  module.exports = RackApplication = (function() {
    function RackApplication(configuration, root) {
      this.configuration = configuration;
      this.root = root;
      this.logger = this.configuration.getLogger(join("apps", basename(this.root)));
      this.readyCallbacks = [];
      this.quitCallbacks = [];
      this.statCallbacks = [];
    }
    RackApplication.prototype.ready = function(callback) {
      if (this.state === "ready") {
        return callback();
      } else {
        this.readyCallbacks.push(callback);
        return this.initialize();
      }
    };
    RackApplication.prototype.quit = function(callback) {
      if (this.state) {
        if (callback) {
          this.quitCallbacks.push(callback);
        }
        return this.terminate();
      } else {
        return typeof callback === "function" ? callback() : void 0;
      }
    };
    RackApplication.prototype.queryRestartFile = function(callback) {
      return fs.stat(join(this.root, "tmp/restart.txt"), __bind(function(err, stats) {
        var lastMtime;
        if (err) {
          this.mtime = null;
          return callback(false);
        } else {
          lastMtime = this.mtime;
          this.mtime = stats.mtime.getTime();
          return callback(lastMtime !== this.mtime);
        }
      }, this));
    };
    RackApplication.prototype.setPoolRunOnceFlag = function(callback) {
      if (!this.statCallbacks.length) {
        exists(join(this.root, "tmp/always_restart.txt"), __bind(function(alwaysRestart) {
          var statCallback, _i, _len, _ref3;
          this.pool.runOnce = alwaysRestart;
          _ref3 = this.statCallbacks;
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            statCallback = _ref3[_i];
            statCallback();
          }
          return this.statCallbacks = [];
        }, this));
      }
      return this.statCallbacks.push(callback);
    };
    RackApplication.prototype.loadScriptEnvironment = function(env, callback) {
      return async.reduce([".powrc", ".envrc", ".powenv"], env, __bind(function(env, filename, callback) {
        var script;
        return exists(script = join(this.root, filename), function(scriptExists) {
          if (scriptExists) {
            return sourceScriptEnv(script, env, callback);
          } else {
            return callback(null, env);
          }
        });
      }, this), callback);
    };
    RackApplication.prototype.loadRvmEnvironment = function(env, callback) {
      var script;
      return exists(script = join(this.root, ".rvmrc"), __bind(function(rvmrcExists) {
        var rvm;
        if (rvmrcExists) {
          return exists(rvm = this.configuration.rvmPath, function(rvmExists) {
            var before;
            if (rvmExists) {
              before = "source '" + rvm + "' > /dev/null";
              return sourceScriptEnv(script, env, {
                before: before
              }, callback);
            } else {
              return callback(null, env);
            }
          });
        } else {
          return callback(null, env);
        }
      }, this));
    };
    RackApplication.prototype.loadEnvironment = function(callback) {
      return this.queryRestartFile(__bind(function() {
        return this.loadScriptEnvironment(null, __bind(function(err, env) {
          if (err) {
            return callback(err);
          } else {
            return this.loadRvmEnvironment(env, __bind(function(err, env) {
              if (err) {
                return callback(err);
              } else {
                return callback(null, env);
              }
            }, this));
          }
        }, this));
      }, this));
    };
    RackApplication.prototype.initialize = function() {
      if (this.state) {
        if (this.state === "terminating") {
          this.quit(__bind(function() {
            return this.initialize();
          }, this));
        }
        return;
      }
      this.state = "initializing";
      return this.loadEnvironment(__bind(function(err, env) {
        var readyCallback, _i, _len, _ref3, _ref4, _ref5;
        if (err) {
          this.state = null;
          this.logger.error(err.message);
          this.logger.error("stdout: " + err.stdout);
          this.logger.error("stderr: " + err.stderr);
        } else {
          this.state = "ready";
          this.pool = nack.createPool(join(this.root, "config.ru"), {
            env: env,
            size: (_ref3 = env != null ? env.POW_WORKERS : void 0) != null ? _ref3 : this.configuration.workers,
            idle: ((_ref4 = env != null ? env.POW_TIMEOUT : void 0) != null ? _ref4 : this.configuration.timeout) * 1000
          });
          bufferLines(this.pool.stdout, __bind(function(line) {
            return this.logger.info(line);
          }, this));
          bufferLines(this.pool.stderr, __bind(function(line) {
            return this.logger.warning(line);
          }, this));
          this.pool.on("worker:spawn", __bind(function(process) {
            return this.logger.debug("nack worker " + process.child.pid + " spawned");
          }, this));
          this.pool.on("worker:exit", __bind(function(process) {
            return this.logger.debug("nack worker exited");
          }, this));
        }
        _ref5 = this.readyCallbacks;
        for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
          readyCallback = _ref5[_i];
          readyCallback(err);
        }
        return this.readyCallbacks = [];
      }, this));
    };
    RackApplication.prototype.terminate = function() {
      if (this.state === "initializing") {
        return this.ready(__bind(function() {
          return this.terminate();
        }, this));
      } else if (this.state === "ready") {
        this.state = "terminating";
        return this.pool.quit(__bind(function() {
          var quitCallback, _i, _len, _ref3;
          this.state = null;
          this.mtime = null;
          this.pool = null;
          _ref3 = this.quitCallbacks;
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            quitCallback = _ref3[_i];
            quitCallback();
          }
          return this.quitCallbacks = [];
        }, this));
      }
    };
    RackApplication.prototype.handle = function(req, res, next, callback) {
      var resume;
      resume = pause(req);
      return this.ready(__bind(function(err) {
        if (err) {
          return next(err);
        }
        return this.setPoolRunOnceFlag(__bind(function() {
          return this.restartIfNecessary(__bind(function() {
            req.proxyMetaVariables = {
              SERVER_PORT: this.configuration.dstPort.toString()
            };
            try {
              return this.pool.proxy(req, res, __bind(function(err) {
                if (err) {
                  this.quit();
                }
                return next(err);
              }, this));
            } finally {
              resume();
              if (typeof callback === "function") {
                callback();
              }
            }
          }, this));
        }, this));
      }, this));
    };
    RackApplication.prototype.restart = function(callback) {
      return this.quit(__bind(function() {
        return this.ready(callback);
      }, this));
    };
    RackApplication.prototype.restartIfNecessary = function(callback) {
      return this.queryRestartFile(__bind(function(mtimeChanged) {
        if (mtimeChanged) {
          return this.restart(callback);
        } else {
          return callback();
        }
      }, this));
    };
    return RackApplication;
  })();
}).call(this);
