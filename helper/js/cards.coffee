
$ ->
  socket = io '/board/cards'
  socket.on 'connect', ->
    manager = socket.io

  $('a.details').click (e) ->
    e.preventDefault()
    socket.emit 'details', $(@).attr 'href'

  socket.on 'alert', (data) ->
    alert data
  .on 'redirect', (loc) ->
    alert "redirect: #{loc}"
    location.replace loc
  .on 'card', (card) ->
    $('#temp').html """
      <pre>
      #{JSON.stringify card, null, 2}
      </pre>
      """
  .on 'card-html', (html) ->
    $('#card-html').html html
