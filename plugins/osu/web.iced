cli = require 'cli-color'

codes = {}

osuLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode0'
taikoLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode1'
ctbLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode2'
omLeaderboard = new Mikuia.Models.Leaderboard 'osuRankMode3'

leaderboard = [
	osuLeaderboard
	taikoLeaderboard
	ctbLeaderboard
	omLeaderboard
]

modes = [
	'osu!'
	'Taiko'
	'Catch the Beat'
	'osu!mania'
]

for lb, i in leaderboard
	lb.setDisplayColor '#f06292'
	lb.setDisplayName 'osu! - ' + modes[i] + ' Rank'
	lb.setDisplayHtml '<b style="color: #FC74B0;">#<%value%></b>'
	lb.setReverseOrder true

Mikuia.Element.register 'userPageSplashButton',
	plugin: 'osu'
	buttons: [
		{
			color: '#f06292'
			name: 'View osu! profile'
			linkFunction: (name) -> 'http://osu.ppy.sh/u/' + name
			setting: 'name'
		}
	]

Mikuia.Web.get '/dashboard/plugins/osu/auth', (req, res) =>
	res.render '../../plugins/osu/views/auth',
		verifyCommand: @Plugin.getSetting 'verifyCommand'

Mikuia.Web.post '/dashboard/plugins/osu/auth', (req, res) =>
	if req.body.authCode?

		await Mikuia.Database.get 'plugin:osu:auth:code:' +  req.body.authCode, defer error, username
		console.log username

		if username?
			Channel = new Mikuia.Models.Channel req.user.username

			await
				Channel.setSetting 'osu', 'name', username, defer err, data
				Mikuia.Database.hset 'plugin:osu:channels', username, Channel.getName(), defer errar, whatever
				
			@Plugin.Log.info 'Authenticated ' + cli.yellowBright(username) + '.'
			await Mikuia.Database.del 'plugin:osu:auth:code:' + req.body.authCode, defer error, whatever

	res.redirect '/dashboard/settings'

# np! continuing the old path so people don't have to reconfigure osu!np
Mikuia.Web.post '/plugins/osu/post/:username', (req, res) ->
	res.send 200