
Constants = require '../local/Constants'
User = require '../local/User'
Trello = require 'node-trello'
Async = require 'async'

exports.heading = "Trello boards"

exports.list = (state, callback) ->
  trello = new Trello Constants.trello.appkey, state.session.user.token
  Async.parallel
    open: (callback) ->
      trello.get "/1/members/me",
        boards: 'open'
        board_organization: true
        tokens: 'all'
      , callback
    closed: (callback) ->
      trello.get "/1/members/me",
        boards: 'closed'
        board_organization: true
      , callback
    , (err, results) ->
      throw err if err
      callback # 'debug',
        results: [
          type: 'Open'
          boards: results.open.boards
        ,
          type: 'Closed'
          boards: results.closed.boards
        ]
        user: state.session.user
