(function() {
  var Configuration, Logger, async, compilePattern, env, fs, getFilenamesForHost, getUserEnv, libraryPath, mkdirp, path, rstat, sourceScriptEnv;
  var __slice = Array.prototype.slice;

  fs = require("fs");

  path = require("path");

  async = require("async");

  Logger = require("./logger");

  mkdirp = require("./util").mkdirp;

  sourceScriptEnv = require("./util").sourceScriptEnv;

  getUserEnv = require("./util").getUserEnv;

  env = process.env;

  module.exports = Configuration = (function() {

    Configuration.userConfigurationPath = path.join(env.HOME, ".powconfig");

    Configuration.loadUserConfigurationEnvironment = function(callback) {
      var _this = this;
      return getUserEnv(function(err, env) {
        var p;
        if (err) {
          return callback(err);
        } else {
          return path.exists(p = _this.userConfigurationPath, function(exists) {
            if (exists) {
              return sourceScriptEnv(p, env, callback);
            } else {
              return callback(null, env);
            }
          });
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
      if (options == null) options = {};
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

    Configuration.prototype.findHostConfiguration = function(host, callback) {
      var _this = this;
      if (host == null) host = "";
      return this.gatherHostConfigurations(function(err, hosts) {
        var config, domain, file, _i, _j, _len, _len2, _ref, _ref2;
        if (err) return callback(err);
        _ref = _this.allDomains;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          domain = _ref[_i];
          _ref2 = getFilenamesForHost(host, domain);
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            file = _ref2[_j];
            if (config = hosts[file]) return callback(null, domain, config);
          }
        }
        if (config = hosts["default"]) {
          return callback(null, _this.allDomains[0], config);
        }
        return callback(null);
      });
    };

    Configuration.prototype.gatherHostConfigurations = function(callback) {
      var hosts;
      var _this = this;
      hosts = {};
      return mkdirp(this.hostRoot, function(err) {
        if (err) return callback(err);
        return fs.readdir(_this.hostRoot, function(err, files) {
          if (err) return callback(err);
          return async.forEach(files, function(file, next) {
            var name, root;
            root = path.join(_this.hostRoot, file);
            name = file.toLowerCase();
            return rstat(root, function(err, stats, path) {
              if (stats != null ? stats.isDirectory() : void 0) {
                hosts[name] = {
                  root: path
                };
                return next();
              } else if (stats != null ? stats.isFile() : void 0) {
                return fs.readFile(path, 'utf-8', function(err, data) {
                  if (err) return next();
                  data = data.trim();
                  if (data.length < 10 && !isNaN(parseInt(data))) {
                    hosts[name] = {
                      url: "http://localhost:" + (parseInt(data))
                    };
                  } else if (data.match("https?://")) {
                    hosts[name] = {
                      url: data
                    };
                  }
                  return next();
                });
              } else {
                return next();
              }
            });
          }, function(err) {
            return callback(err, hosts);
          });
        });
      });
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

  rstat = function(path, callback) {
    return fs.lstat(path, function(err, stats) {
      if (err) {
        return callback(err);
      } else if (stats != null ? stats.isSymbolicLink() : void 0) {
        return fs.realpath(path, function(err, realpath) {
          if (err) {
            return callback(err);
          } else {
            return rstat(realpath, callback);
          }
        });
      } else {
        return callback(err, stats, path);
      }
    });
  };

  compilePattern = function(domains) {
    return RegExp("((^|\\.)(" + (domains.join("|")) + "))\\.?$", "i");
  };

}).call(this);
