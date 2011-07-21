(function() {
  var DnsServer, ndns;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  ndns = require("ndns");
  module.exports = DnsServer = (function() {
    __extends(DnsServer, ndns.Server);
    function DnsServer(configuration) {
      this.configuration = configuration;
      this.handleRequest = __bind(this.handleRequest, this);
      DnsServer.__super__.constructor.call(this, "udp4");
      this.on("request", this.handleRequest);
    }
    DnsServer.prototype.listen = function(port, callback) {
      this.bind(port);
      return typeof callback === "function" ? callback() : void 0;
    };
    DnsServer.prototype.handleRequest = function(req, res) {
      var pattern, q, _ref;
      pattern = this.configuration.dnsDomainPattern;
      res.header = req.header;
      res.question = req.question;
      res.header.aa = 1;
      res.header.qr = 1;
      q = (_ref = req.question[0]) != null ? _ref : {};
      if (q.type === ndns.ns_t.a && q["class"] === ndns.ns_c["in"] && pattern.test(q.name)) {
        res.addRR(ndns.ns_s.an, q.name, ndns.ns_t.a, ndns.ns_c["in"], 600, "127.0.0.1");
      } else {
        res.header.rcode = ndns.ns_rcode.nxdomain;
      }
      return res.send();
    };
    return DnsServer;
  })();
}).call(this);
