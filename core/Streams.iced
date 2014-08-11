class exports.Streams
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	get: (stream, callback) ->
		await Mikuia.Database.hgetall 'mikuia:stream:' + stream, defer err, stream
		callback err, stream

	getAll: (callback) ->
		await Mikuia.Database.smembers 'mikuia:streams', defer err, streams
		callback err, streams