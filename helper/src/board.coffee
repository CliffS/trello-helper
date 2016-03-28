
Constants = require '../local/Constants'
User = require '../local/User'
Trello = require 'node-trello'
Async = require 'async'
Mustache = require '../vendor/mustache-simple'
Path = require 'path'
Markdown = require 'marked'


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
    return callback 'redirect', '/home/logoff' if err?.statusCode is 401
    cards = {}
    cards[card.id] = card for card in data.cards
    label.uses = undefined for label in data.labels when label.uses is -1
    ch.card = cards[ch.idCard] for ch in data.checklists
    callback (if state.query.debug? then 'debug' else 'render'),
      board: data
      user: state.session.user

exports.cards = (state, callback) ->
  [ board, list ] = state.params
  trello = new Trello Constants.trello.appkey, state.session.user.token
  Async.parallel
    open: (callback) ->
      trello.get "/1/lists/#{list}",
        cards: 'open'
        card_fields: 'name,desc,pos,shortUrl'
        board: true
        board_fields: 'name'
      , callback
    closed: (callback) ->
      trello.get "/1/lists/#{list}",
        cards: 'closed'
        card_fields: 'name,desc,pos,shortUrl'
      , callback
  , (err, results) ->
    return callback 'redirect', '/home/logoff' if err?.statusCode is 401
    throw err if err
#    callback 'debug', results
    callback # 'debug',
      results: [
        type: 'Open'
        cards: results.open.cards
      ,
        type: 'Archived'
        cards: results.closed.cards
      ]
      user: state.session.user
      header: "Board: #{results.open.board.name}, List: #{results.open.name}"
      include: 'cards'

  io = Constants.io.of '/board/cards'
  io.on 'connection', (socket) ->

    socket.on 'details', (id) ->
      trello.get "/1/cards/#{id}",
        actions: 'all'
        actions_limit: 1000
      , (err, card) ->
        return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
        # socket.emit 'card', card
        created = a for a in card.actions when a.type is 'createCard'
        response =
          id: card.id
          fields: [
            key: 'Name'
            value: card.name
          ,
            key: 'Description'
            value: do (desc = card.desc) ->
#              max = 200
#              desc = "#{desc.substr 0, max}..." if desc.length > max
#              desc
              Markdown desc
          ,
            key: 'URL'
            value: card.url
            url: card.shortUrl
          ,
            key: 'Short URL'
            value: card.shortUrl
            url: card.shortUrl
          ,
            key: 'Archived'
            value: JSON.stringify card.closed
          ,
            key: 'Created'
            value: if created then new Date(created.date).formatted()
          ,
            key: 'Created by'
            value: do (who = created.memberCreator) ->
              "#{who.fullName} (#{who.username})" if created
          ,
            key: 'Last active'
            value: new Date(card.dateLastActivity).formatted()
          ,
            key: 'Last change'
            value: do (action = card.actions[0]) ->
              "#{action.type} by #{action.memberCreator.fullName}" if action
          ]
        mus = new Mustache
          extension: 'mustache'
          path: Path.join Path.dirname(__dirname), 'templates', 'board'
        html = mus.render 'cards-details', response
        socket.emit 'card-html', html
