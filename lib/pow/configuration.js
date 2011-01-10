(function() {
  var Configuration, async, fs, getFilenamesForHost, join;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require("fs");
  join = require("path").join;
  async = require("async");
  getFilenamesForHost = function(host) {
    var i, length, parts, _results;
    parts = host.split(".");
    length = parts.length - 2;
    _results = [];
    for (i = 0; (0 <= length ? i <= length : i >= length); (0 <= length ? i += 1 : i -= 1)) {
      _results.push(parts.slice(i, length + 1).join("."));
    }
    return _results;
  };
  module.exports = Configuration = (function() {
    function Configuration(options) {
      var _ref, _ref2, _ref3, _ref4, _ref5;
      if (options == null) {
        options = {};
      }
      this.httpPort = (_ref = options.httpPort) != null ? _ref : 20559;
      this.dnsPort = (_ref2 = options.dnsPort) != null ? _ref2 : 20560;
      this.timeout = (_ref3 = options.timeout) != null ? _ref3 : 15 * 60 * 1000;
      this.domain = (_ref4 = options.domain) != null ? _ref4 : "test";
      this.root = (_ref5 = options.root) != null ? _ref5 : join(process.env.HOME, ".pow");
    }
    Configuration.prototype.findApplicationRootForHost = function(host, callback) {
      return this.gatherApplicationRoots(__bind(function(err, roots) {
        var file, root, _i, _len, _ref;
        if (err) {
          return callback(err);
        }
        _ref = getFilenamesForHost(host);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          if (root = roots[file]) {
            return callback(null, root);
          }
        }
        return callback(null);
      }, this));
    };
    Configuration.prototype.gatherApplicationRoots = function(callback) {
      var roots;
      roots = {};
      return fs.readdir(this.root, __bind(function(err, files) {
        if (err) {
          return callback(err);
        }
        return async.forEach(files, __bind(function(file, next) {
          var path;
          path = join(this.root, file);
          return fs.lstat(path, function(err, stats) {
            if (err) {
              return callback(err);
            }
            if (stats.isSymbolicLink()) {
              return fs.readlink(path, function(err, resolvedPath) {
                if (err) {
                  return callback(err);
                }
                roots[file] = resolvedPath;
                return next();
              });
            } else if (stats.isDirectory()) {
              roots[file] = path;
              return next();
            } else {
              return next();
            }
          });
        }, this), function(err) {
          return callback(err, roots);
        });
      }, this));
    };
    return Configuration;
  })();
}).call(this);
