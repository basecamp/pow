(function() {
  var Installer, InstallerFile, async, chown, daemonSource, firewallSource, fs, mkdirp, path, resolverSource, sys;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  fs = require("fs");
  path = require("path");
  mkdirp = require("./util").mkdirp;
  chown = require("./util").chown;
  sys = require("sys");
  resolverSource = require("./templates/installer/resolver");
  firewallSource = require("./templates/installer/cx.pow.firewall.plist");
  daemonSource = require("./templates/installer/cx.pow.powd.plist");
  InstallerFile = (function() {
    function InstallerFile(path, source, root, mode) {
      this.path = path;
      this.root = root != null ? root : false;
      this.mode = mode != null ? mode : 0644;
      this.setPermissions = __bind(this.setPermissions, this);
      this.setOwnership = __bind(this.setOwnership, this);
      this.writeFile = __bind(this.writeFile, this);
      this.vivifyPath = __bind(this.vivifyPath, this);
      this.source = source.trim();
    }
    InstallerFile.prototype.isStale = function(callback) {
      return path.exists(this.path, __bind(function(exists) {
        if (exists) {
          return fs.readFile(this.path, "utf8", __bind(function(err, contents) {
            if (err) {
              return callback(true);
            } else {
              return callback(this.source !== contents.trim());
            }
          }, this));
        } else {
          return callback(true);
        }
      }, this));
    };
    InstallerFile.prototype.vivifyPath = function(callback) {
      return mkdirp(path.dirname(this.path), callback);
    };
    InstallerFile.prototype.writeFile = function(callback) {
      return fs.writeFile(this.path, this.source, "utf8", callback);
    };
    InstallerFile.prototype.setOwnership = function(callback) {
      if (this.root) {
        return chown(this.path, "root:wheel", callback);
      } else {
        return callback(false);
      }
    };
    InstallerFile.prototype.setPermissions = function(callback) {
      return fs.chmod(this.path, this.mode, callback);
    };
    InstallerFile.prototype.install = function(callback) {
      return async.series([this.vivifyPath, this.writeFile, this.setOwnership, this.setPermissions], callback);
    };
    return InstallerFile;
  })();
  module.exports = Installer = (function() {
    Installer.getSystemInstaller = function(configuration) {
      var domain, files, _i, _len, _ref;
      this.configuration = configuration;
      files = [new InstallerFile("/Library/LaunchDaemons/cx.pow.firewall.plist", firewallSource(this.configuration), true)];
      _ref = this.configuration.domains;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        domain = _ref[_i];
        files.push(new InstallerFile("/etc/resolver/" + domain, resolverSource(this.configuration), true));
      }
      return new Installer(files);
    };
    Installer.getLocalInstaller = function(configuration) {
      this.configuration = configuration;
      return new Installer([new InstallerFile("" + process.env.HOME + "/Library/LaunchAgents/cx.pow.powd.plist", daemonSource(this.configuration))]);
    };
    function Installer(files) {
      this.files = files != null ? files : [];
    }
    Installer.prototype.getStaleFiles = function(callback) {
      return async.select(this.files, function(file, proceed) {
        return file.isStale(proceed);
      }, callback);
    };
    Installer.prototype.needsRootPrivileges = function(callback) {
      return this.getStaleFiles(function(files) {
        return async.detect(files, function(file, proceed) {
          return proceed(file.root);
        }, function(result) {
          return callback(result != null);
        });
      });
    };
    Installer.prototype.install = function(callback) {
      return this.getStaleFiles(function(files) {
        return async.forEach(files, function(file, proceed) {
          return file.install(function(err) {
            if (!err) {
              sys.puts(file.path);
            }
            return proceed(err);
          });
        }, callback);
      });
    };
    return Installer;
  })();
}).call(this);
