Model = require '../core/Model'

class exports.Badge extends Model
	constructor: (name) ->
		@model = 'badge'
		@name = name

	exists: (callback) ->
		await @_exists callback

	getAll: (callback) ->
		@_hgetall '', callback

	getDescription: (callback) ->
		@getInfo 'description', callback

	getDisplayName: (callback) ->
		@getInfo 'display_name', callback

	getMemberCount: (callback) ->
		@_scard 'members', callback

	getMembers: (callback) ->
		@_smembers 'members', callback

	getName: (callback) ->
		# wtf???
		return @name

	setDescription: (display, callback) ->
		await @setInfo 'description', description, defer err, data
		callback? err, data

	setDisplayName: (display, callback) ->
		await @setInfo 'display_name', display, defer err, data
		callback? err, data
