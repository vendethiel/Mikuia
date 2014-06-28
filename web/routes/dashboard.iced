module.exports = (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username

	await Channel.isEnabled defer err, enabled
	if err then console.log err

	res.render 'dashboard', {
		enabled: enabled
	}