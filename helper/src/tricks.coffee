
Constants = require '../local/Constants'
User = require '../local/User'
Trello = require 'node-trello'
# Async = require 'async'
RateLimiter = require('limiter').RateLimiter
limiter = new RateLimiter 80, 10 * 1000    # 100 requests in 10 secs

exports.heading = "Trello tricks"

exports.index = (state, callback) ->
  callback {}

exports.sort = (state, callback) ->
  return callback 'redirect', '/home/logoff' unless state.session.user?.token
  @heading = "Trello tricks: sort cards in a list"
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

    socket.on 'do-sort', (serialisedForm) ->
      form = {}
      form[f.name] = f.value for f in serialisedForm
      # console.log form
      [ lower, higher ] = if form.order is 'desc' then [ -1, 1 ] else [ 1, -1 ]
      sorter = switch form.criterion
        when 'name'
          (a, b) ->
            return 0 if a.name is b.name
            if a.name < b.name then lower else higher
        when 'activity'
          (a, b) ->
            datea = new Date a.dateLastActivity
            dateb = new Date b.dateLastActivity
            (datea - dateb) * higher
        when 'due'
          (a, b) ->
            if a.due or b.due
              datea = new Date a.due
              dateb = new Date b.due
              (datea - dateb) * higher
            else if a.name is b.name then 0
            else
              if a.name < b.name then lower else higher
        when 'created'
          (a, b) ->
            datea = new Date a.actions[0].date
            dateb = new Date b.actions[0].date
            (datea - dateb) * higher
        else throw new Error "Incorrect form criterion: #{form.criterion}"
      limiter.removeTokens 1, (err, remaining) ->
        trello.get "/1/lists/#{form.list_id}/cards",
          actions: 'createCard'
          cards: 'open'
          fields: 'name,dateLastActivity,due'
        , (err, cards) ->
          total = cards.length
          done = 1
          return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
          # console.log cards
          cards.sort sorter
          pushtop = ->
            limiter.removeTokens 1, (err, remaining) ->
              card = cards.shift()
              trello.put "/1/cards/#{card.id}",
                pos: 'top'
              , (err, data) ->
                return socket.emit 'redirect', '/home/logoff' if err?.statusCode is 401
                throw err if err
                socket.emit 'bump', Math.ceil done++ / total * 100
                do pushtop if cards.length
          do pushtop if cards.length




