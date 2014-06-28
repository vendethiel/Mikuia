module.exports =
	settings: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.isEnabled defer err, enabled
		if err then console.log err

		res.render 'settings',
			enabled: enabled

	disable: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.disable defer err, data
		if err then # OMG DO SOMETHING ABOUT THE ERROR I DON'T KNOW CALL THE POLICE
		res.redirect '/dashboard/settings'

	enable: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.enable defer err, data
		if err then # OMG DO SOMETHING ABOUT THE ERROR I DON'T KNOW CALL THE POLICE
		res.redirect '/dashboard/settings'