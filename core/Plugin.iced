cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

class exports.Plugin
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@plugins = {}

	exists: (plugin) ->
		return @plugins[plugin]?

	getAll: () -> @plugins

	getManifest: (plugin) ->
		if @plugins[plugin]?.manifest?
			return @plugins[plugin][manifest]
		else
			return null

	load: (name) ->
		@Mikuia.Log.info 'Reading directory: ' + cli.yellowBright(name)

		fs.readFile 'plugins/' + name + '/manifest.json', (err, json) =>
			if !err
				try
					manifest = JSON.parse json
				catch e
					@Mikuia.Log.error 'Failed to parse manifest of plugin: ' + cli.yellowBright(name)

				if manifest?
					if manifest.baseFile?
						@Mikuia.Log.info 'Loading plugin: ' + cli.yellowBright(name + '/' + manifest.baseFile)

						filePath = path.resolve('plugins/' + name + '/' + manifest.baseFile)
						@plugins[name] =
							manifest: manifest
							module: require filePath

						@plugins[name].module.Plugin =
							getSetting: (setting) =>
								return @Mikuia.Settings.pluginGet name, setting

						if manifest.settings?.server?
							if not @Mikuia.settings.plugins[name]?
								@Mikuia.settings.plugins[name] = {}
							for key, value of manifest.settings.server	
								if not @Mikuia.settings.plugins[name][key]?
									@Mikuia.Settings.pluginSet name, key, value
					else
						@Mikuia.Log.error 'Plugin ' + cli.yellowBright(name) + ' does not specify base file.'
					
			else
				@Mikuia.Log.error 'Failed to read manifest of plugin ' + cli.yellowBright(name)

		

		