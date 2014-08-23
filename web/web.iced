bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
express = require 'express.io'
fs = require 'fs'
gm = require 'gm'
morgan = require 'morgan'
passport = require 'passport'
path = require 'path'
request = require 'request'
rstring = require 'random-string'
session = require 'express-session'

RedisStore = require('connect-redis')(session)
TwitchStrategy = require('passport-twitchtv').Strategy

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	else
		req.session.redirectTo = req.path
		res.redirect '/login'

store = new RedisStore
	host: Mikuia.settings.redis.host
	port: Mikuia.settings.redis.port
	db: Mikuia.settings.redis.db
	pass: Mikuia.settings.redis.options.auth_pass

routes = {}
module.exports = app = express()
app.http().io()

passport.serializeUser (user, done) ->
	done null, user

passport.deserializeUser (obj, done) ->
	done null, obj

passport.use new TwitchStrategy
	clientID: Mikuia.settings.twitch.key
	clientSecret: Mikuia.settings.twitch.secret
	callbackURL: Mikuia.settings.twitch.callbackURL
	scope: 'user_read'
, (accessToken, refreshToken, profile, done) ->
	process.nextTick () ->
		return done null, profile

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
#app.use morgan 'dev'
app.use express.static __dirname + '/public'
app.use cookieParser 'oijt09j4g09qjg90q3jk90q3'
app.use bodyParser()
app.use session
	secret: 'oijt09j4g09qjg90q3jk90q3'
	store: store
app.use passport.initialize()
app.use passport.session()
app.use (req, res, next) ->
	res.locals.Mikuia = Mikuia
	res.locals.path = req.path
	res.locals.user = req.user

	pages = []
	if req.user && req.path.indexOf('/dashboard') == 0
		Channel = new Mikuia.Models.Channel req.user.username
		pagePlugins = Mikuia.Element.getAll 'dashboardPagePlugin'
		for pagePlugin in pagePlugins
			await Channel.isPluginEnabled pagePlugin.plugin, defer err, enabled
			if !err && enabled
				for pagePath, page of pagePlugin.pages
					pages.push
						path: '/dashboard/plugins/' + pagePlugin.plugin + pagePath
						name: page.name
						icon: page.icon

	res.locals.pages = pages
	next()

fileList = fs.readdirSync 'web/routes'
for file in fileList
	filePath = path.resolve 'web/routes/' + file
	routes[file.replace('.iced', '')] = require filePath

app.get '/dashboard', checkAuth, routes.dashboard
app.get '/dashboard/commands', checkAuth, routes.commands.commands
app.get '/dashboard/commands/settings/:name', checkAuth, routes.commands.settings
app.get '/dashboard/settings', checkAuth, routes.settings.settings
app.get '/login', routes.login
app.get '/logout', (req, res) ->
	req.logout()
	res.redirect '/'

app.post '/dashboard/commands/add', checkAuth, routes.commands.add
app.post '/dashboard/commands/remove', checkAuth, routes.commands.remove
app.post '/dashboard/commands/save/:name', checkAuth, routes.commands.save
app.post '/dashboard/settings/plugins/toggle', checkAuth, routes.settings.pluginToggle
app.post '/dashboard/settings/save/:name', checkAuth, routes.settings.save
app.post '/dashboard/settings/toggle', checkAuth, routes.settings.toggle

app.get '/', routes.community.index
app.get '/streams', routes.community.streams
app.get '/user/:userId', routes.community.user

app.get '/auth/twitch', passport.authenticate('twitchtv', { scope: [ 'user_read' ] })
app.get '/auth/twitch/callback', (req, res, next) =>
	passport.authenticate('twitchtv', (err, user, info) ->
		if err
			console.log 'here!'
			return res.render 'community/error',
				error: err
		if !user
			return res.redirect '/login'
		req.logIn user, (err) =>
			if err
				return res.render 'community/error',
					error: err

			console.log user

			if req.session.redirectTo?
				res.redirect req.session.redirectTo
			else
				res.redirect '/dashboard'
	)(req, res, next)

	# Channel = new Mikuia.Models.Channel req.user.username
	# await
	# 	Channel.setDisplayName req.user._json.display_name, defer err, data
	# 	Channel.setBio req.user._json.bio, defer err, data
	# 	Channel.setEmail req.user.email, defer err, data
	# 	Channel.setLogo req.user._json.logo, defer err, data
	# 	Channel.enablePlugin 'base', defer err, data
	# 	Channel.getInfo 'key', defer err, key

	# # Generating an API key on login if missing
	# if !key?
	# 	key = rstring
	# 		length: 20
	# 	await Channel.setInfo 'key', key, defer err, whatever

	

	# await Channel.updateAvatar defer err, whatever

app.listen 2912