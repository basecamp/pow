(function() {
  var Configuration, Logger, async, fs, getFilenamesForHost, libraryPath, mkdirp, path, sourceScriptEnv;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  fs = require("fs");
  path = require("path");
  async = require("async");
  Logger = require("./logger");
  mkdirp = require("./util").mkdirp;
  sourceScriptEnv = require("./util").sourceScriptEnv;
  module.exports = Configuration = (function() {
    Configuration.userConfigurationPath = path.join(process.env['HOME'], ".powconfig");
    Configuration.loadUserConfigurationEnvironment = function(callback) {
      var p;
      return path.exists(p = this.userConfigurationPath, function(exists) {
        if (exists) {
          return sourceScriptEnv(p, {}, callback);
        } else {
          return callback(null, {});
        }
      });
    };
    Configuration.getUserConfiguration = function(callback) {
      return this.loadUserConfigurationEnvironment(function(err, env) {
        var key, value;
        if (err) {
          return callback(err);
        } else {
          for (key in env) {
            value = env[key];
            process.env[key] = value;
          }
          return callback(null, new Configuration);
        }
      });
    };
    function Configuration(options) {
      var domain, _ref, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      if (options == null) {
        options = {};
      }
      this.bin = (_ref = (_ref2 = options.bin) != null ? _ref2 : process.env['POW_BIN']) != null ? _ref : path.join(__dirname, "../bin/pow");
      this.dstPort = (_ref3 = (_ref4 = options.dstPort) != null ? _ref4 : process.env['POW_DST_PORT']) != null ? _ref3 : 80;
      this.httpPort = (_ref5 = (_ref6 = options.httpPort) != null ? _ref6 : process.env['POW_HTTP_PORT']) != null ? _ref5 : 20559;
      this.dnsPort = (_ref7 = (_ref8 = options.dnsPort) != null ? _ref8 : process.env['POW_DNS_PORT']) != null ? _ref7 : 20560;
      this.timeout = (_ref9 = (_ref10 = options.timeout) != null ? _ref10 : process.env['POW_TIMEOUT']) != null ? _ref9 : 15 * 60 * 1000;
      this.workers = (_ref11 = (_ref12 = options.workers) != null ? _ref12 : process.env['POW_WORKERS']) != null ? _ref11 : 2;
      domain = (_ref13 = (_ref14 = options.domain) != null ? _ref14 : process.env['POW_DOMAIN']) != null ? _ref13 : "dev";
      this.domains = (_ref15 = (_ref16 = options.domains) != null ? _ref16 : process.env['POW_DOMAINS']) != null ? _ref15 : domain;
      this.domains = this.domains.split ? this.domains.split(",") : this.domains;
      this.hostRoot = (_ref17 = (_ref18 = options.hostRoot) != null ? _ref18 : process.env['POW_HOST_ROOT']) != null ? _ref17 : libraryPath("Application Support", "Pow", "Hosts");
      this.logRoot = (_ref19 = (_ref20 = options.logRoot) != null ? _ref20 : process.env['POW_LOG_ROOT']) != null ? _ref19 : libraryPath("Logs", "Pow");
      this.rvmPath = (_ref21 = (_ref22 = options.rvmPath) != null ? _ref22 : process.env['POW_RVM_PATH']) != null ? _ref21 : path.join(process.env.HOME, ".rvm/scripts/rvm");
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
