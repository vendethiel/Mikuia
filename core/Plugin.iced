cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

class exports.Plugin
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@handlers = {}
		@plugins = {}

	exists: (plugin) -> @plugins[plugin]?

	get: (plugin) -> @plugins[plugin].module

	getAll: () -> @plugins

	getHandler: (handler) ->
		if @handlers[handler]?
			return @handlers[handler]
		else
			return null

	getHandlers: () -> @handlers

	getManifest: (plugin) ->
		if @plugins[plugin]?.manifest?
			return @plugins[plugin].manifest
		else
			return null

	handlerExists: (handler) -> @handlers[handler]?

	load: (name, fileType) ->
		fs.readFile 'plugins/' + name + '/manifest.json', (err, json) =>
			if !err
				try
					manifest = JSON.parse json
				catch e
					@Mikuia.Log.error cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to parse manifest of plugin: ') + cli.yellowBright(name)

				if manifest?
					if manifest[fileType]?
						@Mikuia.Log.info cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Loading plugin: ') + cli.yellowBright(name + '/' + manifest[fileType])

						filePath = path.resolve('plugins/' + name + '/' + manifest[fileType])
						@plugins[name] =
							manifest: manifest
							module: require filePath

						@plugins[name].module.Plugin =
							getSetting: (setting) =>
								return @Mikuia.Settings.pluginGet name, setting
							Log:
								success: (message) =>
									@Mikuia.Log.success '[' + cli.magentaBright(name) + '] ' + message
								info: (message) =>
									@Mikuia.Log.info '[' + cli.magentaBright(name) + '] ' + message
								warning: (message) =>
									@Mikuia.Log.warning '[' + cli.magentaBright(name) + '] ' + message
								error: (message) =>
									@Mikuia.Log.error '[' + cli.magentaBright(name) + '] ' + message

						if manifest.settings?.server?
							if not @Mikuia.settings.plugins[name]?
								@Mikuia.settings.plugins[name] = {}
							for key, value of manifest.settings.server	
								if not @Mikuia.settings.plugins[name][key]?
									@Mikuia.Settings.pluginSet name, key, value

						if manifest.handlers?
							for handlerName, handler of manifest.handlers
								@handlers[handlerName] = handler
								@handlers[handlerName].plugin = name
					else
						@Mikuia.Log.warning cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Plugin ') + cli.yellowBright(name) + cli.whiteBright(' doesn\'t specify a base file.')
					
			else
				@Mikuia.Log.error cli.whiteBright('Mikuia') + ' / ' + cli.whiteBright('Failed to read manifest of plugin ') + cli.yellowBright(name) + cli.whiteBright('.')

		

		