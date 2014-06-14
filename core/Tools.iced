class exports.Tools
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	chunkArray: (array, size) ->
		R = []
		for i in [0..array.length] by size
			R.push array.slice i, i + size
		return R