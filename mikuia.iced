###
  Hello, and welcome to the land of crazy stuff! (AKA Mikuia)
  This time, I'll try to comment at least a bit of this code...
  Let's see how it goes.
###

cli = require 'cli-color'
fs = require 'fs-extra'
iced = require('iced-coffee-script').iced
repl = require 'repl'

global.iced = iced

fs.mkdirs 'logs/mikuia'

Mikuia = new (require './core/Mikuia')
Leaderboard = require './models/Leaderboard'

r = repl.start 'Mikuia> '
r.context.Mikuia = Mikuia
console.log '\n'

Mikuia.initialize()

isBot = false
isWeb = false

switch process.argv[2]
	when 'bot'
		isBot = true
	when 'web'
		isWeb = true
# else
# 	flipOut()

# Let's load plugins.
fs.readdir 'plugins', (pluginDirErr, fileList) ->
	if pluginDirErr
		Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Can\'t access plugin directory.')

	Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Found ') + cli.greenBright(fileList.length) + cli.whiteBright(' plugin directories.')

	Mikuia.loadPlugins(fileList, if isBot then 'baseFile' else 'webFile')

	if isBot
		Mikuia.Chat.connect()
		Mikuia.Chat.update()

	if Mikuia.settings.sentry.enable
		raven = require 'raven'
		client = new raven.Client Mikuia.settings.sentry.dsn
		client.patchGlobal () ->
		Mikuia.Log.fatal 'Error reported to Sentry. Crashing!'
	else
		iced.catchExceptions()

	if isWeb
		Mikuia.Web = require './web/web.iced'

# Stock Leaderboards (why is that here?)
viewerLeaderboard = new Leaderboard Mikuia.Database, 'viewers'
viewerLeaderboard.setDisplayName 'Viewers'
viewerLeaderboard.setDisplayHtml '<i class="fa fa-user" style="color: red;"></i> <%value%>'
