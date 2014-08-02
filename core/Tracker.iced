class exports.Tracker
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	get: (model, name, key, callback) ->
		await Mikuia.Database.get model + ':' + name + ':_tracker:' + key + ':value', defer err, data
		if !data?
			data = 0
		callback err, data

	increment: (model, name, key, value, callback) ->
		await Mikuia.Database.incrby model + ':' + name + ':_tracker:' + key + ':value', value, defer err, data
		callback err, data

	track: (model, name, key, value, callback) ->
		await Mikuia.Database.set model + ':' + name + ':_tracker:' + key + ':value', value, defer err, data
		callback err, data