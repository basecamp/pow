(function() {
  var Configuration, Logger, async, fs, getFilenamesForHost, mkdirp, path;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  fs = require("fs");
  path = require("path");
  async = require("async");
  Logger = require("./logger");
  mkdirp = require("./util").mkdirp;
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
      var _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
      if (options == null) {
        options = {};
      }
      this.dstPort = (_ref = options.dstPort) != null ? _ref : 80;
      this.httpPort = (_ref2 = options.httpPort) != null ? _ref2 : 20559;
      this.dnsPort = (_ref3 = options.dnsPort) != null ? _ref3 : 20560;
      this.timeout = (_ref4 = options.timeout) != null ? _ref4 : 15 * 60 * 1000;
      this.domain = (_ref5 = options.domain) != null ? _ref5 : "test";
      this.root = (_ref6 = options.root) != null ? _ref6 : path.join(process.env.HOME, ".pow");
      this.logRoot = (_ref7 = options.logRoot) != null ? _ref7 : path.join(this.root, ".log");
      this.loggers = {};
    }
    Configuration.prototype.getLogger = function(name) {
      var _base;
      return (_base = this.loggers)[name] || (_base[name] = new Logger(path.join(this.logRoot, name + ".log")));
    };
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
      return mkdirp(this.root, __bind(function(err) {
        if (err) {
          return callback(err);
        }
        return fs.readdir(this.root, __bind(function(err, files) {
          if (err) {
            return callback(err);
          }
          return async.forEach(files, __bind(function(file, next) {
            var root;
            root = path.join(this.root, file);
            return fs.lstat(root, function(err, stats) {
              if (err) {
                return callback(err);
              }
              if (stats.isSymbolicLink()) {
                return fs.readlink(root, function(err, resolvedPath) {
                  if (err) {
                    return callback(err);
                  }
                  roots[file] = resolvedPath;
                  return next();
                });
              } else if (stats.isDirectory()) {
                roots[file] = root;
                return next();
              } else {
                return next();
              }
            });
          }, this), function(err) {
            return callback(err, roots);
          });
        }, this));
      }, this));
    };
    return Configuration;
  })();
}).call(this);
