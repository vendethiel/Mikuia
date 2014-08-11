module.exports =
	index: (req, res) ->
		res.render 'community/index'

	streams: (req, res) ->
		game = ''

		if !req.param 'sortMethod'
			sortMethod = 'viewers'
		else
			sortMethod = req.param 'sortMethod'

		sortLeaderboard = new Mikuia.Models.Leaderboard sortMethod

		sorting = []
		streams = {}
		await Mikuia.Streams.getAll defer err, onlineStreams
		for stream in onlineStreams
			await
				Mikuia.Streams.get stream, defer err, streamData
				sortLeaderboard.getScore stream, defer err2, score
			if !err
				streams[stream] = streamData
			if !err2 && score
				sorting.push [ stream, score ]

		await
			sortLeaderboard.getDisplayHtml defer err, displayHtml
			sortLeaderboard.getReverseOrder defer err, reverseOrder

		sorting.sort (a, b) ->
			if reverseOrder
				return a[1] - b[1]
			else
				return b[1] - a[1]

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