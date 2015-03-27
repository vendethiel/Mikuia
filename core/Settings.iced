cli = require 'cli-color'
fs = require 'fs'

# Some default fields for settings.
defaultSettings =
	bot:
		admins: [
			'hatsuney'
		]
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
	twitch:
		callbackURL: 'http://127.0.0.1:2912/auth/twitch/callback'
		key: 'TWITCH_API_KEY'
		secret: 'TWITCH_API_SECRET'
	web:
		featureMethod: 'viewers'
		featureFallbackMethod: 'viewers'
		port: 5587

module.exports = class Settings
	constructor: (@Mikuia, @logger) ->

	pluginGet: (plugin, key) ->
		@Mikuia.settings.plugins[plugin]?[key] ? @Mikuia.Plugin.getManifest(plugin)?.settings?.server?[key]

	read: ->
		try
			data = fs.readFileSync 'settings.json'
			try
				@Mikuia.settings = JSON.parse data
				@logger.success cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Loaded settings from settings.json.')
			catch e # jsonError
				@logger.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to parse settings.json file: ' + e + ' (if you want to generate a default file, delete it)')
		catch e # readFileSync error
			@logger.warning cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Settings file doesn\'t exist, creating one.')
			@setDefaults()

	save: ->
		fs.writeFileSync 'settings.json', JSON.stringify @Mikuia.settings, null, '\t'

	set: (category, key, value) ->
		@Mikuia.settings[category][key] = value
		@logger.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Setting ' + cli.greenBright(category + '.' + key) + ' to ' + cli.yellowBright(value))
		@save()

	setDefaults: ->
		# Setting default values that don't exist in setting files.
		for category, categoryFields of defaultSettings
			if not @Mikuia.settings[category]?
				@Mikuia.settings[category] = {}
			for field, fieldDefaultValue of categoryFields
				if not @Mikuia.settings[category][field]?
					@set category, field, fieldDefaultValue
