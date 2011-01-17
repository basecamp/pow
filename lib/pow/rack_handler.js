(function() {
  var RackHandler, dirname, fs, getEnvForRoot, join, nack, sourceScriptEnv, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require("fs");
  nack = require("nack");
  _ref = require("path"), join = _ref.join, dirname = _ref.dirname;
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
  getEnvForRoot = function(root, callback) {
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
  module.exports = RackHandler = (function() {
    function RackHandler(configuration, root, callback) {
      this.configuration = configuration;
      this.root = root;
      this.readyCallbacks = [];
      getEnvForRoot(this.root, __bind(function(err, env) {
        var readyCallback, _i, _len, _ref;
        this.env = env;
        if (err) {
          return typeof callback === "function" ? callback(err) : void 0;
        } else {
          this.app = nack.createServer(join(this.root, "config.ru"), this.env);
          callback(null, this);
          _ref = this.readyCallbacks;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            readyCallback = _ref[_i];
            readyCallback();
          }
          return this.readyCallbacks = [];
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
      return this.ready(__bind(function() {
        return this.restartIfNecessary(__bind(function() {
          req.proxyMetaVariables = {
            SERVER_PORT: this.configuration.dstPort.toString()
          };
          try {
            return this.app.handle(req, res, next);
          } finally {
            callback();
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
        return typeof callback === "function" ? callback() : void 0;
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
