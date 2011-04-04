{Daemon, Configuration} = require ".."
process.title = "pow"

flag = process.argv[2]

Configuration.getUserConfiguration (err, configuration) ->
  throw err if err

  if flag is "--install" or flag is "-i"
    configuration.install (err) ->
      throw err if err
  else
    daemon = new Daemon configuration
    daemon.start()
