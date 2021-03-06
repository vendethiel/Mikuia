module.exports =
	settings: (req, res) ->
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

		res.render 'settings',
			categories: categories
			enabled: enabled
			enabledPlugins: enabledPlugins
			plugins: plugins
			settings: settings

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
					if setting.type == 'number'
						req.body[settingName] = parseFloat req.body[settingName]
						if isNaN(req.body[settingName])
							req.body[settingName] = ''
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