(function() {
  var ForemanApplication, HttpProxy, PortChecker, async, basename, bufferLines, exec, exists, fs, join, net, pause, sourceScriptEnv, spawn, _ref, _ref2, _ref3;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  fs = require("fs");
  net = require("net");
  _ref = require("./util"), bufferLines = _ref.bufferLines, pause = _ref.pause, sourceScriptEnv = _ref.sourceScriptEnv, PortChecker = _ref.PortChecker;
  _ref2 = require("path"), join = _ref2.join, exists = _ref2.exists, basename = _ref2.basename;
  _ref3 = require('child_process'), spawn = _ref3.spawn, exec = _ref3.exec;
  HttpProxy = require("http-proxy").HttpProxy;
  module.exports = ForemanApplication = (function() {
    function ForemanApplication(configuration, root) {
      this.configuration = configuration;
      this.root = root;
      this.logger = this.configuration.getLogger(join("apps", basename(this.root)));
      this.procfile = this.configuration.procfile;
      this.readyCallbacks = [];
      this.quitCallbacks = [];
      this.statCallbacks = [];
    }
    ForemanApplication.prototype.changeState = function(state) {
      this.logger.debug("ForemanApplication " + this + " changing from " + this.state + " to " + state);
      return this.state = state;
    };
    ForemanApplication.prototype.ready = function(callback) {
      if (this.state === "ready") {
        return callback();
      } else {
        this.readyCallbacks.push(callback);
        return this.initialize();
      }
    };
    ForemanApplication.prototype.quit = function(callback) {
      if (this.state) {
        if (callback) {
          this.quitCallbacks.push(callback);
        }
        return this.terminate();
      } else {
        return typeof callback === "function" ? callback() : void 0;
      }
    };
    ForemanApplication.prototype.loadScriptEnvironment = function(env, callback) {
      return async.reduce([".powrc", ".envrc", ".powenv"], env, __bind(function(env, filename, callback) {
        var script;
        return exists(script = join(this.root, filename), function(scriptExists) {
          if (scriptExists) {
            return sourceScriptEnv(script, env, callback);
          } else {
            return callback(null, env);
          }
        });
      }, this), callback);
    };
    ForemanApplication.prototype.loadRvmEnvironment = function(env, callback) {
      var script;
      return exists(script = join(this.root, ".rvmrc"), __bind(function(rvmrcExists) {
        var rvm;
        if (rvmrcExists) {
          return exists(rvm = this.configuration.rvmPath, function(rvmExists) {
            var before;
            if (rvmExists) {
              before = "source '" + rvm + "' > /dev/null";
              return sourceScriptEnv(script, env, {
                before: before
              }, callback);
            } else {
              return callback(null, env);
            }
          });
        } else {
          return callback(null, env);
        }
      }, this));
    };
    ForemanApplication.prototype.loadEnvironment = function(callback) {
      return this.loadScriptEnvironment(null, __bind(function(err, env) {
        if (err) {
          return callback(err);
        } else {
          return this.loadRvmEnvironment(env, __bind(function(err, env) {
            var _ref4;
            if (err) {
              return callback(err);
            } else {
              this.procfile = (_ref4 = env != null ? env.POW_PROCFILE : void 0) != null ? _ref4 : this.procfile;
              return callback(null, env);
            }
          }, this));
        }
      }, this));
    };
    ForemanApplication.prototype.initialize = function() {
      if (this.state) {
        if (this.state === "terminating") {
          this.quit(__bind(function() {
            return this.initialize();
          }, this));
        }
        return;
      }
      this.changeState("initializing");
      return this.loadEnvironment(__bind(function(err, env) {
        var port;
        if (err) {
          this.changeState(null);
          this.logger.error(err.message);
          this.logger.error("stdout: " + err.stdout);
          return this.logger.error("stderr: " + err.stderr);
        } else {
          this.spawning = {};
          this.webProcesses = {};
          this.webProcessCount = 0;
          this.spawnedCount = 0;
          this.readyCount = 0;
          port = 20000 + Math.floor(Math.random() * 15000);
          this.foreman = spawn('foreman', ['start', '-f', this.procfile, '-p', port], {
            cwd: this.root,
            env: env
          });
          this.logger.info("forman master " + this.foreman.pid + " spawned");
          bufferLines(this.foreman.stdout, __bind(function(line) {
            this.logger.info(line);
            if (this.state === "initializing") {
              return this.captureForemanPorts(line);
            }
          }, this));
          bufferLines(this.foreman.stderr, __bind(function(line) {
            return this.logger.warning(line);
          }, this));
          return this.foreman.on('exit', __bind(function(code, signal) {
            var quitCallback, _i, _len, _ref4;
            this.logger.debug("foreman master exited with code " + code + " & signal " + signal + "; " + this.quitCallbacks.length + " callbacks to go...");
            _ref4 = this.quitCallbacks;
            for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
              quitCallback = _ref4[_i];
              quitCallback();
            }
            this.quitCallbacks = [];
            this.foreman = null;
            return this.changeState(null);
          }, this));
        }
      }, this));
    };
    ForemanApplication.prototype.captureForemanPorts = function(line) {
      var countMatch, err, portInUseMatch, readyCallback, readyMatch, _base, _i, _len, _name, _ref4;
      portInUseMatch = /.* (web\.[0-9]+).*EADDRINUSE, Address already in use/(line);
      if (portInUseMatch) {
        err = new Error("Port assigned to " + portInUseMatch[1] + " in use already");
        this.changeState("ready");
        _ref4 = this.readyCallbacks;
        for (_i = 0, _len = _ref4.length; _i < _len; _i++) {
          readyCallback = _ref4[_i];
          readyCallback(err);
        }
        this.readyCallbacks = [];
        this.quit();
      }
      countMatch = /Launching ([0-9]+) ([\w]+) process.*/(line);
      if (countMatch) {
        if (countMatch[2] === "web") {
          this.webProcessCount = Number(countMatch[1]);
        }
      }
      readyMatch = /.* (web\.[0-9]+).*started with pid ([0-9]+) and port ([0-9]+)/(line);
      if (readyMatch) {
        (_base = this.spawning)[_name = readyMatch[1]] || (_base[_name] = {});
        this.spawning[readyMatch[1]].pid = Number(readyMatch[2]);
        this.spawning[readyMatch[1]].port = Number(readyMatch[3]);
        this.spawning[readyMatch[1]].name = readyMatch[1];
        this.spawnedCount++;
      }
      if (this.spawnedCount > 0 && this.spawnedCount === this.webProcessCount) {
        this.changeState("spawning");
        return this.checkPorts();
      }
    };
    ForemanApplication.prototype.checkPorts = function() {
      var detector, name, process, _ref4, _results;
      if (this.state !== "spawning") {
        return;
      }
      this.webProcesses = {};
      _ref4 = this.spawning;
      _results = [];
      for (name in _ref4) {
        process = _ref4[name];
        detector = new PortChecker(name, process.port);
        detector.on('ready', __bind(function(name) {
          var readyCallback, _i, _len, _ref5;
          this.webProcesses[name] = this.spawning[name];
          delete this.spawning[name];
          this.readyCount++;
          this.logger.info("" + this.readyCount + " of " + this.webProcessCount + " workers ready");
          if (this.readyCount === this.webProcessCount) {
            this.changeState("ready");
            _ref5 = this.readyCallbacks;
            for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
              readyCallback = _ref5[_i];
              readyCallback();
            }
            return this.readyCallbacks = [];
          }
        }, this));
        _results.push(detector.on('notAvailable', __bind(function(name) {
          var err, readyCallback, _i, _len, _ref5;
          err = new Error("Timed out waiting for port " + this.spawning[name].port + " to be available.");
          this.changeState("ready");
          _ref5 = this.readyCallbacks;
          for (_i = 0, _len = _ref5.length; _i < _len; _i++) {
            readyCallback = _ref5[_i];
            readyCallback(err);
          }
          this.readyCallbacks = [];
          return this.quit();
        }, this)));
      }
      return _results;
    };
    ForemanApplication.prototype.terminate = function() {
      var timeout;
      this.logger.debug("Terminating.");
      if (this.state === "initializing") {
        return this.ready(__bind(function() {
          return this.terminate();
        }, this));
      } else if (this.state === "ready") {
        if (this.foreman) {
          this.changeState("terminating");
          this.foreman.kill('SIGTERM');
          return timeout = setTimeout(__bind(function() {
            if (this.state === 'terminating') {
              return this.foreman.kill('SIGKILL');
            }
          }, this), 3000);
        }
      }
    };
    ForemanApplication.prototype.handle = function(req, res, next, callback) {
      var resume;
      resume = pause(req);
      return this.ready(__bind(function(err) {
        var index, process, proxy;
        if (err) {
          return next(err);
        }
        req.proxyMetaVariables = {
          SERVER_PORT: this.configuration.dstPort.toString()
        };
        try {
          proxy = new HttpProxy();
          proxy.on('proxyError', function(err, req, res) {
            console.log("Proxy Error: " + err);
            return next(err);
          });
          index = Math.ceil(Math.random() * this.webProcessCount);
          process = this.webProcesses["web." + index];
          return proxy.proxyRequest(req, res, {
            host: 'localhost',
            port: process.port
          });
        } finally {
          resume();
          if (typeof callback === "function") {
            callback();
          }
        }
      }, this));
    };
    ForemanApplication.prototype.restart = function(callback) {
      return this.quit(__bind(function() {
        return this.ready(callback);
      }, this));
    };
    return ForemanApplication;
  })();
}).call(this);
