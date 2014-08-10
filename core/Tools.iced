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
		files = fs.readdirSync 'web/public/img/avatars'
		return @fillArray files, limit