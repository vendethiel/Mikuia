{EventEmitter} = require 'events'
path = require 'path'
fs = require 'fs-extra'
{isEditorFile} = require './helpers'

module.exports = class Mikuia
	constructor: ->
		@Events = new EventEmitter
		@Models = {}
		@Stuff = {}
		@settings = {}

	loadCoreFiles: ->
		console.log 'core'
		@Log = new (require './Log')
		@Settings = new (require './Settings')(this, @Log)
		@Twitch = new (require './Twitch')
		@Database = new (require './Database')(@settings, @Log)
		@Chat = new (require './Chat')(@settings, @Log, @Database)
		@Format = new (require './Format')
		@Plugin = new (require './Plugin')(@Log)
		@Tracker = new (require './Tracker')

	loadModelFiles: ->
		console.log 'models'
		# Models... at least that's how I call this weird stuff.
		console.dir fs.readdirSync 'models'
		for fileName in fs.readdirSync 'models'
			continue if isEditorFile(fileName)
			filePath = path.resolve './', 'models', fileName
			modelFile = require filePath
			shortName = fileName.replace '.iced', ''
			@Models[shortName] = modelFile

	loadPlugins: (files, fileType) ->
		@settings.plugins ?= {}
		for file in files
			await @Plugin.load file, fileType, defer @settings.plugins[file]
