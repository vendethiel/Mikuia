fs = require 'fs'
_ = require 'underscore'

chunkArray = (array, size) ->
	for i in [0..array.length] by size
		array.slice i, i + size

colorRarity = (rarity) ->
	switch rarity
		when 'common'
			'<span style="color: white;">Common</span>'
		when 'uncommon'
			'<span style="color: #1eff00;">Uncommon</span>'
		when 'rare'
			'<span style="color: #338BFF;">Rare</span>'
		when 'epic'
			'<span style="color: #B356F0;">Epic</span>'
		when 'legendary'
			'<span style="color: #FF9933;">Legendary</span>'
		when 'unique'
			'<span style="color: #e6cc80;">Unique</span>'
		else
			'<span style="color: red;">UNKNOWN</span>'

fillArray = (data, size) ->
	array = data.slice 0
	while array.length < size
	 	array.push.apply array, array
	_.shuffle array

getAvatars = (limit) ->
	files = fs.readdirSync 'web/public/img/avatars'
	fillArray files, limit

getExperience = (level) ->
	if level > 0
		(((level * 20) * level * 0.8) + level * 100) - 16
	else
		0

getLevel = (experience) ->
	level = 0
	while experience >= getExperience level
		level++

	level - 1

isEditorFile = (fileName) ->
	return true if fileName.charAt(0) in ['.', '#']
	return true if fileName.charAt(fileName.length - 1) == '~'
	return false

module.exports = {
	chunkArray, colorRarity, fillArray,
	getAvatars, getExperience, getLevel, isEditorFile
}
