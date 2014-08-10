module.exports =
	index: (req, res) ->
		res.render 'community/index'

	streams: (req, res) ->
		res.render 'community/streams'