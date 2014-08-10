class exports.Leaderboard extends Mikuia.Model
	constructor: (name) ->
		@model = 'leaderboard'
		@name = name

	getName: () ->
		return @name

	setScore: (channel, score, callback) ->
		await @_zadd 'scores', score, channel, defer err, data
		if callback
			callback err, data