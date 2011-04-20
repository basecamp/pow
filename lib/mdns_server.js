(function() {
  var exec, mDnsServer, ndns, util;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  ndns = require("ndns");
  util = require("util");
  exec = require("child_process").exec;
  module.exports = mDnsServer = (function() {
    var lookupAddressToContactAddressPattern, lookupAddressToContactInterfacePattern;
    __extends(mDnsServer, ndns.Server);
    function mDnsServer(configuration) {
      this.configuration = configuration;
      this.handleRequest = __bind(this.handleRequest, this);;
      mDnsServer.__super__.constructor.call(this, "udp4");
      this.logger = this.configuration.getLogger('mdns');
      this.on("request", this.handleRequest);
    }
    mDnsServer.prototype.lookupHostname = function(callback) {
      if (this.configuration.mDnsHost !== null) {
        return typeof callback == "function" ? callback(null, this.configuration.mDnsHost) : void 0;
      } else {
        return exec("scutil --get LocalHostName", __bind(function(error, stdout, stderr) {
          var hostname;
          if (error) {
            this.logger.warning("Couldn't query local hostname. scutil said: " + (util.inspect(stdout)) + " and " + (util.inspect(stderr)));
            return typeof callback == "function" ? callback(true) : void 0;
          } else {
            hostname = stdout.trim();
            return typeof callback == "function" ? callback(null, hostname) : void 0;
          }
        }, this));
      }
    };
    lookupAddressToContactInterfacePattern = /interface:\s+(\S+)/i;
    lookupAddressToContactAddressPattern = /inet\s+(\d+\.\d+\.\d+\.\d+)/i;
    mDnsServer.prototype.lookupAddressToContact = function(address, callback) {
      return exec("route get default", __bind(function(error, stdout, stderr) {
        var interface, _ref;
        interface = (_ref = stdout.match(lookupAddressToContactInterfacePattern)) != null ? _ref[1] : void 0;
        if (error || !interface) {
          this.logger.warning("Couldn't query route for " + address + ". route said: " + (util.inspect(stdout)) + " and " + (util.inspect(stderr)));
          return typeof callback == "function" ? callback(true, null) : void 0;
        } else {
          return exec("ifconfig " + interface, __bind(function(error, stdout, stderr) {
            var myAddress, _ref;
            myAddress = (_ref = stdout.match(lookupAddressToContactAddressPattern)) != null ? _ref[1] : void 0;
            if (error || !myAddress) {
              this.logger.warning("Couldn't query address for " + interface + ". ifconfig said: " + (util.inspect(stdout)) + " and " + (util.inspect(stderr)));
              return typeof callback == "function" ? callback(true, null) : void 0;
            } else {
              return typeof callback == "function" ? callback(null, myAddress) : void 0;
            }
          }, this));
        }
      }, this));
    };
    mDnsServer.prototype.listen = function(port, callback) {
      return this.lookupHostname(__bind(function(error, hostname) {
        this.pattern = RegExp("(^|\\.)" + hostname + "\\." + this.configuration.mDnsDomain + "\\.?", "i");
        this.logger.debug("multicasting on " + this.configuration.mDnsAddress);
        this.setTTL(255);
        this.setMulticastTTL(255);
        this.setMulticastLoopback(true);
        this.addMembership(this.configuration.mDnsAddress);
        this.logger.debug("binding to port " + this.configuration.mDnsPort);
        this.bind(this.configuration.mDnsPort);
        this.logger.debug("adding mDNS domain to configuration");
        this.configuration.domains.push("" + hostname + ".@configuration.mDnsDomain");
        return typeof callback == "function" ? callback() : void 0;
      }, this));
    };
    mDnsServer.prototype.handleRequest = function(req, res) {
      var q, _ref;
      q = (_ref = req.question[0]) != null ? _ref : {};
      if (q.type === ndns.ns_t.a && q["class"] === ndns.ns_c["in"] && this.pattern.test(q.name)) {
        this.logger.debug("request: question: " + (util.inspect(req.question)));
        res.header = req.header;
        res.question = req.question;
        res.header.aa = 1;
        res.header.qr = 1;
        return this.lookupAddressToContact(req.rinfo.address, __bind(function(error, myAddress) {
          if (error) {
            return this.logger.warning("couldn't find my address to talk to " + req.rinfo.address);
          } else {
            res.addRR(ndns.ns_s.an, q.name, ndns.ns_t.a, ndns.ns_c["in"], 600, myAddress);
            return res.sendTo(this, this.configuration.mDnsPort, this.configuration.mDnsAddress, __bind(function(error) {
              if (error) {
                return this.logger.warning("couldn't send mdns response: " + (util.inspect(error)));
              }
            }, this));
          }
        }, this));
      }
    };
    return mDnsServer;
  })();
}).call(this);
