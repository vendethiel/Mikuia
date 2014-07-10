module.exports =
	settings: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		plugins = Mikuia.Plugin.getAll()

		await
			Channel.isEnabled defer err, enabled
			Channel.getEnabledPlugins defer err, enabledPlugins
		if err then console.log err

		res.render 'settings',
			enabled: enabled
			enabledPlugins: enabledPlugins
			plugins: plugins

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

	pluginDisable: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		if Mikuia.Plugin.exists req.params.name
			await Channel.disablePlugin req.params.name, defer err, data

		res.redirect '/dashboard/settings'

	pluginEnable: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		if Mikuia.Plugin.exists req.params.name
			await Channel.enablePlugin req.params.name, defer err, data

		res.redirect '/dashboard/settings'