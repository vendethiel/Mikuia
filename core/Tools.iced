fs = require 'fs'
_ = require 'underscore'

class exports.Tools
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	chunkArray: (array, size) ->
		R = []
		for i in [0..array.length] by size
			R.push array.slice i, i + size
		return R

	fillArray: (data, size) ->
		array = data.slice 0
		while array.length < size
			array.push.apply array, array
		return _.shuffle array

	getAvatars: (limit) ->
		avatarFolder = 'web/public/img/avatars'
		if not fs.existsSyncpath avatarFolder
			return []
		files = fs.readdirSync avatarFolder
		return @fillArray files, limit

	getExperience: (level) ->
		if level > 0
			return (((level * 20) * level * 0.8) + level * 100) - 16
		else
			return 0

	getLevel: (experience) ->
		level = 0
		while experience >= @getExperience level
			level++

		return level - 1