
NAVIGATION = [
  label: 'Tricks'
  name:  'Useful tricks'
  url:   '/tricks'
  role:  'user'
,
  label: 'Board IDs'
  name:  'List board IDs'
  url:   '/board/list'
  group: '/board'
  role:  'user'
]

exports.navigation = (path, user) ->
  navs = JSON.parse JSON.stringify NAVIGATION
  return navs unless user?  # Will not return to server as new User is called
  navs = (nav for nav in navs when user.can nav.role)
  nav.regex = new RegExp '^' + (nav.group ? nav.url) for nav in navs
  nav.active = true for nav in navs when path.match nav.regex
  navs
