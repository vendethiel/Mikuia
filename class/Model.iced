class exports.Model
	constructor: () ->
		@model = 'model'
		@name = ''

	_exists: (key, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.exists @model + ':' + @name + key, defer err, data
		callback err, data

	_get: (key, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.get @model + ':' + @name + key, defer err, data
		callback err, data

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

	_hincrby: (key, field, value, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.hincrby @model + ':' + @name + key, field, value, defer err, data
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

	_scard: (key, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.scard @model + ':' + @name + key, defer err, data
		callback err, data

	_set: (key, value, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.set @model + ':' + @name + key, value, defer err, data
		callback err, data

	_setex: (key, ttl, value, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.setex @model + ':' + @name + key, ttl, value, defer err, data
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

	_zincrby: (key, increment, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.zincrby @model + ':' + @name + key, increment, member, defer err, data
		callback err, data

	_zrank: (key, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.zrank @model + ':' + @name + key, member, defer err, data
		callback err, data

	_zscore: (key, member, callback) ->
		if key != ''
			key = ':' + key
		await Mikuia.Database.zscore @model + ':' + @name + key, member, defer err, data
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