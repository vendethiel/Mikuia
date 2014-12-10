module.exports =
	commands: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		handlers = Mikuia.Plugin.getHandlers()

		await
			Channel.getCommands defer err, commandHandlers
			Channel.getEnabledPlugins defer err, enabledPlugins

		commands = {}
		if commandHandlers?
			for command, handler of commandHandlers
				commands[command] =
					handler: handler,
					description: handlers[handler].description

		res.render 'commands',
			commands: commands
			enabledPlugins: enabledPlugins
			handlers: handlers

	add: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.command? && data.handler? && Mikuia.Plugin.handlerExists data.handler
			# To do: maybe some validation, I dunno.
			commandName = data.command.split(' ').join('')

			await Channel.addCommand commandName, data.handler, defer err, data
			res.redirect '/dashboard/commands/settings/' + commandName
		else
			res.redirect '/dashboard/commands'

	remove: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.command?
			await Channel.removeCommand data.command, defer err, data

		res.send 200

	save: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.getCommand req.params.name, defer err, data
		if !err && data?
			if Mikuia.Plugin.getHandler(data).settings?
				settings = Mikuia.Plugin.getHandler(data).settings
			else
				settings = {}
			settings._onlyMods =
				type: 'boolean'
			settings._onlySubs =
				type: 'boolean'
			settings._minLevel =
				type: 'number'
			for settingName, setting of settings
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
					await Channel.setCommandSetting req.params.name, settingName, req.body[settingName], defer err, data

		res.redirect '/dashboard/commands'

	settings: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		
		settings = null
		userSettings = null
		if req.params.name?
			await Channel.getCommand req.params.name, defer err, data
			if !err && data? && Mikuia.Plugin.handlerExists data
				if Mikuia.Plugin.getHandler(data).settings?
					settings = Mikuia.Plugin.getHandler(data).settings
				await Channel.getCommandSettings req.params.name, false, defer err, data
				if !err && data?
					userSettings = data

			res.render 'command',
				command: req.params.name
				settings: settings
				userSettings: userSettings