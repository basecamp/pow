(function() {
  var Log, Logger, dirname, fs, method, mkdirp, _fn, _i, _len, _ref;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require("fs");
  dirname = require("path").dirname;
  Log = require("log");
  mkdirp = require("./util").mkdirp;
  module.exports = Logger = (function() {
    Logger.LEVELS = ["debug", "info", "notice", "warning", "error", "critical", "alert", "emergency"];
    function Logger(path, level) {
      this.path = path;
      this.level = level != null ? level : "debug";
      this.pause();
      mkdirp(dirname(this.path), __bind(function(err) {
        if (err) {
          return;
        }
        this.stream = fs.createWriteStream(this.path, {
          flags: "a"
        });
        return this.stream.on("open", __bind(function() {
          this.log = new Log(this.level, this.stream);
          return this.resume();
        }, this));
      }, this));
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
    return Logger;
  })();
  _ref = Logger.LEVELS;
  _fn = function(method) {
    return Logger.prototype[method] = function() {
      if (this.buffer) {
        return this.buffer.push([method, arguments]);
      } else {
        return this.log[method].apply(this.log, arguments);
      }
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    method = _ref[_i];
    _fn(method);
  }
}).call(this);
