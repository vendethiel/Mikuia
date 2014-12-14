cli = require 'cli-color'
irc = require 'node-twitch-irc'
RateLimiter = require('limiter').RateLimiter

joinLimiter = new RateLimiter 25, 10000
messageLimiter = new RateLimiter 10, 30000

class exports.Chat
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		
		@chatters = {}
		@connected = false
		@joined = []
		@moderators = {}

	broadcast: (message) =>
		await Mikuia.Streams.getAll defer err, streams
		for stream in streams
			@say stream, '.me broadcast: ' + message

	connect: =>
		setTimeout () =>
			if !@connected
				@Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Sorry, but Twitch is being a fucking dick.')
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
					@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Connected to IRC.')
					@Mikuia.Events.emit 'twitch.connected'
					@connected = true

				event.on 'disconnected', (reason) =>
					@Mikuia.Log.fatal cli.magenta('Twitch') + ' / ' + cli.whiteBright('Disconnected from Twitch IRC. Reason: ' + reason)

				event.on 'join', (channel) =>
					Channel = new Mikuia.Models.Channel channel
					await Channel.getDisplayName defer err, displayName

					@Mikuia.Log.info cli.cyan(displayName) + ' / ' + cli.whiteBright('Joined the IRC channel.')

				event.on 'part', (channel) =>
					Channel = new Mikuia.Models.Channel channel
					await Channel.getDisplayName defer err, displayName

					@Mikuia.Log.info cli.cyan(displayName) + ' / ' + cli.whiteBright('Left the IRC channel.')
			else
				@Mikuia.Log.error err

	getChatters: (channel) => 
		return @chatters[channel]

	handleMessage: (user, to, message) ->
		Channel = new @Mikuia.Models.Channel to
		Chatter = new @Mikuia.Models.Channel user.username
		await Channel.getDisplayName defer err, displayName

		chatterUsername = cli.yellowBright user.username

		if user.username == Mikuia.settings.bot.admin
			chatterUsername = cli.redBright user.username

		if Chatter.isModOf Channel.getName()
			chatterUsername = cli.greenBright '[m] ' + chatterUsername

		if user.special.indexOf('subscriber') > -1
			chatterUsername = cli.blueBright '[s] ' + chatterUsername

		if message.toLowerCase().indexOf(Mikuia.settings.bot.name.toLowerCase()) > -1 || message.toLowerCase().indexOf(Mikuia.settings.bot.admin) > -1
			@Mikuia.Log.info cli.bgBlackBright(cli.cyan(displayName) + ' / ' + chatterUsername + ': ' + cli.red(message))
		else
			@Mikuia.Log.info cli.cyan(displayName) + ' / ' + chatterUsername + ': ' + cli.whiteBright(message)
		@Mikuia.Events.emit 'twitch.message', user, to, message
		
		Channel.trackIncrement 'messages', 1

		tokens = message.split ' '
		trigger = tokens[0]

		await
			Channel.getCommand trigger, defer commandError, command
			Channel.getCommandSettings trigger, true, defer settingsError, settings

		continueCommand = true

		if !settingsError && user.username != Channel.getName()
			
			if settings?._minLevel? && settings._minLevel > 0
				await Chatter.getLevel Channel.getName(), defer whateverError, userLevel
				if userLevel < settings._minLevel
					continueCommand = false

			if settings?._onlyMods? && settings._onlyMods
				if not Chatter.isModOf Channel.getName()
					continueCommand = false

			if settings?._onlySubs? && settings._onlySubs
				if user.special.indexOf('subscriber') == -1
					continueCommand = false

		if !commandError && command? && continueCommand
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
		if channel.indexOf('#') == -1
			channel = '#' + channel
		if @joined.indexOf(channel) == -1
			joinLimiter.removeTokens 1, (err, rr) =>
				@client.join channel
				@joined.push channel
				if callback
					callback false
		else
			if callback
				callback true

	joinMultiple: (channels, callback) =>
		for channel, i in channels
			await @join channel, defer whatever

		for channel in channels
			await @updateChatters channel, defer whatever

		callback false

	mods: (channel) =>
		channel = channel.replace('#', '')
		if @moderators[channel]?
			return @moderators[channel]
		else
			return null

	part: (channel, callback) =>
		messageLimiter.removeTokens 1, (err, rr) =>	
			@client.part channel
			if @joined.indexOf(channel) > -1
				@joined.splice @joined.indexOf(channel), 1

	say: (channel, message) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel
		lines = message.split '\\n'
		for line in lines
			messageLimiter.removeTokens 1, (err, rr) =>
				if !Mikuia.settings.bot.disableChat
					@client.say channel, line

				Channel = new @Mikuia.Models.Channel channel
				await Channel.getDisplayName defer err, displayName

				@Mikuia.Log.info cli.cyan(displayName) + ' / ' + cli.magentaBright(@Mikuia.settings.bot.name) + ' (' + cli.magentaBright(Math.floor(rr)) + '): ' + message

	sayRaw: (channel, message) =>
		@client.say channel, message

	update: =>
		twitchFailure = false

		await @Mikuia.Database.smembers 'mikuia:channels', defer err, channels
		if err then @Mikuia.Log.error err else
			chunks = @Mikuia.Tools.chunkArray channels, 100
			joinList = @Mikuia.settings.bot.autojoin
			streamData = {}
			streamList = []
			for chunk, i in chunks
				if chunk.length > 0
					@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Checking channels live... (' + (i + 1) + '/' + chunks.length + ')')
					await @Mikuia.Twitch.getStreams chunk, defer err, streams
					if err
						@Mikuia.Log.error err
						twitchFailure = true
					else
						chunkList = []
						for stream in streams
							chunkList.push stream.channel.display_name
							if joinList.indexOf(stream.channel.name) == -1
								joinList.push stream.channel.name
							streamList.push stream
							streamData[stream.channel.name] = stream

							Channel = new Mikuia.Models.Channel stream.channel.name
							Channel.trackValue 'viewers', stream.viewers

						@Mikuia.Log.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Obtained live channels... (' + chunkList.length + ')')
			await @Mikuia.Chat.joinMultiple joinList, defer uselessfulness
						
			# Yay, save dat stuff.
			if !twitchFailure
				await @Mikuia.Database.del 'mikuia:streams', defer err, response
				
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

					if stream.channel.profile_banner? && stream.channel.profile_banner != 'null'
						Channel = new Mikuia.Models.Channel stream.channel.name
						Channel.setProfileBanner stream.channel.profile_banner, defer err, whatever

			@Mikuia.Events.emit 'twitch.updated'

			updateTimeout = streamList.length * 2000
			if updateTimeout < 15000
				updateTimeout = 15000

			setTimeout () =>
				@update()
			, updateTimeout

	updateChatters: (channel, callback) =>
		await Mikuia.Twitch.getChatters channel, defer err, chatters
		if !err
			if chatters.chatters?
				@chatters[channel] = chatters.chatters
			if chatters.chatters?.moderators?
				@moderators[channel] = chatters.chatters.moderators
			Channel = new Mikuia.Models.Channel channel
			Channel.trackValue 'chatters', chatters.chatter_count
			
		callback err