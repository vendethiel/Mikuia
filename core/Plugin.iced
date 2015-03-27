cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

module.exports = class Plugin
	constructor: (@Settings, @logger) ->
		@handlers = {}
		@plugins = {}

	exists: (plugin) -> @plugins[plugin]?

	get: (plugin) -> @plugins[plugin].module

	getAll: -> @plugins

	getHandler: (handler) -> @handlers[handler]

	getHandlers: -> @handlers

	getManifest: (plugin) ->
		@plugins[plugin]?.manifest

	handlerExists: (handler) -> @handlers[handler]?

	load: (name, fileType, callback) ->
		await fs.readFile 'plugins/' + name + '/manifest.json', defer err, json
		if err
			@logger.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Unable to open plugin ') + cli.yellowBright(name) + cli.whiteBright('\'s manifest')

		try
			manifest = JSON.parse json
		catch e
			@logger.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to parse manifest of plugin: ') + cli.yellowBright(name)

		unless manifest
			@logger.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Plugin ') + cli.yellowBright(name) + cli.whiteBright(' doesn\'t specify handlers.')

		@plugins[name] = {manifest}

		needSave = false # shall we save settings?
		settings = {}
		if manifest.settings?.server?
			for key, value of manifest.settings.server
				if not settings[key]?
					settings[key] = value
					@logger.info cli.whiteBright('Mikuia') + ' / ' + 'Setting ' + cli.greenBright('plugins/' + plugin + '/' + key) + ' to ' + cli.yellowBright(value)

		callback settings
		if needSave # if we had some default setting set...
			@Settings.save()

		if manifest.handlers?
			for handlerName, handler of manifest.handlers
				@handlers[handlerName] = handler
				@handlers[handlerName].plugin = name

		if manifest[fileType]?
			@logger.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Loading plugin: ') + cli.yellowBright(name + '/' + manifest[fileType])

			filePath = path.resolve('plugins/' + name + '/' + manifest[fileType])
			@plugins[name].module = plugin = require filePath

			if plugin.elements
				for element in plugin.elements
					@Element.register name,

			@plugins[name].module.Plugin =
				getSetting: (setting) =>
					@settings.pluginGet name, setting
				Log:
					success: (message) =>
						@logger.success '[' + cli.magentaBright(name) + '] ' + message
					info: (message) =>
						@logger.info '[' + cli.magentaBright(name) + '] ' + message
					warning: (message) =>
						@logger.warning '[' + cli.magentaBright(name) + '] ' + message
					error: (message) =>
						@logger.error '[' + cli.magentaBright(name) + '] ' + message
