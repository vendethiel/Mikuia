module.exports =
	badge: (req, res) ->
		Badge = new Mikuia.Models.Badge req.params.badgeId

		await Badge.exists defer err, exists

		if exists
			memberData = {}

			await
				Badge.getAll defer err, data
				Badge.getMembers defer err, members
				Mikuia.Database.zcount 'mikuia:experience', '-inf', '+inf', defer err, uniqueChatters

			for member in members
				Channel = new Mikuia.Models.Channel member
				memberData[member] = {}
				await
					Channel.getDisplayName defer err, memberData[member].displayName
					Channel.getLogo defer err, memberData[member].logo

			res.render 'community/badge',
				Badge: data
				badgeId: req.params.badgeId
				members: members
				memberData: memberData
				uniqueChatters: uniqueChatters
		else
			res.render 'community/error',
				error: 'Badge does not exist.'

	donate: (req, res) ->
		await Mikuia.Database.zrevrange 'mikuia:donators', 0, -1, defer err, donators
		
		displayNames = {}
		logos = {}
		total = 0

		for channel in donators
			Channel = new Mikuia.Models.Channel channel
			await
				Channel.getDisplayName defer err, displayNames[channel]
				Channel.getLogo defer err, logos[channel]

		if req.isAuthenticated()
			await Mikuia.Database.zscore 'mikuia:donators', req.user.username, defer err, data
			if data? && data > 0
				total = data

		res.render 'community/donate',
			displayNames: displayNames
			donators: donators
			logos: logos
			total: total

	guide: (req, res) ->
		res.render 'community/guide'

	index: (req, res) ->
		await Mikuia.Streams.getAllSorted Mikuia.settings.web.featureMethod, defer sorting, streams

		if sorting.length > 0
			stream = sorting[0][0]
		else
			await Mikuia.Streams.getAllSorted Mikuia.settings.web.featureFallbackMethod, defer sorting, streams
			if sorting.length > 0
				stream = sorting[0][0]
			else
				stream = null

		featuredStream = null
		if stream
			Channel = new Mikuia.Models.Channel stream
			await
				Mikuia.Streams.get stream, defer err, featuredStream
				Channel.getBio defer err, bio
				Channel.isSupporter defer err, isSupporter

			if featuredStream?
				featuredStream.bio = bio
				featuredStream.name = featuredStream.display_name

				if isSupporter
					featuredStream.display_name = '❤ ' + featuredStream.display_name

		await Mikuia.Element.preparePanels 'community.index', defer panels

		sortLeaderboard = new Mikuia.Models.Leaderboard 'viewers'

		await Mikuia.Streams.getAllSorted 'viewers', defer sorting, streams
		await sortLeaderboard.getDisplayHtml defer err, displayHtml

		res.render 'community/index',
			featured: featuredStream
			panels: panels
			sorting: sorting
			streams: streams
			displayHtml: displayHtml

	leagueleaderboards: (req, res) ->
		await Mikuia.Database.zrevrange 'leaderboard:1v1rating:scores', 0, 99, 'withscores', defer err, ranks
		
		channels = Mikuia.Tools.chunkArray ranks, 2
		displayNames = {}
		fights = {}
		isStreamer = {}
		logos = {}

		for data in channels
			if data.length > 0
				channel = new Mikuia.Models.Channel data[0]
				rating = data[1]

				await
					channel.isStreamer defer err, isStreamer[data[0]]
					channel.getDisplayName defer err, displayNames[data[0]]
					channel.getLogo defer err, logos[data[0]]
					Mikuia.Leagues.getFightCount channel.getName(), defer err, fights[data[0]]

		res.render 'community/leagueLeaderboards',
			channels: channels
			displayNames: displayNames
			fights: fights
			isStreamer: isStreamer
			logos: logos

	leagues: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await
			Mikuia.Leagues.getFightCount Channel.getName(), defer err, fightCount
			Mikuia.Leagues.getFightCountLost Channel.getName(), defer err, fightsLost
			Mikuia.Leagues.getFightCountWon Channel.getName(), defer err, fightsWon
			Mikuia.Leagues.getRating Channel.getName(), defer err, rating
		
		res.render 'community/leagues',
			fightCount: fightCount
			fightsLost: fightsLost
			fightsWon: fightsWon
			rating: rating

	levels: (req, res) ->
		if req.params.userId?
			Channel = new Mikuia.Models.Channel req.params.userId

			await Channel.exists defer err, exists
			if !err 
				if exists
					await Channel.getDisplayName defer err, displayName
					await Channel.getProfileBanner defer err, profileBanner
					await Mikuia.Database.zrevrange 'levels:' + Channel.getName() + ':experience', 0, 99, 'withscores', defer err, ranks

					channels = Mikuia.Tools.chunkArray ranks, 2
					displayNames = {}
					experience = null
					isStreamer = {}
					logos = {}
					rank = null

					for data in channels
						if data.length > 0
							channel = new Mikuia.Models.Channel data[0]
							experience = data[1]

							await
								channel.isStreamer defer err, isStreamer[data[0]]
								channel.getDisplayName defer err, displayNames[data[0]]
								channel.getLogo defer err, logos[data[0]]

					if req.isAuthenticated()
						channel = new Mikuia.Models.Channel req.user.username
						await
							channel.getExperience Channel.getName(), defer err, experience
							Mikuia.Database.zrevrank 'levels:' + Channel.getName() + ':experience', req.user.username, defer err, rank

					res.render 'community/levelsUser',
						channels: channels
						displayName: displayName
						displayNames: displayNames
						experience: experience
						isStreamer: isStreamer
						logos: logos
						profileBanner: profileBanner
						rank: rank + 1
				else
					res.render 'community/error',
						error: 'Channel does not exist.'
			else
				res.render 'community/error',
					error: err

		else
			await Mikuia.Streams.getAll defer err, streams

			displayNames = {}
			experience = {}
			logos = {}
			ranks = {}
			totalLevel = null
			userCount = {}

			if req.isAuthenticated()
				Channel = new Mikuia.Models.Channel req.user.username

				await
					Channel.getAllExperience defer err, data
					Channel.getTotalLevel defer err, totalLevel	

				for md in data
					experience[md[0]] = md[1]

					chan = new Mikuia.Models.Channel md[0]
					await chan.getDisplayName defer err, displayNames[md[0]]

				for stream in streams
					await Mikuia.Database.zrevrank 'levels:' + stream + ':experience', req.user.username, defer err, ranks[stream]

				for name, rank of ranks
					ranks[name]++

			for stream in streams
				chan = new Mikuia.Models.Channel stream
				await chan.getDisplayName defer err, displayNames[stream]
				await Mikuia.Database.zcard 'levels:' + stream + ':experience', defer err, userCount[stream]

			await Mikuia.Database.zrevrange 'mikuia:experience', 0, 4, 'withscores', defer err, totalLevels
			mexp = Mikuia.Tools.chunkArray totalLevels, 2

			mlvl = []
			for md in mexp
				if md.length > 0
					chan = new Mikuia.Models.Channel md[0]
					await
						chan.getDisplayName defer err, displayNames[md[0]]
						chan.getLogo defer err, logos[md[0]]
					mlvl.push [
						md[0]
						Mikuia.Tools.getLevel md[1]
					]

			res.render 'community/levels',
				displayNames: displayNames
				experience: experience
				level: totalLevel
				logos: logos
				mlvl: mlvl
				ranks: ranks
				rawExperience: data
				streams: streams
				userCount: userCount

	mlvl: (req, res) ->
		await Mikuia.Database.zrevrange 'mikuia:experience', 0, 249, 'withscores', defer err, expData
		channels = Mikuia.Tools.chunkArray expData, 2

		displayNames = {}
		isStreamer = {}
		logos = {}
		rank = null
		totalLevel = null

		for data in channels
			if data.length > 0
				channel = new Mikuia.Models.Channel data[0]
				experience = data[1]

				await
					channel.isStreamer defer err, isStreamer[data[0]]
					channel.getDisplayName defer err, displayNames[data[0]]
					channel.getLogo defer err, logos[data[0]]

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel
			await Mikuia.Database.zrevrank 'mikuia:experience', req.user.username, defer err, rank

		res.render 'community/mlvl',
			channels: channels
			displayNames: displayNames
			isStreamer: isStreamer
			level: totalLevel
			logos: logos
			rank: rank + 1

	slack: (req, res) ->
		totalLevel = 0

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel

		res.render 'community/slack',
			totalLevel: totalLevel

	slackInvite: (req, res) ->
		totalLevel = 0

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel

			if req.user.email? and totalLevel >= 10
				Mikuia.Tools.inviteToSlack req.user.email, req.user.displayName

				res.render 'community/slackInvite'
			else
				res.render 'community/error',
					error: 'Something went wrong...'
		else
			res.render 'community/error',
				error: 'You are not logged in.'

	stats: (req, res) ->
		res.render 'community/stats'

	streams: (req, res) ->
		game = ''

		if !req.param 'sortMethod'
			sortMethod = 'viewers'
		else
			sortMethod = req.param 'sortMethod'

		sortLeaderboard = new Mikuia.Models.Leaderboard sortMethod

		await Mikuia.Streams.getAllSorted sortMethod, defer sorting, streams
		await sortLeaderboard.getDisplayHtml defer err, displayHtml

		leaderboards = {}
		lbList = Mikuia.Element.getAll 'leaderboards'
		for lbName in lbList
			lb = new Mikuia.Models.Leaderboard lbName
			await lb.getDisplayName defer err, displayName
			leaderboards[lbName] = displayName

		res.render 'community/streams',
			displayHtml: displayHtml
			leaderboards: leaderboards
			sorting: sorting
			sortMethod: sortMethod
			streams: streams

	support: (req, res) ->
		res.render 'community/supporter'

	user: (req, res) ->
		if req.params.userId?
			Channel = new Mikuia.Models.Channel req.params.userId
			
			await Channel.exists defer err, exists
			if !err 
				if exists

					channel =
						name: Channel.getName()
					displayNames = {}
					ranks = {}

					await
						Channel.getAllExperience defer err, channel.experience
						Channel.getBadgesWithInfo defer err, channel.badges
						Channel.getBio defer err, channel.bio
						Channel.getCleanDisplayName defer err, channel.display_name
						Channel.getCommands defer err, commands
						Channel.getEnabledPlugins defer err, channel.plugins
						Channel.getLogo defer err, channel.logo
						Channel.getProfileBanner defer err, channel.profileBanner
						Channel.getSetting 'coins', 'name', defer err, coinName
						Channel.getSetting 'coins', 'namePlural', defer err, coinNamePlural
						Channel.getTotalLevel defer err, channel.level
						Channel.isBanned defer err, channel.isBanned
						Channel.isBot defer err, channel.isBot
						Channel.isLive defer err, channel.isLive

					channel.commands = []
					sorting = []
					for commandName, commandHandler of commands
						sorting.push commandName

					sorting.sort()
					for command in sorting
						description = Mikuia.Plugin.getHandler(commands[command]).description
						codeText = false

						await Channel.getCommandSettings command, true, defer err, settings

						if commands[command] == 'base.dummy'
							description = settings.message
							codeText = true
						
						channel.commands.push
							name: command
							description: description
							plugin: Mikuia.Plugin.getManifest(Mikuia.Plugin.getHandler(commands[command]).plugin).name
							settings: settings
							coin:
								coinName: coinName
								coinNamePlural: coinNamePlural
							codeText: codeText

					if channel.isLive
						await Mikuia.Streams.get Channel.getName(), defer err, channel.stream

					for data in channel.experience
						chan = new Mikuia.Models.Channel data[0]
						await chan.getDisplayName defer err, displayNames[data[0]]
						await Mikuia.Database.zrevrank 'levels:' + data[0] + ':experience', Channel.getName(), defer err, ranks[data[0]]
					
					for name, rank of ranks
						ranks[name]++

					splashButtons = []
					for element in Mikuia.Element.getAll 'userPageSplashButton'
						if channel.plugins.indexOf(element.plugin) > -1
							splashButtons = splashButtons.concat element

					for element, i in splashButtons
						for button, j in element.buttons
							if button.setting?
								await Channel.getSetting element.plugin, button.setting, defer err, value
								if value
									button.link = button.linkFunction value
								else
									button.link = false

					if req.params.subpage?
						if req.params.subpage == 'levels'
							res.render 'community/userLevels',
								Channel: channel
								displayNames: displayNames
								ranks: ranks
					else
						res.render 'community/user',
							Channel: channel
							displayNames: displayNames
							splashButtons: splashButtons
				else
					res.render 'community/error',
						error: 'User does not exist.'
			else
				res.render 'community/error',
					error: err
		else
			res.render 'community/error',
				error: 'No user specified.'