class exports.Model
	constructor: () ->
		@model = 'model'
		@name = ''

	_hget: (key, field, callback) ->
		await Mikuia.Databse.hget @model + ':' + key, field, defer err, data
		callback err, data

	_hset: (key, field, value, callback) ->
		await Mikuia.Database.hset @model + ':' + key, field, value, defer err, data
		callback err, data

	_sadd: (key, member, callback) ->
		await Mikuia.Database.sadd @model + ':' + @name + ':' + key, member, defer err, data
		callback err, data

	_sismember: (key, value, callback) ->
		await Mikuia.Database.sismember @model + ':' + @name + ':' + key, value, defer err, data
		callback err, data

	_srem: (key, member, callback) ->
		await Mikuia.Database.srem @model + ':' + @name + ':' + key, member, defer err, data
		callback err, data