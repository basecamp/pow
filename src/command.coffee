{Daemon, Configuration} = require ".."
process.title = "pow"

Configuration.getGlobalConfiguration (err, configuration) ->
  throw err if err

  daemon = new Daemon configuration
  daemon.start()
