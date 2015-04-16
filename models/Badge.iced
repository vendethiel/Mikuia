Model = require '../core/Model'

class exports.Badge extends Model
	constructor: (@db, @name) ->
		@model = 'badge'

	exists: (callback) ->
		@_exists callback

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

	getName: -> @name

	setDescription: (display, callback = ->) ->
		@setInfo 'description', description, callback

	setDisplayName: (display, callback = ->) ->
		await @setInfo 'display_name', display, callback
