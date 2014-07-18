request = require 'request'
RateLimiter = require('limiter').RateLimiter

limiter = new RateLimiter 30, 60000

# Crucial stuff, whatever!

makeRequest = (link, callback) =>
	limiter.removeTokens 1, (err, rr) =>
		request 'https://osu.ppy.sh/api' + link + '&k=' + @Plugin.getSetting('apiKey'), (error, response, body) ->
			if !error && response.statusCode == 200
				data = {}
				try
					data = JSON.parse body
				catch e
					console.log e
				callback false, data
			else
				callback true, null

# API functions.

getUser = (name, mode, callback) ->
	await makeRequest '/get_user?u=' + name + '&m=' + mode + '&type=string', defer err, data
	callback err, data

Mikuia.Events.on 'twitch.message', (from, to, message) =>
	# Beatmaps later :P

Mikuia.Events.on 'osu.stats', (data) =>
	tokens = data.tokens
	tokens.splice(0, 1)
	username = tokens.join(' ')

	await getUser username, 0, defer err, user

	#Mikuia.Chat.say data.to, 'Stats for ' + user[0].username + ': ' + user[0].pp_raw + 'pp, rank: #' + user[0].pp_rank

	Mikuia.Chat.say data.to, Mikuia.Format.parse data.settings.format,
		rank: user[0].pp_rank
		pp: user[0].pp_raw
		username: user[0].username