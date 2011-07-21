(function() {
  var Configuration, Logger, async, compilePattern, env, fs, getFilenamesForHost, libraryPath, mkdirp, path, sourceScriptEnv;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  fs = require("fs");
  path = require("path");
  async = require("async");
  Logger = require("./logger");
  mkdirp = require("./util").mkdirp;
  sourceScriptEnv = require("./util").sourceScriptEnv;
  env = process.env;
  module.exports = Configuration = (function() {
    Configuration.userConfigurationPath = path.join(env.HOME, ".powconfig");
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
    Configuration.optionNames = ["bin", "dstPort", "httpPort", "dnsPort", "timeout", "workers", "domains", "extDomains", "hostRoot", "logRoot", "rvmPath"];
    function Configuration(options) {
      var _base, _base2, _ref, _ref10, _ref11, _ref12, _ref13, _ref14, _ref15, _ref16, _ref17, _ref18, _ref19, _ref2, _ref20, _ref21, _ref22, _ref23, _ref24, _ref25, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
      if (options == null) {
        options = {};
      }
      this.bin = (_ref = (_ref2 = options.bin) != null ? _ref2 : env.POW_BIN) != null ? _ref : path.join(__dirname, "../bin/pow");
      this.dstPort = (_ref3 = (_ref4 = options.dstPort) != null ? _ref4 : env.POW_DST_PORT) != null ? _ref3 : 80;
      this.httpPort = (_ref5 = (_ref6 = options.httpPort) != null ? _ref6 : env.POW_HTTP_PORT) != null ? _ref5 : 20559;
      this.dnsPort = (_ref7 = (_ref8 = options.dnsPort) != null ? _ref8 : env.POW_DNS_PORT) != null ? _ref7 : 20560;
      this.timeout = (_ref9 = (_ref10 = options.timeout) != null ? _ref10 : env.POW_TIMEOUT) != null ? _ref9 : 15 * 60;
      this.workers = (_ref11 = (_ref12 = options.workers) != null ? _ref12 : env.POW_WORKERS) != null ? _ref11 : 2;
      this.domains = (_ref13 = (_ref14 = (_ref15 = options.domains) != null ? _ref15 : env.POW_DOMAINS) != null ? _ref14 : env.POW_DOMAIN) != null ? _ref13 : "dev";
      this.extDomains = (_ref16 = (_ref17 = options.extDomains) != null ? _ref17 : env.POW_EXT_DOMAINS) != null ? _ref16 : [];
      this.domains = (_ref18 = typeof (_base = this.domains).split === "function" ? _base.split(",") : void 0) != null ? _ref18 : this.domains;
      this.extDomains = (_ref19 = typeof (_base2 = this.extDomains).split === "function" ? _base2.split(",") : void 0) != null ? _ref19 : this.extDomains;
      this.allDomains = this.domains.concat(this.extDomains);
      this.hostRoot = (_ref20 = (_ref21 = options.hostRoot) != null ? _ref21 : env.POW_HOST_ROOT) != null ? _ref20 : libraryPath("Application Support", "Pow", "Hosts");
      this.logRoot = (_ref22 = (_ref23 = options.logRoot) != null ? _ref23 : env.POW_LOG_ROOT) != null ? _ref22 : libraryPath("Logs", "Pow");
      this.rvmPath = (_ref24 = (_ref25 = options.rvmPath) != null ? _ref25 : env.POW_RVM_PATH) != null ? _ref24 : path.join(env.HOME, ".rvm/scripts/rvm");
      this.loggers = {};
      this.dnsDomainPattern = compilePattern(this.domains);
      this.httpDomainPattern = compilePattern(this.allDomains);
    }
    Configuration.prototype.toJSON = function() {
      var key, result, _i, _len, _ref;
      result = {};
      _ref = this.constructor.optionNames;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        result[key] = this[key];
      }
      return result;
    };
    Configuration.prototype.getLogger = function(name) {
      var _base;
      return (_base = this.loggers)[name] || (_base[name] = new Logger(path.join(this.logRoot, name + ".log")));
    };
    Configuration.prototype.findApplicationRootForHost = function(host, callback) {
      if (host == null) {
        host = "";
      }
      return this.gatherApplicationRoots(__bind(function(err, roots) {
        var domain, file, root, _i, _j, _len, _len2, _ref, _ref2;
        if (err) {
          return callback(err);
        }
        _ref = this.allDomains;
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
        if (root = roots["default"]) {
          return callback(null, this.allDomains[0], root);
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
            var checkStats, name, root;
            root = path.join(this.hostRoot, file);
            name = file.toLowerCase();
            checkStats = function(path) {
              return fs.lstat(path, function(err, stats) {
                if (stats != null ? stats.isSymbolicLink() : void 0) {
                  return fs.realpath(path, function(err, resolvedPath) {
                    if (err) {
                      return next();
                    } else {
                      return checkStats(resolvedPath);
                    }
                  });
                } else if (stats != null ? stats.isDirectory() : void 0) {
                  roots[name] = path;
                  return next();
                } else if ((stats != null ? stats.isFile() : void 0) && stats.size < 10) {
                  return fs.readFile(path, 'utf-8', function(err, data) {
                    var port;
                    if (err) {
                      return next();
                    }
                    port = parseInt(data.trim());
                    if (!isNaN(port)) {
                      roots[name] = port;
                    }
                    return next();
                  });
                } else {
                  return next();
                }
              });
            };
            return checkStats(root);
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
    return path.join.apply(path, [env.HOME, "Library"].concat(__slice.call(args)));
  };
  getFilenamesForHost = function(host, domain) {
    var i, length, parts, _results;
    host = host.toLowerCase();
    if (host.slice(-domain.length - 1) === ("." + domain)) {
      parts = host.slice(0, -domain.length - 1).split(".");
      length = parts.length;
      _results = [];
      for (i = 0; 0 <= length ? i < length : i > length; 0 <= length ? i++ : i--) {
        _results.push(parts.slice(i, length).join("."));
      }
      return _results;
    } else {
      return [];
    }
  };
  compilePattern = function(domains) {
    return RegExp("((^|\\.)(" + (domains.join("|")) + "))\\.?$", "i");
  };
}).call(this);
