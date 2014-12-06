module.exports =
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
			await Mikuia.Streams.get stream, defer err, featuredStream
			await Channel.getBio defer err, bio
			if featuredStream?
				featuredStream.bio = bio

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

	levels: (req, res) ->
		if req.params.userId?
			Channel = new Mikuia.Models.Channel req.params.userId

			await Channel.exists defer err, exists
			if !err 
				if exists
					await Channel.getDisplayName defer err, displayName
					await Mikuia.Database.zrevrange 'levels:' + req.params.userId + ':experience', 0, 99, 'withscores', defer err, ranks

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
							channel.getExperience req.params.userId, defer err, experience
							Mikuia.Database.zrevrank 'levels:' + req.params.userId + ':experience', req.user.username, defer err, rank

					res.render 'community/levelsUser',
						channels: channels
						displayName: displayName
						displayNames: displayNames
						experience: experience
						isStreamer: isStreamer
						logos: logos
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

			await Mikuia.Database.zrevrange 'mikuia:levels', 0, 4, 'withscores', defer err, totalLevels
			mlvl = Mikuia.Tools.chunkArray totalLevels, 2

			for md in mlvl
				if md.length > 0
					chan = new Mikuia.Models.Channel md[0]
					await
						chan.getDisplayName defer err, displayNames[md[0]]
						chan.getLogo defer err, logos[md[0]]

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
		await Mikuia.Database.zrevrange 'mikuia:levels', 0, 249, 'withscores', defer err, ranks
		channels = Mikuia.Tools.chunkArray ranks, 2

		displayNames = {}
		isStreamer = {}
		logos = {}
		rank = null
		totalExperience = {}
		totalLevel = null

		for data in channels
			if data.length > 0
				channel = new Mikuia.Models.Channel data[0]
				experience = data[1]

				await
					channel.isStreamer defer err, isStreamer[data[0]]
					channel.getDisplayName defer err, displayNames[data[0]]
					channel.getTotalExperience defer err, totalExperience[data[0]]
					channel.getLogo defer err, logos[data[0]]

		if req.isAuthenticated()
			Channel = new Mikuia.Models.Channel req.user.username
			await Channel.getTotalLevel defer err, totalLevel
			await Mikuia.Database.zrevrank 'mikuia:levels', req.user.username, defer err, rank

		res.render 'community/mlvl',
			channels: channels
			displayNames: displayNames
			isStreamer: isStreamer
			level: totalLevel
			logos: logos
			rank: rank + 1
			totalExperience: totalExperience

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

	user: (req, res) ->
		if req.params.userId?
			Channel = new Mikuia.Models.Channel req.params.userId
			
			await Channel.exists defer err, exists
			if !err 
				if exists

					channel =
						name: req.params.userId
					displayNames = {}
					ranks = {}
					await
						Channel.getAllExperience defer err, channel.experience
						Channel.getDisplayName defer err, channel.display_name
						Channel.getTotalLevel defer err, channel.level
						Channel.getLogo defer err, channel.logo

					for data in channel.experience
						chan = new Mikuia.Models.Channel data[0]
						await chan.getDisplayName defer err, displayNames[data[0]]
						await Mikuia.Database.zrevrank 'levels:' + data[0] + ':experience', req.params.userId, defer err, ranks[data[0]]
					
					for name, rank of ranks
						ranks[name]++

					if req.params.subpage?
						if req.params.subpage == 'levels'
							res.render 'community/userLevels',
								Channel: channel,
								displayNames: displayNames,
								ranks: ranks
					else
						res.render 'community/user',
							Channel: channel,
							displayNames: displayNames
				else
					res.render 'community/error',
						error: 'User does not exist.'
			else
				res.render 'community/error',
					error: err
		else
			res.render 'community/error',
				error: 'No user specified.'