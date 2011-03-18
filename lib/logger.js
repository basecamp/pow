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
      this.readyCallbacks = [];
    }
    Logger.prototype.ready = function(callback) {
      if (this.state === "ready") {
        return callback.call(this);
      } else {
        this.readyCallbacks.push(callback);
        if (!this.state) {
          this.state = "initializing";
          return mkdirp(dirname(this.path), __bind(function(err) {
            if (err) {
              return this.state = null;
            } else {
              this.stream = fs.createWriteStream(this.path, {
                flags: "a"
              });
              return this.stream.on("open", __bind(function() {
                var callback, _i, _len, _ref;
                this.log = new Log(this.level, this.stream);
                this.state = "ready";
                _ref = this.readyCallbacks;
                for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                  callback = _ref[_i];
                  callback.call(this);
                }
                return this.readyCallbacks = [];
              }, this));
            }
          }, this));
        }
      }
    };
    return Logger;
  })();
  _ref = Logger.LEVELS;
  _fn = function(level) {
    return Logger.prototype[level] = function() {
      var args;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.ready(function() {
        return this.log[level].apply(this.log, args);
      });
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    level = _ref[_i];
    _fn(level);
  }
}).call(this);
