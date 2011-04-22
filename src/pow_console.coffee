merge = (objects...) ->
  result = {}
  result[key] = value for key, value of object for object in objects
  result

module.exports = class PowConsole
  constructor: (@configuration, @httpServer) ->
    @debugLog = @configuration.getLogger "debug"

  getApplications: (callback) ->
    applications = {}
    @configuration.gatherApplicationRoots (err, roots) =>
      return callback err if err
      for name, root of roots
        application = applications[root] ?= symlinks: []
        application.rackApplication ?= @httpServer.rackApplications[root]
        application.symlinks.push name
      callback null, applications

  helpers:
    path: require "path"

    formatPath: (path) ->
      home = process.env.HOME
      if home is path.slice 0, home.length
        "~" + path.slice home.length
      else
        path

    formatTime: (milliseconds) ->
      seconds = milliseconds / 1000
      if seconds >= 60
        Math.floor(seconds / 60) + " minutes"
      else
        Math.floor(seconds) + " seconds"

  render: (res, status, templateName, context = {}) ->
    template = require "./templates/pow_console/#{templateName}.html"
    context  = merge @helpers, context
    body     = template context
    res.writeHead status, "Content-Type": "text/html; charset=utf8", "X-Pow-Template": templateName
    res.end body

  handle: (req, res, next) ->
    @getApplications (err, applications) =>
      if err
        next err
      else
        try
          @render res, 200, "console", {@configuration, applications}
        catch err
          res.writeHead 500, "Content-Type": "text/plain"
          res.end err.stack
