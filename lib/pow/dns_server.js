(function() {
  var DnsServer, compilePattern, ndns;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  ndns = require("ndns");
  compilePattern = function(domain) {
    return RegExp("\\." + domain + "\\.?$");
  };
  module.exports = DnsServer = (function() {
    __extends(DnsServer, ndns.Server);
    function DnsServer(configuration) {
      this.configuration = configuration;
      this.handleRequest = __bind(this.handleRequest, this);;
      DnsServer.__super__.constructor.call(this, "udp4");
      this.pattern = compilePattern(this.configuration.domain);
      this.on("request", this.handleRequest);
    }
    DnsServer.prototype.listen = function(port, callback) {
      this.bind(port);
      return typeof callback === "function" ? callback() : void 0;
    };
    DnsServer.prototype.handleRequest = function(req, res) {
      var className, name, typeName, _ref, _ref2;
      res.header = req.header;
      res.question = req.question;
      res.header.qr = 1;
      res.header.ancount = 1;
      res.header.aa = 1;
      _ref2 = (_ref = req.question[0]) != null ? _ref : {}, typeName = _ref2.typeName, className = _ref2.className, name = _ref2.name;
      if (typeName === "A" && className === "IN" && this.pattern.test(name)) {
        res.addRR(name, ndns.ns_t.a, ndns.ns_c["in"], 600, "127.0.0.1");
      }
      return res.send();
    };
    return DnsServer;
  })();
}).call(this);
