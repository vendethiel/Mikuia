module.exports = class Model
	constructor: ->
		@model = 'model'
		@name = ''

	_exists: (key, callback) ->
		if key != ''
			key = ':' + key
		@db.exists @model + ':' + @name + key, callback

	_get: (key, callback) ->
		if key != ''
			key = ':' + key
		@db.get @model + ':' + @name + key, callback

	_hdel: (key, field, callback) ->
		if key != ''
			key = ':' + key
		@db.hdel @model + ':' + @name + key, field, callback

	_hget: (key, field, callback) ->
		if key != ''
			key = ':' + key
		@db.hget @model + ':' + @name + key, field, callback

	_hgetall: (key, callback) ->
		if key != ''
			key = ':' + key
		@db.hgetall @model + ':' + @name + key, callback

	_hincrby: (key, field, value, callback) ->
		if key != ''
			key = ':' + key
		@db.hincrby @model + ':' + @name + key, field, value, callback

	_hset: (key, field, value, callback) ->
		if key != ''
			key = ':' + key
		@db.hset @model + ':' + @name + key, field, value, callback

	_sadd: (key, member, callback) ->
		if key != ''
			key = ':' + key
		@db.sadd @model + ':' + @name + key, member, callback

	_scard: (key, callback) ->
		if key != ''
			key = ':' + key
		@db.scard @model + ':' + @name + key, callback

	_set: (key, value, callback) ->
		if key != ''
			key = ':' + key
		@db.set @model + ':' + @name + key, value, callback

	_setex: (key, ttl, value, callback) ->
		if key != ''
			key = ':' + key
		@db.setex @model + ':' + @name + key, ttl, value, callback

	_sismember: (key, member, callback) ->
		if key != ''
			key = ':' + key
		@db.sismember @model + ':' + @name + key, member, callback

	_smembers: (key, callback) ->
		if key != ''
			key = ':' + key
		@db.smembers @model + ':' + @name + key, callback

	_srem: (key, member, callback) ->
		if key != ''
			key = ':' + key
		@db.srem @model + ':' + @name + key, member, callback

	_zadd: (key, score, member, callback) ->
		if key != ''
			key = ':' + key
		@db.zadd @model + ':' + @name + key, score, member, callback

	_zincrby: (key, increment, member, callback) ->
		if key != ''
			key = ':' + key
		@db.zincrby @model + ':' + @name + key, increment, member, callback

	_zscore: (key, member, callback) ->
		if key != ''
			key = ':' + key
		@db.zscore @model + ':' + @name + key, member, callback
