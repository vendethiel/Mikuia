module.exports =
	plugins: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		plugins = Mikuia.Plugin.getAll()

		await
			Channel.isEnabled defer err, enabled
			Channel.getEnabledPlugins defer err, enabledPlugins

		categories = {}
		settings = {}
		for pluginName in enabledPlugins
			await Channel.getSettings pluginName, defer err, settings[pluginName]

			categories[pluginName] = {}
			manifest = Mikuia.Plugin.getManifest(pluginName)
			if manifest?.settings?.channel?
				for settingName, setting of manifest.settings.channel
					if setting.category?
						if !categories[pluginName][setting.category]?
							categories[pluginName][setting.category] = {}
						categories[pluginName][setting.category][settingName] = setting

		res.render 'plugins',
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
					res.send
						enabled: true
				when "disable"
					await Channel.disablePlugin data.name, defer err, data
					res.send
						enabled: false
		else
			res.send 500