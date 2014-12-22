class exports.Badge extends Mikuia.Model
	constructor: (name) ->
		@model = 'badge'
		@name = name

	exists: (callback) ->
		await @_exists '', defer err, data
		callback err, data

	getAll: (callback) ->
		await @_hgetall '', defer err, data
		callback err, data

	getDescription: (callback) ->
		await @getInfo 'description', defer err, data
		callback err, data

	getDisplayName: (callback) ->
		await @getInfo 'display_name', defer err, data
		callback err, data

	getMemberCount: (callback) ->
		await @_scard 'members', defer err, data
		callback err, data

	getMembers: (callback) ->
		await @_smembers 'members', defer err, data
		callback err, data

	getName: (callback) ->
		return @name

	setDescription: (display, callback) ->
		await @setInfo 'description', description, defer err, data
		if callback
			callback err, data

	setDisplayName: (display, callback) ->
		await @setInfo 'display_name', display, defer err, data
		if callback
			callback err, data