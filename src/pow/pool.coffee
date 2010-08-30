{Application} = require "./application"

exports.Pool = class Pool
  constructor: ->
    @applications = {}

  find: (path) ->
    @applications[path]

  create: (path) ->
    application = new Application path
    application.run (exitCode) =>
      @destroy path
    @applications[path] = application

  destroy: (path) ->
    delete @applications[path]

  handle: (path, request) ->
    application = @find(path) || @create(path)
    application.handle request

  getApplications: ->
    application for path, application of @applications

  getIdleApplications: ->
    application for application in @getApplications() when application.isIdle()
