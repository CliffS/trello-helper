
Constants = require '../local/Constants'
Trello = require 'node-trello'
Async = require 'async'

exports.heading = "Trello Web Hooks"

exports.index = (state, callback) ->
  token = state.session.user?.token
  console.log "real token: #{token}"
  token = '2b840d713da9970313d189f3a2b30af660c06fef21cb8617e40b34fffa5f05a0'
  return callback 'redirect', '/' unless token
  trello = new Trello Constants.trello.appkey, state.session.user.token
  trello.get "/1/type/groupfirst", (err, type) ->
    trello.get "/1/token/#{token}/webhooks", (err, data) ->
      callback 'debug',
        err: err
        data: data
        type: type
        user: state.session.user
