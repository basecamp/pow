(function() {
  var PowApplication;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  module.exports = PowApplication = (function() {
    function PowApplication(configuration, httpServer) {
      this.configuration = configuration;
      this.httpServer = httpServer;
      this.debugLog = this.configuration.getLogger("debug");
    }
    PowApplication.prototype.getApplications = function(callback) {
      var applications;
      applications = {};
      return this.configuration.gatherApplicationRoots(__bind(function(err, roots) {
        var application, name, root, _ref, _ref2, _ref3;
        if (err) {
          return callback(err);
        }
        for (name in roots) {
          root = roots[name];
          application = (_ref = applications[root]) != null ? _ref : applications[root] = {};
          (_ref2 = application.symlinks) != null ? _ref2 : application.symlinks = [];
          application.symlinks.push(name);
          (_ref3 = application.rackApplication) != null ? _ref3 : application.rackApplication = this.httpServer.rackApplications[name];
        }
        return callback(null, applications);
      }, this));
    };
    PowApplication.prototype.handle = function(req, res, next) {
      var body;
      body = "";
      return this.getApplications(function(err, applications) {
        var application, root;
        for (root in applications) {
          application = applications[root];
          body += "" + root + ": " + (JSON.stringify(application.symlinks)) + "\n";
        }
        return res.end(body);
      });
    };
    return PowApplication;
  })();
}).call(this);
