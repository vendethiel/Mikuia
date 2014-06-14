###
  Hello, and welcome to the land of crazy stuff! (AKA Mikuia)
  This time, I'll try to comment at least a bit of this code...
  Let's see how it goes.  
###

cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

Mikuia =
  Models: {}

  settings: {}

# Loading core files (that's my way of pretending everything is okay)
for fileName in fs.readdirSync 'core'
  filePath = path.resolve './', 'core', fileName
  coreFile = require filePath
  shortName = fileName.replace '.iced', ''
  Mikuia[shortName] = new coreFile[shortName] Mikuia

# Some default fields for settings, maybe will get moved to other file.
defaultSettings =
	bot:
		debug: false
		name: 'YourBotNameHere'
		oauth: 'oauth:YOUR_TWITCH_IRC_OAUTH_KEY'
	redis:
		host: '127.0.0.1'
		port: 6379
		db: 0
		options:
			auth_pass: ''

# Let's load the settings!
fs.readFile 'settings.json', (settingsErr, data) ->
	if settingsErr
		Mikuia.Log.warning 'Settings file doesn\'t exist, creating one.'
	else
		# A better way to parse JSON would be nice... errors here tend to crash everything.
		try
			Mikuia.settings = JSON.parse data
			Mikuia.Log.success 'Loaded settings from settings.json.'
		catch e
			Mikuia.Log.error 'Failed to parse settings.json file.'
	
	# Setting default values that don't exist in setting files.
	for category, categoryFields of defaultSettings
		if not Mikuia.settings[category]?
			Mikuia.settings[category] = {}
		for field, fieldDefaultValue of categoryFields
			if not Mikuia.settings[category][field]?
				Mikuia.settings[category][field] = fieldDefaultValue
				Mikuia.Log.info 'Setting ' + cli.greenBright(category + '/' + field) + ' to ' + cli.yellowBright(fieldDefaultValue)

	# Saving the settings file!
	fs.writeFileSync 'settings.json', JSON.stringify Mikuia.settings, null, '\t'

	# Welp, we have our settings ready, we can now slowly check stuff, and launch!
	# First thing to check - database connection, Redis FTW.
	# CoffeeScript makes this line look really weird :D
	Mikuia.Database.connect Mikuia.settings.redis.host, Mikuia.settings.redis.port, Mikuia.settings.redis.options

	# Let's load plugins.
	fs.readdir 'plugins', (pluginDirErr, fileList) ->
		if pluginDirErr
			Mikuia.Log.warning 'Can\'t access plugin directory.'
		else
			Mikuia.Log.info 'Found ' + cli.greenBright(fileList.length) + ' files in plugin directory.'
			
		for file in fileList
			Mikuia.Plugin.load file
		
	Mikuia.Chat.connect()

	await Mikuia.Database.get 'derp', defer err, data
	console.log data