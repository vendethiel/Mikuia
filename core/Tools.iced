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

	colorRarity: (rarity) ->
		switch rarity
			when 'common'
				return '<span style="color: white;">Common</span>';
			when 'uncommon'
				return '<span style="color: #1eff00;">Uncommon</span>';
			when 'rare'
				return '<span style="color: #338BFF;">Rare</span>';
			when 'epic'
				return '<span style="color: #B356F0;">Epic</span>';
			when 'legendary'
				return '<span style="color: #FF9933;">Legendary</span>';
			when 'unique'
				return '<span style="color: #e6cc80;">Unique</span>';
			else
				return '<span style="color: red;">UNKNOWN</span>';

	fillArray: (data, size) ->
		array = data.slice 0
		while array.length < size
			array.push.apply array, array
		return _.shuffle array

	getAvatars: (limit) ->
		files = fs.readdirSync 'web/public/img/avatars'
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