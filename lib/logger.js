(function() {
  var Log, Logger, dirname, fs, level, mkdirp, _fn, _i, _len, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  fs = require("fs");
  dirname = require("path").dirname;
  Log = require("log");
  mkdirp = require("./util").mkdirp;
  module.exports = Logger = (function() {
    Logger.LEVELS = ["debug", "info", "notice", "warning", "error", "critical", "alert", "emergency"];
    function Logger(path, level) {
      this.path = path;
      this.level = level != null ? level : "debug";
      this.perform = __bind(this.perform, this);;
      this.pause();
    }
    Logger.prototype.pause = function() {
      return this.buffer || (this.buffer = []);
    };
    Logger.prototype.resume = function() {
      var args, level, _len, _ref, _ref2;
      if (!this.buffer) {
        return;
      }
      _ref = this.buffer;
      for (args = 0, _len = _ref.length; args < _len; args++) {
        level = _ref[args];
        (_ref2 = this.log)[level].apply(_ref2, args);
      }
      return this.buffer = null;
    };
    Logger.prototype.open = function(callback) {
      if (this.stream) {
        return callback.call(this);
      } else {
        return mkdirp(dirname(this.path), __bind(function(err) {
          if (err) {
            return;
          }
          this.stream = fs.createWriteStream(this.path, {
            flags: "a"
          });
          return this.stream.on("open", __bind(function() {
            this.log = new Log(this.level, this.stream);
            this.resume();
            return callback.call(this);
          }, this));
        }, this));
      }
    };
    Logger.prototype.perform = function() {
      var args, level;
      level = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      if (this.buffer) {
        return this.buffer.push([level, args]);
      } else {
        return this.log[level].apply(this.log, args);
      }
    };
    return Logger;
  })();
  _ref = Logger.LEVELS;
  _fn = function(level) {
    return Logger.prototype[level] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.open(function() {
        return this.perform(level, args);
      });
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    level = _ref[_i];
    _fn(level);
  }
}).call(this);
