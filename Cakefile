require.paths.push __dirname + "/lib"
require.paths.push __dirname + "/test"

task "test", "Run the Pow test suite", ->
  {testrunner} = require("nodeunit")
  process.chdir __dirname
  testrunner.run ["test"]

