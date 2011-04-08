# The `command` module is loaded when the `pow` binary runs. It parses
# any command-line arguments and determines whether to install Pow's
# configuration files or start the daemon itself.

{Daemon, Configuration, Installer} = require ".."
sys = require "sys"

# Set the process's title to `pow` so it's easier to find in `ps`,
# `top`, Activity Monitor, and so on.
process.title = "pow"

# Print valid command-line arguments and exit with a non-zero exit
# code if invalid arguments are passed to the `pow` binary.
usage = ->
  console.error "usage: pow [--install-local | --install-system [--dry-run]]"
  process.exit -1

# Start by loading the user configuration from `~/.powconfig`, if it
# exists. The user configuration affects both the installer and the
# daemon.
Configuration.getUserConfiguration (err, configuration) ->
  throw err if err

  createInstaller = null
  dryRun = false

  for arg in process.argv.slice(2)
    # Cache the factory method for creating a local or system
    # installer if necessary.
    if arg is "--install-local"
      createInstaller = Installer.getLocalInstaller
    else if arg is "--install-system"
      createInstaller = Installer.getSystemInstaller
    # Set a flag if a dry run is requested.
    else if arg is "--dry-run"
      dryRun = true
    # Abort if we encounter an unknown argument.
    else
      usage()

  # Abort if a dry run is requested without installing anything.
  if dryRun and not createInstaller
    usage()
  else if createInstaller
    # Create the installer, passing in our loaded configuration.
    installer = createInstaller configuration
    # If a dry run was requested, check to see whether any files need
    # to be installed with root privileges. If yes, exit with a status
    # of 1. If no, exit with a status of 0.
    if dryRun
      installer.needsRootPrivileges (needsRoot) ->
        exitCode = if needsRoot then 1 else 0
        installer.getStaleFiles (files) ->
          sys.puts file.path for file in files
          process.exit exitCode
    # Otherwise, install all the requested files, printing the full
    # path of each installed file to stdout.
    else
      installer.install (err) ->
        throw err if err
  else
    # Start up the Pow daemon if no arguments were passed.
    daemon = new Daemon configuration
    daemon.start()
