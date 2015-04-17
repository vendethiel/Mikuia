class exports.Leaderboard extends Mikuia.Model
	constructor: (@name) ->
		@model = 'leaderboard'

		Mikuia.Element.register 'leaderboards', @name

	getName: -> @name

	# Info :o

	getInfo: (field, callback) ->
		@_hget '', field, callback

	setInfo: (field, value, callback) ->
		@_hset '', field, value, callback

	# Display

	getDisplayName: (callback) ->
		@getInfo 'display_name', callback

	setDisplayName: (display, callback = ->) ->
		@setInfo 'display_name', display, callback

	getDisplayHtml: (callback) ->
		await @getInfo 'display_html', defer err, data
		if err || !data
			data = '<%value%>'
		callback err, data

	setDisplayHtml: (display, callback = ->) ->
		@setInfo 'display_html', display, callback

	# Ordering

	getReverseOrder: (callback) ->
		await @getInfo 'reverseOrder', defer err, data
		if data == 'true'
			data = true
		if data == 'false'
			data = false
		callback err, data

	setReverseOrder: (order, callback = ->) ->
		@setInfo 'reverseOrder', order, callback

	# Scores

	getScore: (channel, callback) ->
		@_zscore 'scores', channel, callback

	setScore: (channel, score, callback = ->) ->
		@_zadd 'scores', score, channel, callback
