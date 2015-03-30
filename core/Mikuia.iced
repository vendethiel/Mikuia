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
		@Chat = new (require './Chat')(@settings, @Log, @Database, @Models, @Events, @Plugin)
		@Format = new (require './Format')
		@Plugin = new (require './Plugin')(@Settings, @Log)

		@Database.connect @settings.redis.host, @settings.redis.port, @settings.redis.options
		@loadModelFiles()

	loadModelFiles: ->
		# TODO there's probably a better way to do that...
		ModelClasses = require('../models')
		@Models =
			Badge: (name) => new ModelClasses.Badge(@Database, name)
			Leaderboard: (name) => new ModelClasses.Leaderboard(@Database, name)
			Channel: (name) => new ModelClasses.Channel(@Database, @settings, name)

	loadPlugins: (files, fileType) ->
		@settings.plugins ?= {}
		for file in files
			await @Plugin.load file, fileType, defer @settings.plugins[file]
