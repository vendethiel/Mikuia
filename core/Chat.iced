cli = require 'cli-color'
irc = require 'node-twitch-irc'
RateLimiter = require('limiter').RateLimiter

limiter = new RateLimiter 15, 30000

class exports.Chat
	constructor: (Mikuia) ->
		@joined = []
		@Mikuia = Mikuia

		setInterval () =>
			@update()
		, 300000

	connect: ->
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

				event.on 'disconnected', (reason) =>
					@Mikuia.Log.warning 'Disconnected from Twitch IRC. Reason: ' + reason

				event.on 'join', (channel) =>
					@Mikuia.Log.info cli.whiteBright('Joined ' + cli.greenBright(channel) + ' on Twitch IRC.')
			
				event.on 'part', (channel) =>
					@Mikuia.Log.info cli.whiteBright('Left ' + cli.redBright(channel) + ' on Twitch IRC.')
			else
				@Mikuia.Log.error err

	handleMessage: (from, to, message) ->
		@Mikuia.Log.info '(' + cli.greenBright(to) + ') ' + cli.yellowBright(from.username) + ': ' + cli.whiteBright(message)
		@Mikuia.Events.emit('twitch.message', from, to, message)

		Channel = new @Mikuia.Models.Channel to
		tokens = message.split ' '
		trigger = tokens[0]

		await
			Channel.getCommand trigger, defer commandError, command
			Channel.getCommandSettings trigger, true, defer settingsError, settings
		if !commandError && command?
			@Mikuia.Events.emit command,
				from: from
				to: to
				message: message
				settings: settings

	join: (channel, callback) =>
		limiter.removeTokens 1, (err, rr) =>	
			@client.join channel
			if @joined.indexOf(channel) == -1
				@joined.push channel

	part: (channel, callback) =>
		limiter.removeTokens 1, (err, rr) =>	
			@client.part channel
			if @joined.indexOf(channel) > -1
				@joined.splice @joined.indexOf(channel), 1

	say: (channel, message) ->
		limiter.removeTokens 1, (err, rr) =>	
			@client.say channel, message
			@Mikuia.Log.info '(' + cli.greenBright(channel) + ') ' + cli.magentaBright(@Mikuia.settings.bot.name) + ' (' + cli.whiteBright(Math.floor(rr)) + '): ' + cli.whiteBright(message)

	update: =>
		await @Mikuia.Database.smembers 'mikuia:channels', defer err, channels
		if err then @Mikuia.Log.error err else
			chunks = @Mikuia.Tools.chunkArray(channels, 100)
			joinList = ['hatsuney']
			for chunk, i in chunks
				@Mikuia.Log.info 'Asking Twitch API for chunk ' + (i + 1) + ' out of ' + chunks.length + '...'
				await @Mikuia.Twitch.getStreams chunk, defer err, streams
				if err then @Mikuia.Log.error err else
					chunkList = []
					for stream in streams
						chunkList.push stream.channel.display_name
						joinList.push stream.channel.name

					@Mikuia.Log.info 'Channels obtained from chunk ' + (i + 1) + ': ' + cli.whiteBright(chunkList.join(', '))
			for channel in joinList
				if @joined.indexOf('#' + channel) == -1
					await @Mikuia.Chat.join '#' + channel