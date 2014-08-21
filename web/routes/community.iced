module.exports =
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