
OAuth = require('oauth').OAuth
Constants = require '../local/Constants'
Trello = require 'node-trello'
User = require '../local/User'

requestURL = "https://trello.com/1/OAuthGetRequestToken"
accessURL = "https://trello.com/1/OAuthGetAccessToken"
authorizeURL = "https://trello.com/1/OAuthAuthorizeToken"

secrets = {}

exports.index = (state, callback) ->
  if state.session.user?.token
    callback 'redirect', '/board/list'
  else
    callback
      heading: ''
      nav: ''

exports.login = (state, callback) ->
  loginCallback = "http://#{state.headers.host}/home/cb"
  oauth = new OAuth requestURL, accessURL, \
          Constants.trello.appkey, Constants.trello.secret, \
          '1.0', loginCallback, 'HMAC-SHA1'
  oauth.getOAuthRequestToken (err, token, tokenSecret, results) ->
    return console.log err if err
    secrets[token] = tokenSecret
    callback 'redirect',
      "#{authorizeURL}?oauth_token=#{token}&name=#{Constants.brand}&expiration=1day&scope=read"

exports.cb = (state, callback) ->
  oauth = new OAuth requestURL, accessURL, \
          Constants.trello.appkey, Constants.trello.secret, \
          '1.0', undefined, 'HMAC-SHA1'
  query = state.query
  token = query.oauth_token
  tokenSecret = secrets[token]
  verifier = query.oauth_verifier
  oauth.getOAuthAccessToken token, tokenSecret, verifier, \
    (err, accessToken, accessTokenSecret, results) ->
      console.log err if err
      delete secrets[token]
      return callback 'redirect', '/' if err
      console.log accessToken
      User.fetch accessToken
      .on 'ready', (user) ->
        state.session.user = user
        callback 'redirect', '/board/list'

exports.logoff = (state, callback) ->
#  token = state.session.user?.token
#  if token
#    trello = new Trello Constants.trello.appkey, token
#    trello.del "/1/tokens/#{token}", (err, data) ->
#      console.log "DELETE", err, data
  delete state.session.user
  callback 'redirect', '/'
