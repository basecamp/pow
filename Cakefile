{print} = require 'sys'
{spawn} = require 'child_process'

task 'build', 'Build CoffeeScript source files', ->
  coffee = spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> print data.toString()

task 'test', 'Run the Pow test suite', ->
  require.paths.unshift __dirname + "/src"
  require.paths.unshift __dirname + "/test/lib"

  {reporters} = require 'nodeunit'
  process.chdir __dirname
  reporters.default.run ['test']
