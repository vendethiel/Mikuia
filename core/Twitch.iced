twitchy = require 'twitchy'

class exports.Twitch
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	init: ->
		if @Mikuia.settings.twitch.key != 'TWITCH_API_KEY' && @Mikuia.settings.twitch.secret != 'TWITCH_API_SECRET'
			@twitch = new twitchy {
				key: @Mikuia.settings.twitch.key
				secret: @Mikuia.settings.twitch.secret
			}
		else
			@Mikuia.Log.fatal 'Please specify correct Twitch API key and secret.'
			process.exit()

	getStreams: (channels, callback) ->
		@twitch._get 'streams/?channel=' + channels.join ',', (err, result) =>
			if err
				Mikuia.Log.error 'Failed to obtain stream list from Twitch API.'
			else
				console.log result