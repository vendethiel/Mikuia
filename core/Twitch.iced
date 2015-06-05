request = require 'request'
twitchy = require 'twitchy'

class exports.Twitch
	constructor: (@Mikuia) ->

	init: ->
		if @Mikuia.settings.twitch.key != 'TWITCH_API_KEY' && @Mikuia.settings.twitch.secret != 'TWITCH_API_SECRET'
			@twitch = new twitchy {
				key: @Mikuia.settings.twitch.key
				secret: @Mikuia.settings.twitch.secret
			}
		else
			@Mikuia.Log.fatal 'Please specify correct Twitch API key and secret.'

	getChatters: (channel, callback) ->
		channel = channel.replace('#', '')
		request 'http://tmi.twitch.tv/group/user/' + channel + '/chatters', (error, response, body) ->
			if !error && response.statusCode == 200
				data = {}
				try
					data = JSON.parse body
				catch e
					console.log e
				callback false, data
			else
				callback true, null

	getStreams: (channels, callback) ->
		completed = false
		setTimeout () =>
			if !completed
				callback true, 'Timed out.'
		, 10000
		@twitch._get 'streams/?channel=' + channels.join(','), (err, result) =>
			if err || not result.req.res.body?.streams?
				if !completed
					@Mikuia.Log.error 'Failed to obtain stream list from Twitch API.'
					callback true, null
					completed = true
			else
				if !completed
					callback err, result.req.res.body.streams
					completed = true
