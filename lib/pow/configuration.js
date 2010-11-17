(function() {
  var Configuration, Finalizer, _ref, fs, join;
  var __bind = function(func, context) {
    return function(){ return func.apply(context, arguments); };
  };
  _ref = require("path");
  join = _ref.join;
  fs = require("fs");
  Finalizer = function(callback) {
    this.callback = callback;
    this.count = 0;
    this.done = false;
    return this;
  };
  Finalizer.from = function(finalizerOrCallback) {
    return finalizerOrCallback instanceof Finalizer ? finalizerOrCallback : new Finalizer((typeof finalizerOrCallback !== "undefined" && finalizerOrCallback !== null) ? finalizerOrCallback : function() {});
  };
  Finalizer.prototype.increment = function() {
    if (this.done) {
      return null;
    }
    return this.count += 1;
  };
  Finalizer.prototype.decrement = function() {
    if (this.done) {
      return null;
    }
    if ((this.count -= 1) <= 0) {
      this.done = true;
      return this.callback();
    }
  };
  exports.Configuration = (function() {
    Configuration = function(root) {
      this.root = root;
      return this;
    };
    Configuration.prototype.findPathForHost = function(host, callback) {
      return this.gather(__bind(function(paths) {
        var _i, _len, _ref2, filename, path;
        _ref2 = this.getFilenamesForHost(host);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          filename = _ref2[_i];
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
        var _i, _len, _ref2;
        if (err) {
          throw err;
        }
        _ref2 = filenames;
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          (function() {
            var path;
            var filename = _ref2[_i];
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
          }).call(this);
        }
        return finalizer.decrement();
      }, this));
    };
    Configuration.prototype.getFilenamesForHost = function(host) {
      var _result, i, length, parts;
      parts = host.split(".");
      length = parts.length - 2;
      _result = [];
      for (i = 0; (0 <= length ? i <= length : i >= length); (0 <= length ? i += 1 : i -= 1)) {
        _result.push(parts.slice(i, length + 1).join("."));
      }
      return _result;
    };
    return Configuration;
  })();
}).call(this);
