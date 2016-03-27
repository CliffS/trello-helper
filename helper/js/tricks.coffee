
$ ->
  socket = io "/tricks"
  socket.on "connect", ->
    manager = socket.io

  $('.select-board').click (e) ->
    e.preventDefault()
    socket.emit 'select', $(@).attr 'href'
    $('.nav-pills li.active').removeClass 'active'
    $(@).closest('li').addClass 'active'

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
        <a href="/tricks/sorter/#{list.idBoard}/#{list.id}" class="select-list">
        #{list.name}
        </a>
        </li>
        """
      $lists.append item
    return
