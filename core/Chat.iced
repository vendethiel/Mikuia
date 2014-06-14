cli = require 'cli-color'
irc = require 'irc'

class exports.Chat
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	connect: ->
		###
			Better safe than sorry,
			better safe than sorry,
			better safe than sorry...
		###
		@client = new irc.Client 'irc.twitch.tv', @Mikuia.settings.bot.name, {
			nick: @Mikuia.settings.bot.name
			userName: @Mikuia.settings.bot.name
			realName: 'Mikuia/Lukanya - a Twitch.tv bot // http://mikuia.tv'
			password: @Mikuia.settings.bot.oauth
			autoRejoin: false
			debug: @Mikuia.settings.bot.debug
			showErrors: true
		}

		@client.on 'registered', =>
			@Mikuia.Log.info 'Connected to Twitch IRC.'

		@client.on 'error', (err) =>
			@Mikuia.Log.error err

		@client.on 'join', (channel, nick) =>
			@Mikuia.Log.info 'Joined ' + channel + '.'

		@client.on 'message', (from, to, message) =>
			@handleMessage from, to, message

	handleMessage: (from, to, message) ->
		@Mikuia.Log.info '(' + cli.greenBright(to) + ') ' + cli.yellowBright(from) + ': ' + cli.whiteBright(message)

	join: (channel) ->
		
		@client.join(channel)