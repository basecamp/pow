(function() {
  var Configuration, Daemon, Installer, usage, util, _ref;

  _ref = require(".."), Daemon = _ref.Daemon, Configuration = _ref.Configuration, Installer = _ref.Installer;

  util = require("util");

  process.title = "pow";

  usage = function() {
    console.error("usage: pow [--print-config | --install-local | --install-system [--dry-run]]");
    return process.exit(-1);
  };

  Configuration.getUserConfiguration(function(err, configuration) {
    var arg, createInstaller, daemon, dryRun, installer, key, printConfig, shellEscape, underscore, value, _i, _len, _ref2, _ref3, _results;
    if (err) throw err;
    printConfig = false;
    createInstaller = null;
    dryRun = false;
    _ref2 = process.argv.slice(2);
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      arg = _ref2[_i];
      if (arg === "--print-config") {
        printConfig = true;
      } else if (arg === "--install-local") {
        createInstaller = Installer.getLocalInstaller;
      } else if (arg === "--install-system") {
        createInstaller = Installer.getSystemInstaller;
      } else if (arg === "--dry-run") {
        dryRun = true;
      } else {
        usage();
      }
    }
    if (dryRun && !createInstaller) {
      return usage();
    } else if (printConfig) {
      underscore = function(string) {
        return string.replace(/(.)([A-Z])/g, function(match, left, right) {
          return left + "_" + right.toLowerCase();
        });
      };
      shellEscape = function(string) {
        return "'" + string.toString().replace(/'/g, "'\\''") + "'";
      };
      _ref3 = configuration.toJSON();
      _results = [];
      for (key in _ref3) {
        value = _ref3[key];
        _results.push(util.puts("POW_" + underscore(key).toUpperCase() + "=" + shellEscape(value)));
      }
      return _results;
    } else if (createInstaller) {
      installer = createInstaller(configuration);
      if (dryRun) {
        return installer.needsRootPrivileges(function(needsRoot) {
          var exitCode;
          exitCode = needsRoot ? 1 : 0;
          return installer.getStaleFiles(function(files) {
            var file, _j, _len2;
            for (_j = 0, _len2 = files.length; _j < _len2; _j++) {
              file = files[_j];
              util.puts(file.path);
            }
            return process.exit(exitCode);
          });
        });
      } else {
        return installer.install(function(err) {
          if (err) throw err;
        });
      }
    } else {
      daemon = new Daemon(configuration);
      return daemon.start();
    }
  });

}).call(this);
