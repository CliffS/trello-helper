
$ ->
  socket = io "/tricks"
  socket.on "connect", ->
    manager = socket.io
#    .on 'disconnect', ->
#      alert 'Disconnected'
#    .on 'reconnect', ->
#      alert 'Reconnected'

  $('.select-board').click (e) ->
    e.preventDefault()
    socket.emit 'select', $(@).attr 'href'
    $('.active').removeClass 'active'
    $(@).closest('li').addClass 'active'
    $(@).blur()

  $('#lists').on 'click', 'a', (e) ->
    e.preventDefault()
    socket.emit 'list-chosen', $(@).attr 'href'
    $('#lists .nav-pills li.active').removeClass 'active'
    $(@).closest('li').addClass 'active'

  $('#sort-modal').on 'hidden.bs.modal', (e) ->
    $('#lists .active').removeClass 'active'

  $('#sort-modal form').submit (e) ->
    e.preventDefault()
    socket.emit 'do-sort', $(@).serializeArray()
    $('#sort-modal .progress-bar').width "0%"
    $('#sort-modal .progress-bar').addClass "active"
    $('#sort-modal .btn').prop 'disabled', true
    $('#sort-modal .btn').addClass 'disabled'


  socket.on 'alert', (data) ->
    alert data
  .on 'redirect', (loc) ->
    alert "redirect: #{loc}"
    location.replace loc
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
    $('#list_id').val data.id
    $('#card-count').html if data.cards is 0 then "None" else data.cards
    $('#sort-modal button[type="submit"]').prop 'disabled', data.cards is 0
    $('#sort-modal .progress-bar').attr 'aria-valuemax', data.cards
#    $('form select option:first-child').prop 'selected', true
    $('#open').attr 'href', data.board.shortUrl
    $('#sort-modal').modal 'show'
  .on 'bump', (counter) ->
    $('#sort-modal .progress-bar').width "#{counter}%"
    if counter is 100
      $('#sort-modal .progress-bar').removeClass 'active'
      $('#sort-modal .btn').prop 'disabled', false
      $('#sort-modal .btn').removeClass 'disabled'
    

    
