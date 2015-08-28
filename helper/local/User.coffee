
EventEmitter = require('events').EventEmitter
Trello = require 'node-trello'
Constants = require './Constants'

class User extends EventEmitter

  constructor: (params) ->
    @[key] = val for key, val of params
    process.nextTick =>
      @emit 'ready', @

  @fetch: (token) ->
    ee = new EventEmitter
    unless token
      return process.nextTick =>
        ee.emit 'error', "Missing token"
    trello = new Trello Constants.trello.appkey, token
    trello.get "/1/members/me", (err, data) =>
      return ee.emit 'error', err if err
      user = new @ data
      user.token = token
      ee.emit 'ready', user
    ee


module.exports = User
