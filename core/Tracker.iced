module.exports = class Tracker
	constructor: (@db, @inst) ->
		@model = @inst.model
		@name = @inst.getName()

	_lb: (key, value, callback) ->
		if @model == 'channel'
			# TODO fix this. this is broken
			lb = new Mikuia.Models.Leaderboard key
			lb.setScore name, value
		callback? err, data

	get: (key, callback) ->
		await Mikuia.Database.get @model + ':' + @name + ':_tracker:' + key + ':value', defer err, data
		data = 0 if !data? # iced scoping bug with defer
		callback err, data

	increment: (key, value, callback) ->
		await Mikuia.Database.incrby @model + ':' + @name + ':_tracker:' + key + ':value', value, defer err, data
		if err
			@_lb key, value
		else
			@_lb key, data
		callback err, data

	value: (key, value, callback) ->
		await Mikuia.Database.set @model + ':' + @name + ':_tracker:' + key + ':value', value, defer err, data
		@_lb key, value
		callback err, data
