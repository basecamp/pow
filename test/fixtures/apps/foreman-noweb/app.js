var http = require('http');
var port = parseInt(process.env.PORT) || 3000;
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Pretend I am a worker.');
}).listen(port, "127.0.0.1");
console.log('Worker running at http://127.0.0.1:' + port + '/');
