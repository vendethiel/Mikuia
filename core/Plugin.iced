class exports.Plugin
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	load: (name) ->
		@Mikuia.Log.info 'Loading plugin: ' + name