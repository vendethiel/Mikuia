cli = require 'cli-color'
fs = require 'fs'
path = require 'path'

class exports.Plugin
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@plugins = {}

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
						@plugins[name] = require filePath

					else
						@Mikuia.Log.error 'Plugin ' + cli.yellowBright(name) + ' does not specify base file.'

			else
				@Mikuia.Log.error 'Failed to read manifest of plugin ' + cli.yellowBright(name)

		

		