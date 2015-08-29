
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
        board_organization_fields: 'name,displayName,url'
        board_fields: 'name,desc,descData,idOrganization,shortUrl,starred'
      , callback
    closed: (callback) ->
      trello.get "/1/members/me",
        boards: 'closed'
        board_organization: true
        board_organization_fields: 'name,displayName,url'
        board_fields: 'name,desc,descData,idOrganization,shortUrl,starred'
      , callback
    , (err, results) ->
      return callback 'redirect', '/home/logoff' if err?.statusCode is 401
      callback # 'debug',
        results: [
          type: 'Open'
          boards: results.open.boards
        ,
          type: 'Closed'
          boards: results.closed.boards
        ]
        user: state.session.user

exports.detail = (state, callback) ->
  board = state.params[0]
  trello = new Trello Constants.trello.appkey, state.session.user.token
  trello.get "/1/boards/#{board}",
    cards: 'all'
    card_fields: 'name,closed,due,shortUrl'
    labels: 'all'
    lists: 'all'
    list_fields: 'all'
    checklists: 'all'
    checklist_fields: 'all'
    fields: 'name,desc,descData,closed,shortUrl'
  , (err, data) ->
    cards = {}
    cards[card.id] = card for card in data.cards
    label.uses = undefined for label in data.labels when label.uses is -1
    ch.card = cards[ch.idCard] for ch in data.checklists
    callback (if state.query.debug? then 'debug' else 'render'),
      board: data
      user: state.session.user

