###
  Hello, and welcome to the land of crazy stuff! (AKA Mikuia)
  This time, I'll try to comment at least a bit of this code...
  Let's see how it goes.
###

cli = require 'cli-color'
fs = require 'fs-extra'
iced = require('iced-coffee-script').iced
path = require 'path'
repl = require 'repl'

# So yeah, let's see what happens if we go with this.
{EventEmitter} = require 'events'

Mikuia =
	Events: new EventEmitter
	Models: {}
	Stuff: {}
	settings: {}

global.iced = iced
global.Mikuia = Mikuia

fs.mkdirs 'logs/mikuia'

isEditorFile = (fileName) ->
	fileName.charAt(0) in ['.', '#']

# Loading core files (that's my way of pretending everything is okay)
for fileName in fs.readdirSync 'core'
	continue if isEditorFile(fileName)
	filePath = path.resolve './', 'core', fileName
	coreFile = require filePath
	shortName = fileName.replace '.iced', ''
	Mikuia[shortName] = new coreFile[shortName] Mikuia

Mikuia.Model = require('./class/Model').Model

# Models... at least that's how I call this weird stuff.
for fileName in fs.readdirSync 'models'
	continue if isEditorFile(fileName)
	filePath = path.resolve './', 'models', fileName
	modelFile = require filePath
	shortName = fileName.replace '.iced', ''
	Mikuia.Models[shortName] = modelFile[shortName]

# Let's load the settings!
Mikuia.Settings.read ->
	# Welp, we have our settings ready, we can now slowly check stuff, and launch!
	# First thing to check - database connection, Redis FTW.
	# CoffeeScript makes this line look really weird :D
	Mikuia.Database.connect Mikuia.settings.redis.host, Mikuia.settings.redis.port, Mikuia.settings.redis.options

	isBot = false
	isWeb = false

	switch process.argv[2]
		when 'bot'
			isBot = true
		when 'web'
			isWeb = true
		else
			isBot = true
			
	# Let's load plugins.
	fs.readdir 'plugins', (pluginDirErr, fileList) ->
		if pluginDirErr
			Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Can\'t access plugin directory.')

		Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Found ') + cli.greenBright(fileList.length) + cli.whiteBright(' plugin directories.')

		for file in fileList
			if isBot
				Mikuia.Plugin.load file, 'baseFile'
			else if isWeb
				Mikuia.Plugin.load file, 'webFile'

	if isBot
		Mikuia.Chat.connect()
		Mikuia.Twitch.init()

		if Mikuia.settings.sentry.enable
			raven = require 'raven'
			client = new raven.Client Mikuia.settings.sentry.dsn
			client.patchGlobal () ->
				Mikuia.Log.fatal 'Error reported to Sentry. Crashing!'
		else
			iced.catchExceptions()

	if isWeb
		Mikuia.Web = require './web/web.iced'

		# Stock Leaderboards
		viewerLeaderboard = new Mikuia.Models.Leaderboard 'viewers'
		viewerLeaderboard.setDisplayName 'Viewers'
		viewerLeaderboard.setDisplayHtml '<i class="fa fa-user" style="color: red;"></i> <%value%>'

r = repl.start 'Mikuia> '
r.context.Mikuia = Mikuia
console.log '\n'
