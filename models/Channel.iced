class exports.Channel extends Mikuia.Model
	constructor: (name) ->
		@model = 'channel'
		@name = name

	getName: () ->
		return @name



	# Enabling & disabling, whatever.

	disable: (callback) ->
		await Mikuia.Database.srem 'mikuia:channels', @getName(), defer err, data
		callback err, data

	enable: (callback) ->
		await Mikuia.Database.sadd 'mikuia:channels', @getName(), defer err, data
		callback err, data

	isEnabled: (callback) ->
		await Mikuia.Database.sismember 'mikuia:channels', @getName(), defer err, data
		callback err, data