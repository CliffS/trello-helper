
Constants = require '../local/Constants'
User = require '../local/User'
Trello = require 'node-trello'
Async = require 'async'

exports.heading = "Trello tricks"

exports.index = (state, callback) ->
  callback {}

exports.sort = (state, callback) ->
  return callback 'redirect', '/home/logoff' unless state.session.user?.token
  trello = new Trello Constants.trello.appkey, state.session.user.token
  trello.get "/1/members/me",
    boards: 'open'
    board_fields: 'name,desc,descData,idOrganization,shortUrl,starred'
  , (err, result) ->
    return callback 'redirect', '/home/logoff' if err?.statusCode is 401
    unless result.boards.length is 0
      board = result.boards[0]
      board.active = true
      trello.get "/1/boards/#{board.id}",
        lists: 'open'
      , (err, data) ->
        return callback 'redirect', '/home/logoff' if err?.statusCode is 401
        callback # 'debug',
          boards: result.boards
          lists: data.lists
          include: 'tricks'

  io = Constants.io.of '/tricks'
  io.on 'connection', (socket) ->
  # console.log "connected"
    socket.on 'select', (id) ->
      trello.get "/1/boards/#{id}",
        lists: 'open'
      , (err, data) ->
        return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
        socket.emit 'lists', data.lists
        console.log data.lists

exports.sorter = (state, callback) ->
  [ board, list ] = state.params
  trello = new Trello Constants.trello.appkey, state.session.user.token
  trello.get "/1/list/#{list}",
    cards: 'open'
    card_fields: 'dateLastActivity,name,desc,due'
    board: true
    board_fields: 'name'
    fields: 'name'
  , (err, data) ->
      return callback 'redirect', '/home/logoff' if err?.statusCode is 401
      callback 'debug', data
