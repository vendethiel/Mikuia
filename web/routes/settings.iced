module.exports =
	settings: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		plugins = Mikuia.Plugin.getAll()

		await
			Channel.isEnabled defer err, enabled
			Channel.getEnabledPlugins defer err, enabledPlugins

		settings = {}
		for pluginName in enabledPlugins
			await Channel.getSettings pluginName, defer err, settings[pluginName]

		res.render 'settings',
			enabled: enabled
			enabledPlugins: enabledPlugins
			plugins: plugins
			settings: settings

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

	save: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		if Mikuia.Plugin.exists req.params.name
			manifest = Mikuia.Plugin.getManifest req.params.name
			for setting, value of req.body
				if manifest.settings.channel?[setting]?
					# To do: some kind of entry validation, and errors?
					await Channel.setSetting req.params.name, setting, value, defer err, data

		res.redirect '/dashboard/settings'