class exports.Model
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@model = 'model'
		@name = ''

	_sismember: (key, value, callback) ->
		await @Mikuia.Database.sismember @model + ':' + @name + ':' + key, value, defer err, data
		callback err, data