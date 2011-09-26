{pause}         = require "../lib/util"
{testCase}      = require "nodeunit"
{EventEmitter}  = require "events"

module.exports = testCase
  "pauses and resumes request objects": (test) ->
    test.expect 9

    chunks = ['chunk 1', 'chunk 2']
    stream = new EventEmitter

    badData  = (chunk) -> test.ok false, "'data' should not fire on paused streams, but received a chunk: #{chunk}"
    goodData = (chunk) -> test.ok true
    onEnd    = -> test.ok true
    dataConsumer = (chunk) ->
      index = chunks.indexOf chunk
      test.ok index > -1, "unexpected data chunk: #{chunk}"
      chunks[index..index] = [] if index > -1

    stream.on 'data', badData
    stream.on 'data', dataConsumer
    stream.on 'end',  onEnd

    resume1 = pause stream
    resume2 = pause stream

    stream.emit 'data', chunk for chunk in chunks

    resume2?()

    chunks.push 'chunk 3'
    stream.emit 'data', 'chunk 3'

    stream.removeListener 'data', badData
    stream.on 'data', goodData

    resume3 = pause stream

    chunks.push 'chunk 4'
    stream.emit 'data', 'chunk 4'
    stream.emit 'end'

    resume1?()
    resume3?()
    test.done()
