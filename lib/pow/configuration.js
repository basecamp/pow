(function() {
  var Configuration, Finalizer, fs, join;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  join = require("path").join;
  fs = require("fs");
  Finalizer = (function() {
    Finalizer.from = function(finalizerOrCallback) {
      if (finalizerOrCallback instanceof Finalizer) {
        return finalizerOrCallback;
      } else {
        return new Finalizer(finalizerOrCallback != null ? finalizerOrCallback : function() {});
      }
    };
    function Finalizer(callback) {
      this.callback = callback;
      this.count = 0;
      this.done = false;
    }
    Finalizer.prototype.increment = function() {
      if (this.done) {
        return;
      }
      return this.count += 1;
    };
    Finalizer.prototype.decrement = function() {
      if (this.done) {
        return;
      }
      if ((this.count -= 1) <= 0) {
        this.done = true;
        return this.callback();
      }
    };
    return Finalizer;
  })();
  exports.Configuration = Configuration = (function() {
    function Configuration(root) {
      this.root = root;
    }
    Configuration.prototype.findPathForHost = function(host, callback) {
      return this.gather(__bind(function(paths) {
        var filename, path, _i, _len, _ref;
        _ref = this.getFilenamesForHost(host);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          filename = _ref[_i];
          if (path = paths[filename]) {
            return callback(path);
          }
        }
        return callback(false);
      }, this));
    };
    Configuration.prototype.gather = function(callback) {
      var finalizer, paths;
      paths = {};
      finalizer = new Finalizer(function() {
        return callback(paths);
      });
      finalizer.increment();
      return fs.readdir(this.root, __bind(function(err, filenames) {
        var filename, _fn, _i, _len;
        if (err) {
          throw err;
        }
        _fn = __bind(function(filename) {
          var path;
          finalizer.increment();
          path = join(this.root, filename);
          return fs.lstat(path, function(err, stats) {
            if (err) {
              throw err;
            }
            if (stats.isSymbolicLink()) {
              finalizer.increment();
              fs.readlink(path, function(err, resolvedPath) {
                paths[filename] = join(resolvedPath, "config.ru");
                return finalizer.decrement();
              });
            }
            return finalizer.decrement();
          });
        }, this);
        for (_i = 0, _len = filenames.length; _i < _len; _i++) {
          filename = filenames[_i];
          _fn(filename);
        }
        return finalizer.decrement();
      }, this));
    };
    Configuration.prototype.getFilenamesForHost = function(host) {
      var i, length, parts, _results;
      parts = host.split(".");
      length = parts.length - 2;
      _results = [];
      for (i = 0; (0 <= length ? i <= length : i >= length); (0 <= length ? i += 1 : i -= 1)) {
        _results.push(parts.slice(i, length + 1).join("."));
      }
      return _results;
    };
    return Configuration;
  })();
}).call(this);
