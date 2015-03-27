module.exports = class Tracker
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	_lb: (model, name, key, value, callback) ->
		if model == 'channel'
			lb = new Mikuia.Models.Leaderboard key
			lb.setScore name, value
		if callback
			callback err, data

	get: (model, name, key, callback) ->
		await Mikuia.Database.get model + ':' + name + ':_tracker:' + key + ':value', defer err, data
		if !data?
			data = 0
		callback err, data

	increment: (model, name, key, value, callback) ->
		await Mikuia.Database.incrby model + ':' + name + ':_tracker:' + key + ':value', value, defer err, data
		if !err
			@_lb model, name, key, data
		else
			@_lb model, name, key, value
		callback err, data

	track: (model, name, key, value, callback) ->
		await Mikuia.Database.set model + ':' + name + ':_tracker:' + key + ':value', value, defer err, data
		@_lb model, name, key, value
		callback err, data
