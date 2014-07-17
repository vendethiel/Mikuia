class exports.Channel extends Mikuia.Model
	constructor: (name) ->
		@model = 'channel'
		@name = name.replace('#', '').toLowerCase()

	# Core functions, changing those often end up breaking half of the universe.

	getName: () ->
		return @name

	# Info & settings

	getInfo: (field, callback) ->
		await @_hget @getName(), field, defer err, data
		callback err, data

	getSetting: (plugin, field, callback) ->
		await @_hget @getName() + ':plugin:' + plugin + ':settings', field, defer err, data
		if !data && Mikuia.Plugin.getManifest(plugin)?.settings?.channel?[field]?.default?
			data = Mikuia.Plugin.getManifest(plugin).settings.channel[field].default
		callback err, data

	getSettings: (plugin, callback) ->
		await @_hgetall @getName() + ':plugin:' + plugin + ':settings', defer err, data
		callback err, data

	setInfo: (field, value, callback) ->
		await @_hset @getName(), field, value, defer err, data
		callback err, data

	setSetting: (plugin, field, value, callback) ->
		if value != ''
			await @_hset @getName() + ':plugin:' + plugin + ':settings', field, value, defer err, data
		else
			await @_hdel @getName() + ':plugin:' + plugin + ':settings', field, defer err, data
		callback err, data

	# Enabling & disabling, whatever.

	disable: (callback) ->
		await Mikuia.Database.srem 'mikuia:channels', @getName(), defer err, data
		callback err, data

	enable: (callback) ->
		await Mikuia.Database.sadd 'mikuia:channels', @getName(), defer err, data
		callback err, data

	isEnabled: (callback) ->
		await Mikuia.Database.sismember 'mikuia:channels', @getName(), defer err, data
		callback err, data

	# Commands

	addCommand: (command, handler, callback) ->
		await @_hset @getName() + ':commands', command, handler, defer err, data
		callback err, data

	getCommand: (command, callback) ->
		await @_hget @getName() + ':commands', command, defer err, data
		callback err, data

	getCommands: (callback) ->
		await @_hgetall @getName() + ':commands', defer err, data
		callback err, data

	# Plugins

	disablePlugin: (name, callback) ->
		await @_srem @getName() + ':plugins', name, defer err, data
		callback err, data

	enablePlugin: (name, callback) ->
		await @_sadd @getName() + ':plugins', name, defer err, data
		callback err, data

	getEnabledPlugins: (callback) ->
		await @_smembers @getName() + ':plugins', defer err, data
		callback err, data

	isPluginEnabled: (name, callback) ->
		await @_sismember @getName() + ':plugins', name, defer err, data
		callback err, data

	# "Convenience" functions that help get and set data...  or something.

	setBio: (bio, callback) ->
		await @setInfo 'bio', bio, defer err, data
		callback err, data

	setEmail: (email, callback) ->
		await @setInfo 'email', email, defer err, data
		callback err, data

	setLogo: (logo, callback) ->
		await @setInfo 'logo', logo, defer err, data
		callback err, data