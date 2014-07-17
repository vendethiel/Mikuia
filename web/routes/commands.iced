module.exports =
	commands: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		handlers = Mikuia.Plugin.getHandlers()

		await Channel.getCommands defer err, commandHandlers
		if err then console.log err

		commands = {}
		if commandHandlers?
			for command, handler of commandHandlers
				commands[command] =
					handler: handler,
					description: handlers[handler].description

		res.render 'commands',
			commands: commands
			handlers: handlers

	add: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.command? && data.handler? && Mikuia.Plugin.handlerExists data.handler
			# To do: maybe some validation, I dunno.
			data.command = data.command.replace(' ', '')
			await Channel.addCommand data.command, data.handler, defer err, data

		res.redirect '/dashboard/commands'