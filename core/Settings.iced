cli = require 'cli-color'
fs = require 'fs'

# Some default fields for settings.
defaultSettings =
	bot:
		admins: [
			'hatsuney'
		]
		connections: 2
		debug: false
		disableChat: false
		name: 'YourBotNameHere'
		oauth: 'oauth:YOUR_TWITCH_IRC_OAUTH_KEY'
		autojoin: []
	plugins: {}
	redis:
		host: '127.0.0.1'
		port: 6379
		db: 0
		options:
			auth_pass: '',
	sentry:
		enable: false
		dsn: 'https://username:password@app.getsentry.com/id'
	slack:
		channel: 'SLACK_CHANNEL_ID'
		token: 'SLACK_TOKEN_FOR_INVITES'
	twitch:
		callbackURL: 'http://127.0.0.1:2912/auth/twitch/callback'
		key: 'TWITCH_API_KEY'
		secret: 'TWITCH_API_SECRET'
	web:
		featureMethod: 'viewers'
		featureFallbackMethod: 'viewers'
		port: 5587

class exports.Settings
	constructor: (@Mikuia) ->

	pluginGet: (plugin, key) ->
		@Mikuia.settings.plugins[plugin]?[key] ? @Mikuia.Plugin.getManifest(plugin)?.settings?.server?[key]

	pluginSet: (plugin, key, value) ->
		@Mikuia.settings.plugins[plugin][key] = value
		@Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + 'Setting ' + cli.greenBright('plugins/' + plugin + '/' + key) + ' to ' + cli.yellowBright(value)
		@save()

	read: (callback) ->
		fs.readFile 'settings.json', (settingsErr, data) =>
			if settingsErr
				@Mikuia.Log.warning cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Settings file doesn\'t exist, creating one.')
				@setDefaults()
			else
				# A better way to parse JSON would be nice... errors here tend to crash everything.
				try
					@Mikuia.settings = JSON.parse data
					@Mikuia.Log.success cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Loaded settings from settings.json.')
				catch e
				 	@Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to parse settings.json file: ' + e + ' (if you want to generate a default file, delete it)')

			callback settingsErr

	save: ->
		fs.writeFileSync 'settings.json', JSON.stringify @Mikuia.settings, null, '\t'

	set: (category, key, value) ->
		@Mikuia.settings[category][key] = value
		@Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Setting ' + cli.greenBright(category + '.' + key) + ' to ' + cli.yellowBright(value))
		@save()

	setDefaults: ->
		# Setting default values that don't exist in setting files.
		for category, categoryFields of defaultSettings
			if not @Mikuia.settings[category]?
				@Mikuia.settings[category] = {}
			for field, fieldDefaultValue of categoryFields
				if not @Mikuia.settings[category][field]?
					@set category, field, fieldDefaultValue
