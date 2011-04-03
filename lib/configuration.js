(function() {
  var Configuration, Logger, async, fs, getFilenamesForHost, libraryPath, mkdirp, path;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  fs = require("fs");
  path = require("path");
  async = require("async");
  Logger = require("./logger");
  mkdirp = require("./util").mkdirp;
  module.exports = Configuration = (function() {
    function Configuration(options) {
      var _ref, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      if (options == null) {
        options = {};
      }
      this.dstPort = (_ref = options.dstPort) != null ? _ref : 80;
      this.httpPort = (_ref2 = options.httpPort) != null ? _ref2 : 20559;
      this.dnsPort = (_ref3 = options.dnsPort) != null ? _ref3 : 20560;
      this.timeout = (_ref4 = options.timeout) != null ? _ref4 : 15 * 60 * 1000;
      this.workers = (_ref5 = options.workers) != null ? _ref5 : 2;
      this.domains = (_ref6 = options.domains) != null ? _ref6 : ["test", "dev"];
      this.hostRoot = (_ref7 = options.hostRoot) != null ? _ref7 : libraryPath("Application Support", "Pow", "Hosts");
      this.logRoot = (_ref8 = options.logRoot) != null ? _ref8 : libraryPath("Logs", "Pow");
      this.rvmPath = (_ref9 = options.rvmPath) != null ? _ref9 : path.join(process.env.HOME, ".rvm/scripts/rvm");
      this.loggers = {};
    }
    Configuration.prototype.getLogger = function(name) {
      var _base;
      return (_base = this.loggers)[name] || (_base[name] = new Logger(path.join(this.logRoot, name + ".log")));
    };
    Configuration.prototype.findApplicationRootForHost = function(host, callback) {
      return this.gatherApplicationRoots(__bind(function(err, roots) {
        var domain, file, root, _i, _j, _len, _len2, _ref, _ref2;
        if (err) {
          return callback(err);
        }
        _ref = this.domains;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          domain = _ref[_i];
          _ref2 = getFilenamesForHost(host, domain);
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            file = _ref2[_j];
            if (root = roots[file]) {
              return callback(null, domain, root);
            }
          }
        }
        return callback(null);
      }, this));
    };
    Configuration.prototype.gatherApplicationRoots = function(callback) {
      var roots;
      roots = {};
      return mkdirp(this.hostRoot, __bind(function(err) {
        if (err) {
          return callback(err);
        }
        return fs.readdir(this.hostRoot, __bind(function(err, files) {
          if (err) {
            return callback(err);
          }
          return async.forEach(files, __bind(function(file, next) {
            var root;
            root = path.join(this.hostRoot, file);
            return fs.lstat(root, function(err, stats) {
              if (stats != null ? stats.isSymbolicLink() : void 0) {
                return fs.realpath(root, function(err, resolvedPath) {
                  if (err) {
                    return next();
                  } else {
                    return fs.lstat(resolvedPath, function(err, stats) {
                      if (stats != null ? stats.isDirectory() : void 0) {
                        roots[file] = resolvedPath;
                      }
                      return next();
                    });
                  }
                });
              } else if (stats != null ? stats.isDirectory() : void 0) {
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
  libraryPath = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return path.join.apply(path, [process.env.HOME, "Library"].concat(__slice.call(args)));
  };
  getFilenamesForHost = function(host, domain) {
    var i, length, parts, _results;
    if (host.slice(-domain.length - 1) === ("." + domain)) {
      parts = host.slice(0, -domain.length - 1).split(".");
      length = parts.length;
      _results = [];
      for (i = 0; (0 <= length ? i < length : i > length); (0 <= length ? i += 1 : i -= 1)) {
        _results.push(parts.slice(i, length).join("."));
      }
      return _results;
    } else {
      return [];
    }
  };
}).call(this);
