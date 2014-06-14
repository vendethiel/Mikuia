cli = require 'cli-color'
iced = require 'iced-coffee-script'.iced
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