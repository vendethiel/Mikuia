cli = require 'cli-color'
irc = require 'twitch-irc'
RateLimiter = require('limiter').RateLimiter
Channel = require '../models/Channel'
{chunkArray} = require './helpers'

channelLimiter = {}
joinLimiter = new RateLimiter 25, 10000
messageLimiter = new RateLimiter 10, 30000

module.exports = class Chat
	constructor: (@settings, @logger, @db) ->
		@chatters = {}
		@connected = false
		@joined = []
		@moderators = {}
		@streams = new (require './Streams')(@db)

	broadcast: (message) =>
		await @streams.getAll defer err, streams
		for stream in streams
			@say stream, '.me broadcast: ' + message

	connect: =>
		@client = new irc.client
			options:
				debug: @settings.bot.debug
				exitOnError: true
			connection:
				reconnect: true
				retries: 3
				serverType: 'chat'
				preferredServer: @settings.bot.server
			identity:
				username: @settings.bot.name
				password: @settings.bot.oauth

		@client.connect()

		@client.addListener 'chat', (channel, user, message) =>
			@handleMessage user, channel, message

		@client.addListener 'connected', (address, port) =>
			@logger.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Connected to Twitch IRC (' + cli.yellowBright(address + ':' + port) + cli.whiteBright(')'))
			@Mikuia.Events.emit 'twitch.connected'
			@connected = true

		@client.addListener 'disconnected', (reason) =>
			@logger.fatal cli.magenta('Twitch') + ' / ' + cli.whiteBright('Disconnected from Twitch IRC. Reason: ' + reason)

		@client.addListener 'join', (channel, username) =>
			if username == @settings.bot.name.toLowerCase()
				Channel = new Mikuia.Models.Channel channel
				await
					Channel.getDisplayName defer err, displayName
					Channel.isSupporter defer err, isSupporter

				if isSupporter
					channelLimiter[Channel.getName()] = new RateLimiter 3, 10000
					rateLimitingProfile = cli.redBright 'Supporter (3 per 10s)'
				else
					channelLimiter[Channel.getName()] = new RateLimiter 2, 10000
					rateLimitingProfile = cli.greenBright 'Free (2 per 10s)'

				@logger.info cli.cyan(displayName) + ' / ' + cli.whiteBright('Joined the IRC channel. Rate Limiting Profile: ') + rateLimitingProfile


		@client.addListener 'part', (channel, username) =>
			if username == @settings.bot.name.toLowerCase()
				Channel = new Mikuia.Models.Channel channel
				await Channel.getDisplayName defer err, displayName

				delete channelLimiter[Channel.getName()]
				@logger.info cli.cyan(displayName) + ' / ' + cli.whiteBright('Left the IRC channel.')

		@client.addListener 'reconnect', =>
			@connected = false
			@joined = []

	getChatters: (channel) => @chatters[channel]

	handleMessage: (user, to, message) =>
		Channel = new @Mikuia.Models.Channel to
		Chatter = new @Mikuia.Models.Channel user.username
		await Channel.getDisplayName defer err, displayName

		chatterUsername = cli.yellowBright user.username

		if Chatter.isAdmin()
			chatterUsername = cli.redBright user.username

		if Chatter.isModOf Channel.getName()
			chatterUsername = cli.greenBright '[m] ' + chatterUsername

		if user.special.indexOf('subscriber') > -1
			chatterUsername = cli.blueBright '[s] ' + chatterUsername

		if message.toLowerCase().indexOf(Mikuia.settings.bot.name.toLowerCase()) > -1 || message.toLowerCase().indexOf(Mikuia.settings.bot.admin) > -1
			@logger.info cli.bgBlackBright(cli.cyan(displayName) + ' / ' + chatterUsername + ': ' + cli.red(message))
		else
			@logger.info cli.cyan(displayName) + ' / ' + chatterUsername + ': ' + cli.whiteBright(message)
		@Mikuia.Events.emit 'twitch.message', user, to, message

		Channel.trackIncrement 'messages', 1

		tokens = message.split ' '
		trigger = tokens[0]

		await Channel.queryCommand trigger, user, defer err, o
		{command, settings, isAllowed} = o

		# abort if there's an error, access denied or no command
		return if err || !isAllowed || !command?

		handler = @Mikuia.Plugin.getHandler command
		await Channel.isPluginEnabled handler.plugin, defer err, enabled

		if !err && enabled
			if settings?._coinCost and settings._coinCost > 0
				await Mikuia.Database.zincrby "channel:#{Channel.getName()}:coins", -settings._coinCost, user.username, defer error, whatever

			@Mikuia.Events.emit command, {user, to, message, tokens, settings}
			Channel.trackIncrement 'commands', 1

	join: (channel, callback) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel

		Channel = new Mikuia.Models.Channel channel
		await Channel.isEnabled defer err, isMember

		if @joined.indexOf(channel) == -1 && isMember
			joinLimiter.removeTokens 1, (err, rr) =>
				@client.join channel
				@joined.push channel
				callback? false
		else
			callback? true

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
		joinLimiter.removeTokens 1, (err, rr) =>
			@client.part channel
			if @joined.indexOf(channel) > -1
				@joined.splice @joined.indexOf(channel), 1

	say: (channel, message) =>
		if channel.indexOf('#') == -1
			channel = '#' + channel
		if message.indexOf('.') == 0 or message.indexOf('/') == 0
			message = '!' + message.replace('.', '').replace('/', '')

		@sayUnfiltered channel, message

	sayUnfiltered: (channel, message) ->
		Channel = new Mikuia.Models.Channel channel
		await Channel.getDisplayName defer err, displayName

		lines = message.split '\\n'
		for line in lines
			if !Mikuia.settings.bot.disableChat && line.trim() != ''
				messageLimiter.removeTokens 1, (err, twitchRR) =>
					if channelLimiter[Channel.getName()]?
							channelLimiter[Channel.getName()].removeTokens 1, (err, channelRR) =>
								@client.say channel, line
								@logger.info cli.cyan(displayName) + ' / ' + cli.magentaBright(@settings.bot.name) + ' (' + cli.magentaBright(Math.floor(twitchRR)) + ') (' + cli.greenBright(Math.floor(channelRR)) + '): ' + line

	sayRaw: (channel, message) =>
		@client.say channel, message

	update: =>
		twitchFailure = false

		await @db.smembers 'mikuia:channels', defer err, channels
		if err then @logger.error err else
			chunks = chunkArray channels, 100
			joinList = @settings.bot.autojoin
			streamData = {}
			streamList = []
			for chunk, i in chunks
				if chunk.length > 0
					@logger.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Checking channels live... (' + (i + 1) + '/' + chunks.length + ')')
					await @Mikuia.Twitch.getStreams chunk, defer err, streams
					if err
						@logger.error err
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
							Channel.trackValue 'followers', stream.channel.followers
							Channel.trackValue 'viewers', stream.viewers

							await Channel.isSupporter defer err, isSupporter
							if isSupporter
								Channel.trackValue 'supporterValue', Math.floor(Math.random() * 10000)

						@logger.info cli.magenta('Twitch') + ' / ' + cli.whiteBright('Obtained live channels... (' + chunkList.length + ')')
			await @Mikuia.Chat.joinMultiple joinList, defer uselessfulness

			# Yay, save dat stuff.
			if !twitchFailure
				await @db.del 'mikuia:streams', defer err, response

			await
				for stream in streamList
					@db.sadd 'mikuia:streams', stream.channel.name, defer err, whatever

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
						@db.hset 'mikuia:stream:' + stream.channel.name, thing, stream.channel[thing], defer err, whatever

					@db.hset 'mikuia:stream:' + stream.channel.name, 'created_at', stream.created_at, defer err, whatever
					@db.hset 'mikuia:stream:' + stream.channel.name, 'preview', stream.preview.medium, defer err, whatever
					@db.hset 'mikuia:stream:' + stream.channel.name, 'viewers', stream.viewers, defer err, whatever
					@db.expire 'mikuia:stream:' + stream.channel.name, 600, defer err, whatever

					if stream.channel.profile_banner? && stream.channel.profile_banner != 'null'
						Channel = new Channel stream.channel.name
						Channel.setProfileBanner stream.channel.profile_banner, defer err, whatever

			@Mikuia.Events.emit 'twitch.updated'

			updateTimeout = streamList.length * 1000
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
