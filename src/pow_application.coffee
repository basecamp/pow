module.exports = class PowApplication
  constructor: (@configuration) ->

  handle: (req, res, next, callback) ->
    res.send "Hello"
    callback()
