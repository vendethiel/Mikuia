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
			@Mikuia.Log.fatal 'Failed to connect to database. '
			@Mikuia.Log.fatal err
			process.exit()

	get: (key, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.get key, (err, data) ->
			callback err, data

	hget: (key, field, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hget key, field, (err, data) ->
			callback err, data

	hset: (key, field, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.hset key, field, value, (err, data) ->
			callback err, data

	sadd: (key, member, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.sadd key, member, (err, data) ->
			callback err, data

	set: (key, value, callback) ->
		await @client.select @Mikuia.settings.redis.db
		@client.set key, value, (err, data) ->
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