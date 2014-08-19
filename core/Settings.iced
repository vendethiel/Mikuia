cli = require 'cli-color'
fs = require 'fs'

# Some default fields for settings.
defaultSettings =
	bot:
		debug: false
		name: 'YourBotNameHere'
		oauth: 'oauth:YOUR_TWITCH_IRC_OAUTH_KEY'
	plugins: {}
	redis:
		host: '127.0.0.1'
		port: 6379
		db: 0
		options:
			auth_pass: '',
	twitch:
		callbackURL: 'http://127.0.0.1:2912/auth/twitch/callback'
		key: 'TWITCH_API_KEY'
		secret: 'TWITCH_API_SECRET'
	web:
		featureMethod: 'viewers'
		featureFallbackMethod: 'viewers'
		port: 5587

class exports.Settings
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	pluginGet: (plugin, key) ->
		if @Mikuia.settings.plugins[plugin]?[key]?
			return @Mikuia.settings.plugins[plugin][key]
		else if @Mikuia.Plugin.getManifest(plugin)?.settings?.server?[key]?
			return @Mikuia.Plugin.getManifest(plugin).settings.server[key]
		else
			return null

	pluginSet: (plugin, key, value) ->
		@Mikuia.settings.plugins[plugin][key] = value
		@Mikuia.Log.info 'Setting ' + cli.greenBright('plugins/' + plugin + '/' + key) + ' to ' + cli.yellowBright(value)
		@save()

	read: (callback) ->
		fs.readFile 'settings.json', (settingsErr, data) =>
			if settingsErr
				@Mikuia.Log.warning 'Settings file doesn\'t exist, creating one.'
				callback(settingsErr)
			else
				# A better way to parse JSON would be nice... errors here tend to crash everything.
				try
					@Mikuia.settings = JSON.parse data
					@Mikuia.Log.success 'Loaded settings from settings.json.'
					callback(null)
				catch e
					@Mikuia.Log.error 'Failed to parse settings.json file: ' + e
					callback(e)
			@setDefaults()
	
	save: ->
		fs.writeFileSync 'settings.json', JSON.stringify @Mikuia.settings, null, '\t'

	set: (category, key, value) ->
		@Mikuia.settings[category][key] = value
		@Mikuia.Log.info 'Setting ' + cli.greenBright(category + '.' + key) + ' to ' + cli.yellowBright(value)
		@save()

	setDefaults: () ->
		# Setting default values that don't exist in setting files.
		for category, categoryFields of defaultSettings
			if not @Mikuia.settings[category]?
				@Mikuia.settings[category] = {}
			for field, fieldDefaultValue of categoryFields
				if not @Mikuia.settings[category][field]?
					@set category, field, fieldDefaultValue