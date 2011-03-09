(function() {
  var LineBuffer, RackHandler, async, basename, bufferLines, dirname, envFilenames, exec, fs, getEnvForRoot, join, nack, path, pause, sourceScriptEnv, _ref, _ref2;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  path = require("path");
  fs = require("fs");
  nack = require("nack");
  _ref = require("./util"), LineBuffer = _ref.LineBuffer, pause = _ref.pause;
  _ref2 = require("path"), join = _ref2.join, dirname = _ref2.dirname, basename = _ref2.basename;
  exec = require("child_process").exec;
  sourceScriptEnv = function(script, callback) {
    var command;
    command = "source '" + script + "' > /dev/null;\n" + process.execPath + " -e 'JSON.stringify(process.env)'";
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
  envFilenames = [".powrc", ".envrc"];
  getEnvForRoot = function(root, callback) {
    var filename, files;
    files = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = envFilenames.length; _i < _len; _i++) {
        filename = envFilenames[_i];
        _results.push(join(root, filename));
      }
      return _results;
    })();
    return async.detect(files, path.exists, function(filename) {
      if (filename) {
        return sourceScriptEnv(filename, callback);
      } else {
        return callback(null, {});
      }
    });
  };
  bufferLines = function(stream, callback) {
    var buffer;
    buffer = new LineBuffer(stream);
    buffer.on("data", callback);
    return buffer;
  };
  module.exports = RackHandler = (function() {
    function RackHandler(configuration, root, callback) {
      var createServer, installLogHandlers, processReadyCallbacks;
      this.configuration = configuration;
      this.root = root;
      this.logger = this.configuration.getLogger(join("apps", basename(this.root)));
      this.readyCallbacks = [];
      callback != null ? callback : callback = function(err) {
        if (err) {
          throw err;
        }
      };
      createServer = __bind(function() {
        return this.app = nack.createServer(join(this.root, "config.ru"), {
          env: this.env,
          size: this.configuration.workers
        });
      }, this);
      processReadyCallbacks = __bind(function() {
        var readyCallback, _i, _len, _ref;
        _ref = this.readyCallbacks;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          readyCallback = _ref[_i];
          readyCallback();
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
      getEnvForRoot(this.root, __bind(function(err, env) {
        this.env = env;
        if (err) {
          return callback(err);
        } else {
          createServer();
          installLogHandlers();
          callback(null, this);
          return processReadyCallbacks();
        }
      }, this));
    }
    RackHandler.prototype.ready = function(callback) {
      if (this.app) {
        return callback();
      } else {
        return this.readyCallbacks.push(callback);
      }
    };
    RackHandler.prototype.handle = function(req, res, next, callback) {
      var resume;
      resume = pause(req);
      return this.ready(__bind(function() {
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
      return fs.unlink(join(this.root, "tmp/restart.txt"), __bind(function(err) {
        if (err) {
          return callback();
        } else {
          return this.quit(callback);
        }
      }, this));
    };
    return RackHandler;
  })();
}).call(this);
