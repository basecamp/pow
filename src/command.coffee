process.title = "pow"

{Daemon, Configuration, Installer} = require ".."
sys = require "sys"

usage = ->
  console.error "usage: pow [[--install-local | --install-system] [--dry-run]]"
  process.exit -1

Configuration.getUserConfiguration (err, configuration) ->
  throw err if err

  createInstaller = null
  dryRun = false

  for arg in process.argv.slice(2)
    if arg is "--install-local"
      createInstaller = Installer.getLocalInstaller
    else if arg is "--install-system"
      createInstaller = Installer.getSystemInstaller
    else if arg is "--dry-run"
      dryRun = true
    else
      usage()

  if dryRun and not createInstaller
    usage()
  else if createInstaller
    installer = createInstaller configuration
    if dryRun
      installer.needsRootPrivileges (needsRoot) ->
        exitCode = if needsRoot then 1 else 0
        installer.getStaleFiles (files) ->
          sys.puts file.path for file in files
          process.exit exitCode
    else
      installer.install (err) ->
        throw err if err
  else
    daemon = new Daemon configuration
    daemon.start()
