cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

class exports.Plugin
	constructor: (@Mikuia) ->
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

	load: (name, fileType) ->
		await fs.readFile 'plugins/' + name + '/manifest.json', defer err, json
		if err
			@Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Unable to open plugin ') + cli.yellowBright(name) + cli.whiteBright('\'s manifest')

		try
			manifest = JSON.parse json
		catch e
			@Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to parse manifest of plugin: ') + cli.yellowBright(name)

		unless manifest
			@Mikuia.Log.fatal cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Plugin ') + cli.yellowBright(name) + cli.whiteBright(' doesn\'t specify handlers.')

		@plugins[name] = {manifest}

		if manifest.settings?.server?
			@Mikuia.settings.plugins[name] ?= {}
			for key, value of manifest.settings.server
				if not @Mikuia.settings.plugins[name][key]?
					@Mikuia.Settings.pluginSet name, key, value

		if manifest.handlers?
			for handlerName, handler of manifest.handlers
				@handlers[handlerName] = handler
				@handlers[handlerName].plugin = name

		if manifest[fileType]?
			@Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Loading plugin: ') + cli.yellowBright(name + '/' + manifest[fileType])

			filePath = path.resolve('plugins/' + name + '/' + manifest[fileType])

			@plugins[name].module = require filePath
			@plugins[name].module.Plugin =
				getSetting: (setting) =>
					@Mikuia.Settings.pluginGet name, setting
				Log:
					success: (message) =>
						@Mikuia.Log.success '[' + cli.magentaBright(name) + '] ' + message
					info: (message) =>
						@Mikuia.Log.info '[' + cli.magentaBright(name) + '] ' + message
					warning: (message) =>
						@Mikuia.Log.warning '[' + cli.magentaBright(name) + '] ' + message
					error: (message) =>
						@Mikuia.Log.error '[' + cli.magentaBright(name) + '] ' + message
