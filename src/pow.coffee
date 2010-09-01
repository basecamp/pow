{Server} = require "./pow/server"

server = new Server
  "/Volumes/37signals/iterations/config.ru": ["iterations.test"]
  "/Volumes/37signals/portfolio/config.ru":  ["37img.test"]
  "/Volumes/37signals/launchpad/config.ru":  ["launchpad.test"]
  "/Volumes/37signals/basecamp/config.ru":   ["37s.basecamp.test"]

server.listen 3000

setInterval (-> server.reapIdleApplications()), 1000
