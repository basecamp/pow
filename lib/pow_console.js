(function() {
  var PowConsole, merge;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  merge = function() {
    var key, object, objects, result, value, _i, _len;
    objects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    result = {};
    for (_i = 0, _len = objects.length; _i < _len; _i++) {
      object = objects[_i];
      for (key in object) {
        value = object[key];
        result[key] = value;
      }
    }
    return result;
  };
  module.exports = PowConsole = (function() {
    function PowConsole(configuration, httpServer) {
      this.configuration = configuration;
      this.httpServer = httpServer;
      this.debugLog = this.configuration.getLogger("debug");
    }
    PowConsole.prototype.getApplications = function(callback) {
      var applications;
      applications = {};
      return this.configuration.gatherApplicationRoots(__bind(function(err, roots) {
        var application, name, root, _ref, _ref2;
        if (err) {
          return callback(err);
        }
        for (name in roots) {
          root = roots[name];
          application = (_ref = applications[root]) != null ? _ref : applications[root] = {
            symlinks: []
          };
          (_ref2 = application.rackApplication) != null ? _ref2 : application.rackApplication = this.httpServer.rackApplications[root];
          application.symlinks.push(name);
        }
        return callback(null, applications);
      }, this));
    };
    PowConsole.prototype.helpers = {
      path: require("path"),
      formatPath: function(path) {
        var home;
        home = process.env.HOME;
        if (home === path.slice(0, home.length)) {
          return "~" + path.slice(home.length);
        } else {
          return path;
        }
      },
      formatTime: function(milliseconds) {
        var seconds;
        seconds = milliseconds / 1000;
        if (seconds >= 60) {
          return Math.floor(seconds / 60) + " minutes";
        } else {
          return Math.floor(seconds) + " seconds";
        }
      }
    };
    PowConsole.prototype.render = function(res, status, templateName, context) {
      var body, template;
      if (context == null) {
        context = {};
      }
      template = require("./templates/pow_console/" + templateName + ".html");
      context = merge(this.helpers, context);
      body = template(context);
      res.writeHead(status, {
        "Content-Type": "text/html; charset=utf8",
        "X-Pow-Template": templateName
      });
      return res.end(body);
    };
    PowConsole.prototype.handle = function(req, res, next) {
      return this.getApplications(__bind(function(err, applications) {
        if (err) {
          return next(err);
        } else {
          try {
            return this.render(res, 200, "console", {
              configuration: this.configuration,
              applications: applications
            });
          } catch (err) {
            res.writeHead(500, {
              "Content-Type": "text/plain"
            });
            return res.end(err.stack);
          }
        }
      }, this));
    };
    return PowConsole;
  })();
}).call(this);
