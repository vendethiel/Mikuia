class exports.Leagues
	constructor: (@Mikuia) ->
		# durr

	addFight: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel
		Mikuia.Database.incrby 'channel:' + Channel.getName() + ':1v1:fights', 1, callback

	addFightLoss: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel
		Mikuia.Database.incrby 'channel:' + Channel.getName() + ':1v1:fights:lost', 1, callback

	addFightWin: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel
		Mikuia.Database.incrby 'channel:' + Channel.getName() + ':1v1:fights:won', 1, callback

	getFightCount: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel

		await Mikuia.Database.get 'channel:' + Channel.getName() + ':1v1:fights', defer err, fights
		if !fights
			fights = 0

		callback err, parseInt fights

	getFightCountLost: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel

		await Mikuia.Database.get 'channel:' + Channel.getName() + ':1v1:fights:lost', defer err, fights
		if !fights
			fights = 0

		callback err, parseInt fights

	getFightCountWon: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel

		await Mikuia.Database.get 'channel:' + Channel.getName() + ':1v1:fights:won', defer err, fights
		if !fights
			fights = 0

		callback err, parseInt fights

	getLeague: (elo) ->
		return Math.max(Math.min(1 + Math.floor((elo - 600) / 200), 9), 1)

	getLeagueDivision: (elo) ->
		if elo < 2360
			if elo >= 600
				return 5 - Math.floor((elo % 200) / 40)
			else
				return 5
		else
			return 1

	getLeagueDivisionText: (elo) ->
		switch @getLeagueDivision elo
			when 1 then 'I'
			when 2 then 'II'
			when 3 then 'III'
			when 4 then 'IV'
			when 5 then 'V'
			else '?'

	getLeagueFullText: (elo) -> @getLeagueText(elo) + ' ' + @getLeagueDivisionText(elo)

	getLeagueText: (elo) ->
		switch @getLeague elo
			when 1 then 'Paper'
			when 2 then 'Sand'
			when 3 then 'Wood'
			when 4 then 'Stone'
			when 5 then 'Iron'
			when 6 then 'Gold'
			when 7 then 'Platinum'
			when 8 then 'Diamond'
			when 9 then 'Master'
			else 'Unknown'

	getRating: (channel, callback) ->
		Channel = new Mikuia.Models.Channel channel

		await Mikuia.Database.get 'channel:' + Channel.getName() + ':1v1:rating', defer err, rating
		if !rating
			rating = 1000

		callback err, parseInt rating

	updateRating: (channel, rating, callback) ->
		Channel = new Mikuia.Models.Channel channel
		Leaderboard = new Mikuia.Models.Leaderboard '1v1rating'

		await @getFightCount Channel.getName(), defer err, fights
		if fights >= 10
			await Leaderboard.setScore Channel.getName(), rating, defer whatever

		Mikuia.Database.set 'channel:' + Channel.getName() + ':1v1:rating', rating, callback