###
# mustache-simple.js - wrapper around mustache
###

fs = require 'fs'
mustache = require 'mustache'
Path = require 'path'

class Mustache
  constructor: (options) ->
    @extension = options.extension ? 'mustache'
    @path      = options.path      ? '.'

  path: (path) ->
    @path = path if path
    @path

  extension: (extension) ->
    @extension = extension if extension
    @extension

  re: /{{>\s*([\w-]+)\s*}}/g,

  parts: {}

  readFile: (filename) ->
    paths = if Array.isArray @path then @path else [ @path ]
    data = 'Not found'
    for path in paths
      file = Path.join path, "#{filename}.#{@extension}"
      if fs.existsSync file
        data = fs.readFileSync file, encoding: 'utf-8'
        partials = (data.match @re) ? []
        partials = (part.replace(@re, '$1') for part in partials)
        @parts[part] ?= @readFile(part) for part in partials
        break
    data

  render: (file, context) ->
    template = @readFile file
    output = mustache.render template, context, @parts

module.exports = Mustache

