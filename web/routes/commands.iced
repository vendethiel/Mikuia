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
			await Channel.addCommand data.command.split(' ').join(''), data.handler, defer err, data

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
		if !err && data? && Mikuia.Plugin.getHandler(data).settings?
			settings = Mikuia.Plugin.getHandler(data).settings
			for setting, value of req.body
				if settings[setting]?
					# To do: stuff
					await Channel.setCommandSetting req.params.name, setting, value, defer err, data

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