(function() {
  var NameServer, TEST_HOST, ndns;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  ndns = require("ndns");
  TEST_HOST = /\.test\.?$/;
  exports.NameServer = NameServer = (function() {
    function NameServer() {
      this.onRequest = __bind(this.onRequest, this);;      this.server = ndns.createServer("udp4");
      this.server.on("request", this.onRequest);
    }
    NameServer.prototype.listen = function(port) {
      return this.server.bind(port);
    };
    NameServer.prototype.onRequest = function(req, res) {
      var className, name, typeName, _ref, _ref2;
      res.header = req.header;
      res.question = req.question;
      res.header.qr = 1;
      res.header.ancount = 1;
      res.header.aa = 1;
      _ref2 = (_ref = req.question[0]) != null ? _ref : {}, typeName = _ref2.typeName, className = _ref2.className, name = _ref2.name;
      if (typeName === "A" && className === "IN" && TEST_HOST.test(name)) {
        res.addRR(name, ndns.ns_t.a, ndns.ns_c["in"], 600, "127.0.0.1");
      }
      return res.send();
    };
    return NameServer;
  })();
}).call(this);
