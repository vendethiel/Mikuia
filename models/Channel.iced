class exports.Channel extends Mikuia.Model
	constructor: (name) ->
		@model = 'channel'
		@name = name

	# Core functions, changing those often end up breaking half of the universe.

	getName: () ->
		return @name

	setInfo: (field, value, callback) ->
		await @_hset @getName(), field, value, defer err, data
		callback err, data

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

	# "Convenience" functions that help get and set data...  or something.

	setBio: (bio, callback) ->
		await @setInfo 'bio', bio, defer err, data
		callback err, data

	setEmail: (email, callback) ->
		await @setInfo 'email', email, defer err, data
		callback err, data

	setLogo: (logo, callback) ->
		await @setInfo 'logo', logo, defer err, data
		callback err, data