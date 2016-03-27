
$ ->
  socket = io "/tricks"
  socket.on "connect", ->
    manager = socket.io

  $('.select-board').click (e) ->
    e.preventDefault()
    socket.emit 'select', $(@).attr 'href'

  $('#lists').on 'click', 'a', (e) ->
    e.preventDefault()
    socket.emit 'list-chosen', $(@).attr 'href'
    $('#lists .nav-pills li.active').removeClass 'active'
    $(@).closest('li').addClass 'active'

  $('#sort-modal').on 'hidden.bs.modal', (e) ->
    $('#lists .active').removeClass 'active'

  socket.on 'alert', (data) ->
    alert data
  .on 'redirect', (loc) ->
    location = loc
  .on 'lists', (lists) ->
    $lists = $ '#lists'
    $lists.empty()
    for list in lists
      item = $ """
        <li>
        <a href="#{list.id}">#{list.name}</a>
        </li>
        """
      $lists.append item
    return
  .on 'list-selected', (data) ->
    $('#board-name').html data.board.name
    $('#list-name').html data.name
    $('#card-count').html data.cards
    $('form select option:first-child').prop 'selected', true
    $('#open').attr 'href', data.board.shortUrl
    $('#sort-modal').modal 'show'

    
