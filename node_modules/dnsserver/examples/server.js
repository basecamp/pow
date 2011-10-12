#!/usr/bin/env node

var dnsserver = require('../lib/dnsserver');

var server = dnsserver.createServer();
server.bind(8000, '127.0.0.1');

server.on('request', function(req, res) {
  console.log("req = ", req);
  var question = req.question;

  if (question.type == 1 && question.class == 1 && question.name == 'tomhughescroucher.com') {
    // IN A query
    res.addRR(question.name, 1, 1, 3600, '184.106.231.91');
  } else {
    res.header.rcode = 3; // NXDOMAIN
  }

  res.send();
});

server.on('error', function(e) {
  throw e;
});
