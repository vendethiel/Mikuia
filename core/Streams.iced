Leaderboard = require '../models/Leaderboard'

module.exports = class Streams
	constructor: (@db) ->

	get: (stream, callback) ->
		@db.hgetall 'mikuia:stream:' + stream, callback

	getAll: (callback) ->
		@db.smembers 'mikuia:streams', callback

	getAllSorted: (sortMethod, callback) ->
		sortLeaderboard = new Leaderboard sortMethod
		sorting = []
		streams = {}
		await @getAll defer err, onlineStreams
		for stream in onlineStreams
			await
				@get stream, defer err, streamData
				sortLeaderboard.getScore stream, defer err2, score
			if !err
				streams[stream] = streamData
			if !err2 && score
				sorting.push [ stream, score ]

		await sortLeaderboard.getReverseOrder defer err, reverseOrder

		sorting.sort (a, b) ->
			if reverseOrder
				return a[1] - b[1]
			else
				return b[1] - a[1]

		callback sorting, streams
