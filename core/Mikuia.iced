{EventEmitter} = require 'events'
path = require 'path'
fs = require 'fs-extra'
{isEditorFile} = require './helpers'

module.exports = class Mikuia
	constructor: ->
		@Events = new EventEmitter
		@Stuff = {}
		@settings = {}

	initialize: ->
		@Log = new (require './Log')
		@Settings = new (require './Settings')(this, @Log)
		@Settings.read()

		@Database = new (require './Database')(@settings, @Log)
		# Chat does *a bit* too much
		@Chat = new (require './Chat')(@settings, @Log, @Database, @Events, @Plugin)
		@Format = new (require './Format')
		@Plugin = new (require './Plugin')(@Settings, @Log)

		@Database.connect @settings.redis.host, @settings.redis.port, @settings.redis.options

	loadPlugins: (files, fileType) ->
		@settings.plugins ?= {}
		for file in files
			await @Plugin.load file, fileType, defer @settings.plugins[file]
