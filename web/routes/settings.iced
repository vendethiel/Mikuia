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

	pluginToggle: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.status? && data.name?
			switch data.status
				when "enable"
					await Channel.enablePlugin data.name, defer err, data
				when "disable"
					await Channel.disablePlugin data.name, defer err, data

		res.send 200

	save: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		if Mikuia.Plugin.exists req.params.name
			manifest = Mikuia.Plugin.getManifest req.params.name
			for settingName, setting of manifest.settings.channel
				if setting.type == 'boolean'
					if req.body[settingName]? && req.body[settingName] == 'on'
							req.body[settingName] = true
						else 
							req.body[settingName] = false
				if req.body[settingName]? && setting.type != 'disabled'
					# To do: some kind of entry validation, and errors?
					await Channel.setSetting req.params.name, settingName, req.body[settingName], defer err, data

		res.redirect '/dashboard/settings'

	toggle: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.status?
			switch data.status
				when "enable"
					await Channel.enable defer err, data
				when "disable"
					await Channel.disable defer err, data

		res.send 200