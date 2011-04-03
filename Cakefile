require.paths.unshift "#{__dirname}/node_modules"

async   = require 'async'
fs      = require 'fs'
{print} = require 'sys'
{spawn} = require 'child_process'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

buildTemplates = (callback) ->
  eco = require 'eco'
  compile = (name) ->
    (callback) ->
      fs.readFile "src/#{name}.eco", "utf8", (err, data) ->
        if err then callback err
        else fs.writeFile "lib/#{name}.js", eco.compile(data), callback

  async.parallel [
    compile("cx.pow.firewall.plist")
    compile("cx.pow.powd.plist")
  ], callback

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> print data.toString()
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()
  buildTemplates()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run the Pow test suite', ->
  build ->
    process.env["RUBYOPT"]  = "-rubygems"
    process.env["NODE_ENV"] = "test"
    require.paths.unshift __dirname + "/lib"

    {reporters} = require 'nodeunit'
    process.chdir __dirname
    reporters.default.run ['test']
