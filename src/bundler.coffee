{spawn} = require "child_process"

readOutputFrom = (process, callback) ->
  output = ""
  process.stdout.on "data", (data) ->
    output += data.toString()
  process.on "exit", (exitCode) ->
    callback exitCode, output

exports.list = (options, callback) ->
  args = ["list"]
  if typeof options == "function"
    callback = options
    options = {}
  else
    options ||= {}
    args.push options.name if options.name

  process = spawn("bundle", args, cwd: options.cwd)
  readOutputFrom process, callback

exports.hasGem = (options, callback) ->
  exports.list options, (exitCode) ->
    callback exitCode is 0

exports.exec = (options) ->
  spawn("bundle", ["exec", options.args...], cwd: options.cwd)
