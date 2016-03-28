

http = require 'http'
URL  = require 'url'
fs   = require 'fs'
less = require 'less'
mime = require 'mime-types'
Mustache = require './vendor/mustache-simple'
Path = require 'path'
Session = require 'session-memcached'
qs = require 'querystring'
coffee = require 'coffee-script'
Etag = require 'etag'

User = require './local/User'
Constants = require './local/Constants'
Navigation = require './local/Navigation'
io = Constants.io
log = Constants.log()

server = http.createServer()

process.on 'SIGTERM', ->
  setTimeout ->
    do process.exit
  , 100

io.attach server

src   = require './src'

server.listen Constants.socket
log.debug "Server started and io attached"

HOMEPAGE = '/home/index'

server.on 'request', (req, res) ->
  url = URL.parse req.url, true
  urlPath = url.pathname
  return if urlPath.match /^\/socket\.io\//
  urlPath = urlPath.replace /^\/$/, HOMEPAGE
  suffix = urlPath.replace /^.*\./, '' if urlPath.match /\./
  mimetype = mime.lookup suffix
  fullpath = Path.join __dirname, urlPath
  switch mimetype
    when 'text/less'
      fs.readFile fullpath, 'utf-8', (err, data) =>
        if err
          res.writeHead 404
          res.end "#{fullpath}: File not found"
        else if check_etag req, res, fullpath
          return
        else
          less.render data,
            paths: [
              __dirname
              Path.dirname fullpath
            ]
          .then (output) ->
            res.writeHead 200,
              'Content-Type': 'text/css; charset=utf-8'
            res.end output.css
          , (error) ->
            console.log error
            res.writeHead 501, 'Not Implemented'
            res.end error
    when 'text/coffeescript'
      return if check_etag req, res, fullpath
      fs.readFile fullpath, 'utf-8', (err, data) =>
        if err
          res.writeHead 404
          res.end "#{urlPath}: path not found"
        else
          try
            text = coffee.compile data
          catch err
            console.log err
            res.writeHead 500, 'Syntax Error'
            res.end "Syntax Error: #{err.message}
                    on line #{err.location.first_line}"
            return
          res.writeHead 200,
            'Content-Type': 'application/x-javascript; charset=utf-8'
          res.end text
    when false
      if suffix
        res.writeHead 415
        res.end "#{fullpath} unknown suffix: #{suffix}"
        return
      session = new Session req, res
      match = urlPath.match /(?!\/)([^/]+)/g
      unless match?
        res.writeHead 404
        res.end "#{urlPath}: path not found"
        return
      [filename, routine, params...] = match
      routine ?= 'index'
      module = src[filename]
      unless typeof module?[routine] is 'function'
        res.writeHead 404
        res.end "#{urlPath}: path not found"
        return
      required = module[routine].role ? module.ROLE
      # if we have a user, make it a User class
      currentUser = new User session.user
      .on 'ready', =>
        if required? and not currentUser.can required
          session.nextPath = urlPath
          session.roleWanted = required
          filename = 'home'
          module = src.home
          routine = 'login'
        if req.method is 'HEAD'
            res.writeHead 200
            return res.end()
        parse_post req, (post) =>
          module[routine]
            session: session
            post: post
            query: url.query
            type: req.method
            headers: req.headers
            params: params
          , (command, result) =>
            if command?.toString().match /^\d{3}/     # HTTP response
              res.writeHead command
              res.end result
              return
            [command, result] = ['render', command] unless result?
            switch command
              when 'render'
                mus = new Mustache
                  extension: 'mustache'
                  path: [
                    Path.join __dirname, 'templates', filename
                    Path.join __dirname, 'templates'
                  ]
                result.nav ?= Navigation.navigation urlPath, currentUser
                result.heading ?= module.heading ? filename.wordUpper()
                result.brand ?= Constants.brand
                result.user ?= if currentUser.user_id? then currentUser
                template = result.template ? routine
                html = mus.render template, result
                res.writeHead 200,
                  'Content-Type': 'text/html; charset=utf-8'
                  'X-Mustache': 'rendered'
                res.end html
              when 'debug'
                res.writeHead 200,
                  'Content-Type': 'text/plain; charset=utf-8'
                res.end JSON.stringify result, ' ', 2
              when 'redirect'
                res.writeHead 303,
                  Location: result
                res.end "Redirect: #{result}"
              when 'json'
                res.writeHead 200,
                  'Content-Type': 'application/json; charset=utf-8'
                res.end JSON.stringify result
              else
                res.writeHead 200,
                  'Content-Type': command
                res.end result

    else # default:
      return if check_etag req, res, fullpath
      fs.readFile fullpath, (err, data) =>
        if err
          res.writeHead 404
          res.end "#{fullpath} File not found"
        else
          type = mime.contentType mimetype
          res.setHeader 'Content-Type', "#{type}; charset=utf-8"
          res.end data
  return

parse_post = (req, done) ->
  body = ''
  req.on 'data', (chunk) ->
    body += chunk
  req.on 'end', ->
    done if body isnt '' then qs.parse body else undefined

check_etag = (req, res, fullpath) ->
  headers = req.headers
  match = headers['if-none-match']
  try
    stats = fs.statSync fullpath
  catch err
    return false
  etag = Etag stats
  res.setHeader 'ETag', etag
  if match? and etag is match
    res.writeHead 304, 'Not Modified'
    res.end()
    true
  else false
