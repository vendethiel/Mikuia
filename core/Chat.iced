cli = require 'cli-color'
irc = require 'node-twitch-irc'
RateLimiter = require('limiter').RateLimiter

limiter = new RateLimiter 15, 30000

class exports.Chat
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		
		@connected = false
		@joined = []
		@moderators = {}

		setInterval () =>
			@update()
		, 300000

	connect: =>
		setTimeout () =>
			if !@connected
				@Mikuia.Log.fatal 'Sorry, but Twitch is being a fucking dick.'
		, 10000
		@client = new irc.connect
			autoreconnect: true
			channels: []
			debug: @Mikuia.settings.bot.debug
			names: true
			nickname: @Mikuia.settings.bot.name
			port: 6667
			server: 'irc.twitch.tv'
			oauth: @Mikuia.settings.bot.oauth
			twitchclient: 3
		, (err, event) =>
			if !err
				event.on 'chat', (user, channel, message) =>
					@handleMessage user, channel, message

				event.on 'connected', =>
					@Mikuia.Log.info 'Connected to Twitch IRC.'
					@Mikuia.Events.emit 'twitch.connected'
					@connected = true

				event.on 'disconnected', (reason) =>
					@Mikuia.Log.warning 'Disconnected from Twitch IRC. Reason: ' + reason

				event.on 'join', (channel) =>
					@Mikuia.Log.info cli.whiteBright('Joined ' + cli.greenBright(channel) + ' on Twitch IRC.')

				event.on 'part', (channel) =>
					@Mikuia.Log.info cli.whiteBright('Left ' + cli.redBright(channel) + ' on Twitch IRC.')
			else
				@Mikuia.Log.error err

	handleMessage: (user, to, message) ->
		@Mikuia.Log.info '(' + cli.greenBright(to) + ') ' + cli.yellowBright(user.username) + ': ' + cli.whiteBright(message)
		@Mikuia.Events.emit 'twitch.message', user, to, message

		Channel = new @Mikuia.Models.Channel to
		Channel.trackIncrement 'messages', 1

		tokens = message.split ' '
		trigger = tokens[0]

		await
			Channel.getCommand trigger, defer commandError, command
			Channel.getCommandSettings trigger, true, defer settingsError, settings

		if !commandError && command?
			handler = @Mikuia.Plugin.getHandler command
			await Channel.isPluginEnabled handler.plugin, defer whateverError, enabled

			if !whateverError && enabled
				@Mikuia.Events.emit command,
					user: user
					to: to
					message: message
					tokens: tokens
					settings: settings
				Channel.trackIncrement 'commands', 1

	join: (channel, callback) =>
		if @joined.indexOf('#' + channel) == -1
			limiter.removeTokens 1, (err, rr) =>	
				@client.join channel
				if @joined.indexOf(channel) == -1
					@joined.push channel

		await @Mikuia.Twitch.getChatters channel, defer err, chatters
		if !err
			if chatters.chatters?.moderators?
				@moderators['#' + channel] = chatters.chatters.moderators
			Channel = new Mikuia.Models.Channel channel
			Channel.trackValue 'chatters', chatters.chatter_count

	mods: (channel) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel
		if @moderators[channel]?
			return @moderators[channel]
		else
			return null

	part: (channel, callback) =>
		limiter.removeTokens 1, (err, rr) =>	
			@client.part channel
			if @joined.indexOf(channel) > -1
				@joined.splice @joined.indexOf(channel), 1

	say: (channel, message) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel
		lines = message.split '\\n'
		for line in lines
			limiter.removeTokens 1, (err, rr) =>	
				@client.say channel, line
				@Mikuia.Log.info '(' + cli.greenBright(channel) + ') ' + cli.magentaBright(@Mikuia.settings.bot.name) + ' (' + cli.whiteBright(Math.floor(rr)) + '): ' + cli.whiteBright(line)

	update: =>
		await @Mikuia.Database.smembers 'mikuia:channels', defer err, channels
		if err then @Mikuia.Log.error err else
			chunks = @Mikuia.Tools.chunkArray channels, 100
			joinList = ['hatsuney']
			streamData = {}
			streamList = []
			for chunk, i in chunks
				@Mikuia.Log.info 'Asking Twitch API for chunk ' + (i + 1) + ' out of ' + chunks.length + '...'
				await @Mikuia.Twitch.getStreams chunk, defer err, streams
				if err then @Mikuia.Log.error err else
					chunkList = []
					for stream in streams
						chunkList.push stream.channel.display_name
						joinList.push stream.channel.name
						streamList.push stream
						streamData[stream.channel.name] = stream

						Channel = new Mikuia.Models.Channel stream.channel.name
						Channel.trackValue 'viewers', stream.viewers

					@Mikuia.Log.info 'Channels obtained from chunk ' + (i + 1) + ': ' + cli.whiteBright(chunkList.join(', '))
			for channel in joinList
				@Mikuia.Chat.join '#' + channel
						
			# Yay, save dat stuff.
			await @Mikuia.Database.del 'mikuia:streams', defer err, response
			if !err
				await
					for stream in streamList
						@Mikuia.Database.sadd 'mikuia:streams', stream.channel.name, defer err, whatever
						
						things = [
							'display_name'
							'followers'
							'game'
							'logo'
							'mature'
							'profile_banner'
							'status'
							'views'
						]

						for thing in things
							@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, thing, stream.channel[thing], defer err, whatever

						@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, 'preview', stream.preview.medium, defer err, whatever
						@Mikuia.Database.hset 'mikuia:stream:' + stream.channel.name, 'viewers', stream.viewers, defer err, whatever
						@Mikuia.Database.expire 'mikuia:stream:' + stream.channel.name, 600, defer err, whatever
			@Mikuia.Events.emit 'twitch.updated'