cli = require 'cli-color'
irc = require 'node-twitch-irc'

class exports.Chat
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	connect: ->
		###
			Better safe than sorry,
			better safe than sorry,
			better safe than sorry...
		###
		@client = new irc.connect {
			autoreconnect: true
			channels: []
			debug: @Mikuia.settings.bot.debug
			names: true
			nickname: @Mikuia.settings.bot.name
			port: 6667
			server: 'irc.twitch.tv'
			oauth: @Mikuia.settings.bot.oauth
		}, (err, event) =>
			if !err
				event.on 'chat', (user, channel, message) =>
					@handleMessage(user, channel, message)

				event.on 'connected', =>
					@Mikuia.Log.info 'Connected to Twitch IRC.'

				event.on 'join', (channel) =>
					@Mikuia.Log.info 'Joined ' + channel + '.'
			else
				@Mikuia.Log.error err

	handleMessage: (from, to, message) ->
		@Mikuia.Log.info '(' + cli.greenBright(to) + ') ' + cli.yellowBright(from.username) + ': ' + cli.whiteBright(message)

	join: (channel) ->
		@client.join channel

	say: (channel, message) ->
		@client.say channel, message