var http = require('http');
var port = parseInt(process.env.PORT) || 3000;
http.createServer(function (req, res) {
  res.writeHead(400, {'Content-Type': 'text/plain'});
  res.end('This is not the app you\'re looking for...');
}).listen(port, "127.0.0.1");
console.log('Server running at http://127.0.0.1:' + port + '/');
