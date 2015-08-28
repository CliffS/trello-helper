###

constants.coffee - local constants

###

esrever = require 'esrever'
Bunyan = require 'bunyan'
Entities = require 'htmlentities'
Path = require 'path'

exports.io = do require 'socket.io'

LIVE = switch
  when __dirname.match /\/live\// then 'live'
  when __dirname.match /\/proof\// then 'proof'
  when __dirname.match /\/cliff\// then 'cliff'
  else 'other'

exports.live = LIVE
exports.isLive = do (LIVE) ->
  LIVE is 'live'

suite = 'helper'
exports.socket =
  switch LIVE
    when 'live', 'proof'
      "/var/run/www/#{suite}-#{LIVE}.sock"
    else
      8085

exports.brand = 'Trello Helper'

process.umask 0o002

logger = do ->
  path = Path.join Path.dirname(__dirname), 'log'
  Bunyan.createLogger
    name: suite
    streams:
      [
        level: 'debug'
        path: Path.join path, 'debug.log'
        type: 'rotating-file'
        period: '1d'
        count: 14
      ,
        level: 'warn'
        path: Path.join path, 'error.log'
        type: 'rotating-file'
        period: '1w'
        count: 8
      ,
        level: 'info'
        path: Path.join path, 'info.log'
        type: 'rotating-file'
        period: '1w'
        count: 8
      ]

exports.log = (section) ->
  return logger unless section
  logger.info "Creating section child: #{section}"
  logger.child section: section

exports.trello =
  appkey:  'c123d12b6afd39d86af870f700f9f31f'
  secret:  'f93cd85a1d1134df737219d00428eaf259a3fd1ee3033b2d066de6e487377745'

Number::format = ->
  @toFixed(2).replace /\d(?=(\d{3})+\.)/g, '$&,'

String::format = ->
  parseFloat(@).format()

String::unformat = ->
  parseFloat @.replace ',', ''

String::reverse = ->
  esrever.reverse @

String::decode = ->
  Entities.decode @

String::wordUpper = ->
  s = @toLowerCase()
  s.replace /\b\w/g, (char) ->
    char.toUpperCase()

Date::formatted = ->
  months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ]
  day = @getDate()
  month = months[@getMonth()]
  year = @getFullYear()
  "#{day} #{month} #{year}"

Date::ymd = ->
  day = "0#{@getDate()}".substr(-2)
  month = "0#{@getMonth() + 1}".substr(-2)
  year = @getFullYear()
  "#{year}-#{month}-#{day}"

Date::hm = ->
  @toTimeString().substr 0, 5

Date::hms = ->
  @toTimeString().substr 0, 8
