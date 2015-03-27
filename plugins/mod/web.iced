request = require 'request'

module.exports =
	elements: [
		name: 'dashboardPagePlugin',
		pages:
				'/':
				name: 'Mod Tools'
				icon: 'icon-settings'
	]

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'


Mikuia.Web.get '/dashboard/plugins/mod', checkAuth, (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username
	await Channel._smembers 'plugin:mod:bannedWords', defer whatever, words
	await Channel._smembers 'plugin:mod:whitelistedDomains', defer whatever, domains

	res.render '../../plugins/mod/views/index',
		domains: domains
		words: words

Mikuia.Web.post '/dashboard/plugins/mod/words/add', checkAuth, (req, res) ->
	if req.body.word?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._sadd 'plugin:mod:bannedWords', req.body.word.trim(), defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/words/remove', checkAuth, (req, res) ->
	if req.body.word?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._srem 'plugin:mod:bannedWords', req.body.word, defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/domains/add', checkAuth, (req, res) ->
	if req.body.domain?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._sadd 'plugin:mod:whitelistedDomains', req.body.domain.trim(), defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/domains/remove', checkAuth, (req, res) ->
	if req.body.domain?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._srem 'plugin:mod:whitelistedDomains', req.body.domain, defer whatever, reply

	res.send 200
