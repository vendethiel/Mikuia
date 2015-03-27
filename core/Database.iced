cli = require 'cli-color'
redis = require 'redis'

module.exports = class Database
	constructor: (@settings, @logger) ->

	connect: (host, port, options) ->
		@logger.info cli.redBright('Redis') + ' / ' + cli.whiteBright('Attempting to connect with the server at ' + host + ':' + port + '...')
		@client = redis.createClient port, host, options
		@client.on 'ready', =>
			@logger.success cli.redBright('Redis') + ' / ' + cli.whiteBright('Connected to the database.')
		@client.on 'error', (err) =>
			console.trace()
			@logger.fatal cli.redBright('Redis') + ' / ' + cli.whiteBright('Database error: ' + err)

	del: (key, callback) ->
		await @client.select @settings.redis.db
		@client.del key, callback

	exists: (key, callback) ->
		await @client.select @settings.redis.db
		@client.exists key, callback

	expire: (key, timeout, callback) ->
		await @client.select @settings.redis.db
		@client.expire key, timeout, callback

	get: (key, callback) ->
		await @client.select @settings.redis.db
		@client.get key, callback

	hdel: (key, field, callback) ->
		await @client.select @settings.redis.db
		@client.hdel key, field, callback

	hget: (key, field, callback) ->
		await @client.select @settings.redis.db
		@client.hget key, field, callback

	hgetall: (key, callback) ->
		await @client.select @settings.redis.db
		@client.hgetall key, callback

	hincrby: (key, field, value, callback) ->
		await @client.select @settings.redis.db
		@client.hincrby key, field, value, callback

	hset: (key, field, value, callback) ->
		await @client.select @settings.redis.db
		@client.hset key, field, value, callback

	incrby: (key, value, callback) ->
		await @client.select @settings.redis.db
		@client.incrby key, value, callback

	sadd: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.sadd key, member, callback

	scard: (key, callback) ->
		await @client.select @settings.redis.db
		@client.scard key, callback

	set: (key, value, callback) ->
		await @client.select @settings.redis.db
		@client.set key, value, callback

	setex: (key, ttl, value, callback) ->
		await @client.select @settings.redis.db
		@client.setex key, ttl, value, callback

	sismember: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.sismember key, member, callback

	smembers: (key, callback) ->
		await @client.select @settings.redis.db
		@client.smembers key, callback

	srem: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.srem key, member, callback

	zadd: (key, score, member, callback) ->
		await @client.select @settings.redis.db
		@client.zadd key, score, member, callback

	zcard: (key, callback) ->
		await @client.select @settings.redis.db
		@client.zcard key, callback

	zcount: (key, min, max, callback) ->
		await @client.select @settings.redis.db
		@client.zcount key, min, max, callback

	zincrby: (key, member, increment, callback) ->
		await @client.select @settings.redis.db
		@client.zincrby key, member, increment, callback

	zrank: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.zrank key, member, callback

	zrevrange: (key, start, stop, withscores, callback) ->
		await @client.select @settings.redis.db
		if !callback?
			callback = withscores
			@client.zrevrange key, start, stop, callback
		else
			@client.zrevrange key, start, stop, withscores, callback

	zrevrangebyscore: (key, max, min, withscores, callback) ->
		await @client.select @settings.redis.db
		if !callback?
			callback = withscores
			@client.zrevrangebyscore key, max, min, callback
		else
			@client.zrevrangebyscore key, max, min, withscores, callback

	zrevrank: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.zrevrank key, member, callback

	zscore: (key, member, callback) ->
		await @client.select @settings.redis.db
		@client.zscore key, member, callback
