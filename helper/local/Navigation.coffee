
NAVIGATION = [
  label: 'Boards'
  name:  'List Boards'
  url:   '/board/list'
  role:  'user'
]

exports.navigation = (path, user) ->
  navs = JSON.parse JSON.stringify NAVIGATION
  return navs unless user?  # Will not return to server as new User is called
  navs = (nav for nav in navs when user.can nav.role)
  nav.active = true for nav in navs when nav.url is path
  navs
