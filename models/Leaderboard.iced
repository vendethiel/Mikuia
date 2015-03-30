Model = require '../core/Model'

module.exports = class Leaderboard extends Model
	constructor: (@db, @name) ->
		@model = 'leaderboard'

	getName: -> @name

	# Info :o

	getInfo: (field, callback) ->
		@_hget '', field, callback

	setInfo: (field, value, callback) ->
		@_hset '', field, value, callback

	# Display

	getDisplayName: (callback) ->
		@getInfo 'display_name', callback

	setDisplayName: (display, callback) ->
		await @setInfo 'display_name', display, defer err, data
		callback? err, data

	getDisplayHtml: (callback) ->
		await @getInfo 'display_html', defer err, data
		if err || !data
			data = '<%value%>'
		callback err, data

	setDisplayHtml: (display, callback) ->
		await @setInfo 'display_html', display, defer err, data
		callback? err, data

	# Ordering

	getReverseOrder: (callback) ->
		await @getInfo 'reverseOrder', defer err, data
		if data == 'true'
			data = true
		if data == 'false'
			data = false
		callback err, data

	setReverseOrder: (order, callback) ->
		await @setInfo 'reverseOrder', order, defer err, data
		callback? err, data

	# Scores

	getScore: (channel, callback) ->
		@_zscore 'scores', channel, callback

	setScore: (channel, score, callback) ->
		await @_zadd 'scores', score, channel, defer err, data
		callback? err, data
