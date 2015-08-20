bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
express = require 'express.io'
fs = require 'fs-extra'
gm = require 'gm'
moment = require 'moment'
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

if Mikuia.settings.sentry.enable
	raven = require 'raven'
	app.use raven.middleware.express Mikuia.settings.sentry.dsn
else
	iced.catchExceptions()

app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
app.use express.static __dirname + '/public'
app.use cookieParser 'oijt09j4g09qjg90q3jk90q3'
app.use bodyParser.urlencoded
	extended: true
app.use bodyParser.json()
app.use morgan 'dev'
app.use session
	resave: false
	saveUninitialized: true
	secret: 'oijt09j4g09qjg90q3jk90q3'
	store: store
app.use passport.initialize()
app.use passport.session()
app.use (req, res, next) ->
	res.locals.Mikuia = Mikuia
	res.locals.moment = moment
	res.locals.path = req.path
	res.locals.user = req.user

	isBanned = false
	pages = []
	if req.user
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel.isBanned defer err, isBanned

		if !isBanned and req.path.indexOf('/dashboard') == 0
			pagePlugins = Mikuia.Element.getAll 'dashboardPagePlugin'
			for pagePlugin in pagePlugins || []
				await Channel.isPluginEnabled pagePlugin.plugin, defer err, enabled
				if !err && enabled
					for pagePath, {name, icon} of pagePlugin.pages
						pages.push {
							name, icon,
							path: '/dashboard/plugins/' + pagePlugin.plugin + pagePath
						}

	if !isBanned
		res.locals.pages = pages
		next()
	else
		res.send 'This account ("' + req.user.username + '") has been permanently banned from using Mikuia.'

fs.mkdirs 'web/public/img/avatars'

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
app.get '/badge/:badgeId', routes.community.badge
app.get '/guide', routes.community.guide
app.get '/leagues', checkAuth, routes.community.leagues
app.get '/leagues/leaderboards', routes.community.leagueleaderboards
app.get '/levels', routes.community.levels
app.get '/levels/:userId', routes.community.levels
app.get '/mlvl', routes.community.mlvl
app.get '/slack', routes.community.slack
app.post '/slack/invite', routes.community.slackInvite
app.get '/stats', routes.community.stats
app.get '/streams', routes.community.streams
app.get '/supporter', routes.community.support
app.get '/user/:userId', routes.community.user
app.get '/user/:userId/:subpage', routes.community.user

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

			Channel = new Mikuia.Models.Channel user.username
			await
				Channel.setDisplayName user._json.display_name, defer err, data
				Channel.setBio user._json.bio, defer err, data
				Channel.setEmail user.email, defer err, data
				Channel.enablePlugin 'base', defer err, data
				Channel.getInfo 'key', defer err, key

			if user._json.logo? && user._json.logo.indexOf('http') == 0
				await Channel.setLogo user._json.logo, defer err, data
			else
				await Channel.setLogo 'http://static-cdn.jtvnw.net/jtv_user_pictures/xarth/404_user_150x150.png', defer err, data

			if !key?
				key = rstring
					length: 20
				await Channel.setInfo 'key', key

			if req.session.redirectTo?
				res.redirect req.session.redirectTo
			else
				res.redirect '/'

			await Channel.updateAvatar defer err, whatever
	)(req, res, next)

app.listen Mikuia.settings.web.port

updateGithub = (callback) =>
	request 
		url: 'https://api.github.com/repos/Mikuia/Mikuia/commits'
		headers: 
			'User-Agent': 'Mikuia/0.0.0.0.1'
	, (error, response, body) =>
		if !error
			try
				json = JSON.parse body
			catch error
				if error
					Mikuia.Log.error error

			if json
				Mikuia.Stuff.githubCommits = json

				for commit in Mikuia.Stuff.githubCommits
					if commit.commit.message.indexOf('[') == 0
						commit.commit.message = commit.commit.message.replace '[add]', '<span class="label label-primary">add</span>'
						commit.commit.message = commit.commit.message.replace '[del]', '<span class="label label-danger">del</span>'
						commit.commit.message = commit.commit.message.replace '[fix]', '<span class="label label-success">fix</span>'

						commit.commit.message = commit.commit.message.replace '[bot]', '<span class="label label-default">bot</span>'
						commit.commit.message = commit.commit.message.replace '[coins]', '<span class="label label-warning">coins</span>'
						commit.commit.message = commit.commit.message.replace '[fun]', '<span class="label label-primary">fun</span>'
						commit.commit.message = commit.commit.message.replace '[levels]', '<span class="label label-warning">levels</span>'
						commit.commit.message = commit.commit.message.replace '[lol]', '<span class="label label-warning">lol</span>'
						commit.commit.message = commit.commit.message.replace '[mod]', '<span class="label label-danger">mod</span>'
						commit.commit.message = commit.commit.message.replace '[osu]', '<span class="label label-warning">osu</span>'
						commit.commit.message = commit.commit.message.replace '[rotmg]', '<span class="label label-warning">rotmg</span>'
						commit.commit.message = commit.commit.message.replace '[twitch]', '<span class="label label-info">twitch</span>'
						commit.commit.message = commit.commit.message.replace '[web]', '<span class="label label-info">web</span>'
						commit.commit.message = commit.commit.message.replace '[wow]', '<span class="label label-warning">wow</span>'
				
		else
			Mikuia.Log.error error
		callback error

setInterval () =>
	await updateGithub defer whatever
, 300000
Mikuia.Stuff.githubCommits = []
await updateGithub defer whatever
