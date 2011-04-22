module.exports = class PowConsole
  constructor: (@configuration, @httpServer) ->
    @debugLog = @configuration.getLogger "debug"

  getApplications: (callback) ->
    applications = {}
    @configuration.gatherApplicationRoots (err, roots) =>
      return callback err if err
      for name, root of roots
        application = applications[root] ?= symlinks: []
        application.rackApplication ?= @httpServer.rackApplications[name]
        application.symlinks.push name
      callback null, applications

  handle: (req, res, next) ->
    body = ""

    @getApplications (err, applications) ->
      for root, application of applications
        body += "#{root}: #{JSON.stringify application.symlinks}\n"

      res.end body
