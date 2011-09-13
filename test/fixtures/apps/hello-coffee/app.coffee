http = require 'http'
port = Number(process.env.PORT || 3000)

server = http.createServer (req, res) ->
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.end 'Hello Procfile.dev!'

server.listen port, "127.0.0.1"

console.log 'Server running at http://127.0.0.1:' + port + '/'
