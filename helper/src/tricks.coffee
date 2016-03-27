
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
    board_fields: 'name,desc,descData,idOrganization,shortUrl,starred,prefs'
  , (err, result) ->
    return callback 'redirect', '/home/logoff' if err?.statusCode is 401
    return callback 'redirect', '/' if result.boards.length is 0
    for b in result.boards
      image = b.prefs.backgroundImageScaled?[1].url ? b.prefs.backgroundImage
      b.style = if image?
        "background-image:url('#{image}');"
      else
        "background-color:#{b.prefs.backgroundColor}"
    board = result.boards[0]
    board.active = true
    trello.get "/1/boards/#{board.id}",
      lists: 'open'
    , (err, data) ->
      return callback 'redirect', '/home/logoff' if err?.statusCode is 401
      callback (if state.query.debug then 'debug' else 'render'),
        boards: result.boards
        lists: data.lists
        include: 'tricks'       # coffee file to include
        board: board
        list: data.lists[0]

  io = Constants.io.of '/tricks'
  io.on 'connection', (socket) ->
  # console.log "connected"
    socket.on 'select', (id) ->
      trello.get "/1/boards/#{id}",
        lists: 'open'
      , (err, data) ->
        return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
        socket.emit 'lists', data.lists
    socket.on 'list-chosen', (id) ->
      trello.get "/1/list/#{id}",
        cards: 'open'
        board: true
        board_fields: 'name,shortUrl'
        fields: 'name,pos'
      , (err, list) ->
        return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
        list.cards = list.cards.length
        socket.emit 'list-selected', list
        state.session.list = list
        do state.session.save

