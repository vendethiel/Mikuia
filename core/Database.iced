cli = require 'cli-color'
redis = require 'redis'

class exports.Database
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	connect: (host, port, options) ->
		@Mikuia.Log.info 'Attempting to connect with ' + cli.redBright('Redis') + ' server at ' + host + ':' + port + '...'
		@client = redis.createClient port, host, options
		@client.on 'ready', =>
			@Mikuia.Log.success 'Connected to the database.'
		@client.on 'error', (err) =>
			console.trace()
			@Mikuia.Log.fatal 'Database error: ' + err

	del: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.del key, (err, data) ->
			callback err, data

	exists: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.exists key, (err, data) ->
			callback err, data

	expire: (key, timeout, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.expire key, timeout, (err, data) ->
			callback err, data

	get: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.get key, (err, data) ->
			callback err, data

	hdel: (key, field, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hdel key, field, (err, data) ->
			callback err, data

	hget: (key, field, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hget key, field, (err, data) ->
			callback err, data

	hgetall: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hgetall key, (err, data) ->
			callback err, data

	hincrby: (key, field, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hincrby key, field, value, (err, data) ->
			callback err, data

	hset: (key, field, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hset key, field, value, (err, data) ->
			callback err, data

	incrby: (key, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.incrby key, value, (err, data) ->
			callback err, data

	sadd: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.sadd key, member, (err, data) ->
			callback err, data

	set: (key, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.set key, value, (err, data) ->
			callback err, data

	setex: (key, ttl, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.setex key, ttl, value, (err, data) ->
			callback err, data

	sismember: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.sismember key, member, (err, data) ->
			callback err, data

	smembers: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.smembers key, (err, data) ->
			callback err, data

	srem: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.srem key, member, (err, data) ->
			callback err, data

	zadd: (key, score, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zadd key, score, member, (err, data) ->
			callback err, data

	zcard: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zcard key, (err, data) ->
			callback err, data

	zcount: (key, min, max, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zcount key, min, max, (err, data) ->
			callback err, data

	zrank: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zrank key, member, (err, data) ->
			callback err, data

	zrevrange: (key, start, stop, withscores, callback) ->
		await @client.select @Mikuia.settings.redis.db
		if !callback?
			callback = withscores
			@client.zrevrange key, start, stop, (err, data) ->
				callback err, data
		else
			@client.zrevrange key, start, stop, withscores, (err, data) ->
				callback err, data

	zrevrank: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zrevrank key, member, (err, data) ->
			callback err, data

	zscore: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.zscore key, member, (err, data) ->
			callback err, data