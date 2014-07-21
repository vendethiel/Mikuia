cli = require 'cli-color'
irc = require 'slate-irc'
net = require 'net'
request = require 'request'
RateLimiter = require('limiter').RateLimiter

apiLimiter = new RateLimiter 30, 60000
banchoLimiter = new RateLimiter 1, 'second'
codes = {}
userData = {}

# Crucial stuff, whatever!

banchoSay = (name, message) =>
	banchoLimiter.removeTokens 1, (err, rr) =>
		@bancho.send name, message

checkForRequest = (user, Channel, message) =>

	continueCheck = true
	await Channel.getSetting 'osu', 'requestSubMode', defer err, requestSubMode
	if !err && requestSubMode
		if user.special.indexOf('subscriber') == -1
			continueCheck = false

	if continueCheck
		if /osu.ppy.sh\/(b|s)\/(\d+)/g.test message
			match = /osu.ppy.sh\/(b|s)\/(\d+)/g.exec message
			
			await
				Channel.getSetting 'osu', 'name', defer err, username
				Channel.getSetting 'osu', 'mode', defer err2, mode

			if !err && username != ''
				await getBeatmap match[2], match[1], defer err, beatmaps
				if !err && beatmaps.length
					switch match[1]
						when 'b'
							sendRequest Channel, user, username, beatmaps[0]
						when 's'
							customModes = false
							preferredMode = '0'
							if !err2
								preferredMode = mode

							maps = []
							for i, map of beatmaps
								if map.mode == preferredMode
									maps.push map

							if maps.length == 0
								maps = beatmaps
								preferredMode = '0'

							highestDifficultyRating = 0
							highestDifficultyMap = null

							for i, map of maps
								if map.difficultyrating > highestDifficultyRating && map.mode == preferredMode
									highestDifficultyRating = map.difficultyrating
									highestDifficultyMap = map

							sendRequest Channel, user, username, highestDifficultyMap

makeAPIRequest = (link, callback) =>
	apiLimiter.removeTokens 1, (err, rr) =>
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

sendRequest = (channel, user, username, map) =>
	await
		channel.getSetting 'osu', 'chatRequestFormat', defer err, chatRequestFormat
		channel.getSetting 'osu', 'osuRequestFormat', defer err2, osuRequestFormat
		channel.getSetting 'osu', 'requestChatInfo', defer err3, requestChatInfo

	modeText = 'osu!'
	approvedText = 'Ranked'
	switch map.mode
		when '1' then modeText = 'Taiko'
		when '2' then modeText = 'Catch the Beat'
		when '3' then modeText = 'osu!mania'

	switch map.approved
		when '3' then approvedText = 'Qualified'
		when '2' then approvedText = 'Approved'
		when '0' then approvedText = 'Pending'
		when '-1' then approvedText = 'WIP'
		when '-2' then approvedText = 'Graveyard'

	data =
		requester: user.username
		beatmapset_id: map.beatmapset_id
		beatmap_id: map.beatmap_id
		approved: map.approved
		approved_date: map.approved_date
		approvedText: approvedText
		last_update: map.last_update
		total_length: map.total_length
		hit_length: map.hit_length
		version: map.version
		artist: map.artist
		title: map.title
		creator: map.creator
		bpm: map.bpm
		source: map.source
		difficultyrating: map.difficultyrating
		diff_size: map.diff_size
		diff_overall: map.diff_overall
		diff_approach: map.diff_approach
		diff_drain: map.diff_drain
		mode: map.mode
		modeText: modeText

	# Chat
	if !err && requestChatInfo
		Mikuia.Chat.say channel.getName(), Mikuia.Format.parse chatRequestFormat, data

	# osu!
	if !err2
		banchoSay username, Mikuia.Format.parse osuRequestFormat, data

# API functions.

getBeatmap = (id, type, callback) ->
	await makeAPIRequest '/get_beatmaps?' + type + '=' + id, defer err, data
	callback err, data

getUser = (name, mode, callback) ->
	await makeAPIRequest '/get_user?u=' + name + '&m=' + mode + '&type=string', defer err, data
	callback err, data

Mikuia.Events.on 'twitch.connected', =>
	stream = net.connect
		port: 6667
		host: 'cho.ppy.sh'

	@bancho = irc stream
	@bancho.pass @Plugin.getSetting 'password'
	@bancho.nick @Plugin.getSetting 'name'
	@bancho.user @Plugin.getSetting 'name', 'Mikuia - a Twitch.tv bot // http://mikuia.tv'

	@bancho.on 'welcome', (nick) =>
		@Plugin.Log.success 'Logged in to osu!Bancho as ' + nick + '.'

	@bancho.on 'message', (message) =>
		@Plugin.Log.info cli.yellowBright(message.from) + ': ' + cli.whiteBright(message.message)
		if message.message == '!verify'
			code = Math.floor(Math.random() * 900000) + 100000
			codes[code] = message.from
			banchoSay message.from, 'Your code is ' + code + '. You have only a minute to save the wo... I mean to put it on page...'
			setTimeout () ->
				delete codes[code]
			, 60000

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	Channel = new Mikuia.Models.Channel to
	await Channel.getSetting 'osu', 'requests', defer err, requestsEnabled
	if !err && requestsEnabled
		checkForRequest user, Channel, message

Mikuia.Events.on 'osu.request', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	checkForRequest data.from, Channel, data.message

Mikuia.Events.on 'osu.stats', (data) =>
	tokens = data.tokens
	tokens.splice 0, 1
	username = tokens.join ' '

	await getUser username, 0, defer err, user

	Mikuia.Chat.say data.to, Mikuia.Format.parse data.settings.format,
		username: user[0].username
		id: user[0].user_id
		rank: user[0].pp_rank
		pp: user[0].pp_raw
		count300: user[0].count300
		count100: user[0].count100
		count50: user[0].count50
		playcount: user[0].playcount
		ranked_score: user[0].ranked_score
		total_score: user[0].total_score
		level: user[0].level
		accuracy: user[0].accuracy
		rank_ss: user[0].count_rank_ss
		rank_s: user[0].count_rank_s
		rank_a: user[0].count_rank_a
		country: user[0].country

Mikuia.Web.get '/dashboard/plugins/osu/auth', (req, res) ->
	res.render '../../plugins/osu/views/auth'

Mikuia.Web.post '/dashboard/plugins/osu/auth', (req, res) =>
	if req.body.authCode? && codes[req.body.authCode]?
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.setSetting 'osu', 'name', codes[req.body.authCode], defer err, data
		@Plugin.Log.info 'Authorized ' + cli.yellowBright(codes[req.body.authCode]) + '.'
		delete codes[req.body.authCode]

	res.redirect '/dashboard/settings'

setInterval () =>
	await Mikuia.Database.smembers 'mikuia:streams', defer err, streams
	
	if !err && streams?
		for stream in streams
			await Mikuia.Database.hget 'mikuia:stream:' + stream, 'game', defer err, game
			if !err && game == 'Osu!'
				Channel = new Mikuia.Models.Channel stream
				await Channel.getSetting 'osu', 'updates', defer err, updates
				if !err && updates
					await
						Channel.getSetting 'osu', 'name', defer err, name
						Channel.getSetting 'osu', 'mode', defer err2, mode
					if !err && name?

						if err2
							mode = 0

						await getUser name, mode, defer err, stats
						if !err
							stats = stats[0]

							if userData[name]?[mode]?
								data = userData[name][mode]

								if data.pp_raw != stats.pp_raw
									pp_change = stats.pp_raw - data.pp_raw
									rank_change = (stats.pp_rank - data.pp_rank) * -1
									acc_change = stats.accuracy - data.accuracy

									if pp_change >= 0
										pp_updown = 'up'
										pp_sign = '+'
									else
										pp_updown = 'down'
										pp_sign = ''

									if rank_change >= 0
										rank_updown = 'up'
										rank_sign = '+'
									else
										rank_updown = 'down'
										rank_sign = ''

									if acc_change >= 0
										acc_updown = 'up'
										acc_sign = '+'
									else
										acc_updown = 'down'
										acc_sign = ''


									await
										Channel.getSetting 'osu', 'rankChangeFormat', defer err, rankChangeFormat
										Channel.getSetting 'osu', 'updateDelay', defer err, updateDelay
									if !err

										setTimeout () =>
											Mikuia.Chat.say stream, Mikuia.Format.parse rankChangeFormat,
												pp_new: stats.pp_raw
												pp_old: data.pp_raw
												pp_change: pp_change
												pp_updown: pp_updown
												pp_sign: pp_sign
												rank_new: stats.pp_rank
												rank_old: data.pp_rank
												rank_change: rank_change
												rank_updown: rank_updown
												rank_sign: rank_sign
												acc_new: stats.accuracy
												acc_old: data.accuracy
												acc_change: acc_change
												acc_updown: acc_updown
												acc_sign: acc_sign
										, updateDelay * 1000

							if !userData[name]?
								userData[name] = {}
							userData[name][mode] = stats
, 5000