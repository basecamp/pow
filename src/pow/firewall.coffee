util   = require if process.binding('natives').util then 'util' else 'sys'
{exec} =  require 'child_process'

exports.forwardPort = (port, callback) ->
  exec "ipfw add fwd 127.0.0.1,#{port} tcp from any to any dst-port 80 in", (error, stdout, stderr) ->
    util.print stdout
    util.print stderr

    if error?
      callback 1

    exec "sysctl -w net.inet.ip.forwarding=1", (error, stdout, stderr) ->
      util.print stdout
      util.print stderr

      if error?
        callback 1

      callback 0
