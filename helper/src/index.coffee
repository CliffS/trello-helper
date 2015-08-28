# Pre-load all modules.
#
fs = require 'fs'

fs.readdir __dirname, (err, files) ->
  for file in files
    [name, suffix] = file.split '.'
    if suffix is 'coffee'
      exports[name] = require "./#{file}" unless name is 'index'

