class exports.Model
	constructor: () ->
		@model = 'model'
		@name = ''

	_hdel: (key, field, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.hdel @model + ':' + @name + key, field, defer err, data
		callback err, data

	_hget: (key, field, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.hget @model + ':' + @name + key, field, defer err, data
		callback err, data

	_hgetall: (key, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.hgetall @model + ':' + @name + key, defer err, data
		callback err, data

	_hset: (key, field, value, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.hset @model + ':' + @name + key, field, value, defer err, data
		callback err, data

	_sadd: (key, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.sadd @model + ':' + @name + key, member, defer err, data
		callback err, data

	_sismember: (key, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.sismember @model + ':' + @name + key, member, defer err, data
		callback err, data

	_smembers: (key, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.smembers @model + ':' + @name + key, defer err, data
		callback err, data

	_srem: (key, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.srem @model + ':' + @name + key, member, defer err, data
		callback err, data

	_zadd: (key, score, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.zadd @model + ':' + @name + key, score, member, defer err, data
		callback err, data

	trackGet: (key, callback) ->
		await Mikuia.Tracker.get @model, @name, key, defer err, data
		callback err, data

	trackIncrement: (key, value, callback) ->
		await Mikuia.Tracker.increment @model, @name, key, value, defer err, data
		if callback
			callback err, data

	trackValue: (key, value, callback) ->
		await Mikuia.Tracker.track @model, @name, key, value, defer err, data
		if callback
			callback err, data