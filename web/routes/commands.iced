fs = require 'fs'
jade = require 'jade'

module.exports =
	commands: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		handlers = Mikuia.Plugin.getHandlers()

		await
			Channel.getCommands defer err, commandHandlers
			Channel.getEnabledPlugins defer err, enabledPlugins
			Channel.getSetting 'coins', 'name', defer err, coinName
			Channel.getSetting 'coins', 'namePlural', defer err, coinNamePlural

		commands = []
		sorting = []

		if commandHandlers?
			for command, handler of commandHandlers
				sorting.push command

		sorting.sort()
		for command in sorting
			description = Mikuia.Plugin.getHandler(commandHandlers[command]).description

			await Channel.getCommandSettings command, true, defer err, settings

			commands.push
				name: command
				description: description
				handler: commandHandlers[command]
				plugin: Mikuia.Plugin.getManifest(Mikuia.Plugin.getHandler(commandHandlers[command]).plugin).name
				settings: settings
				coin:
					coinName: coinName
					coinNamePlural: coinNamePlural

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

			if commandName? and commandName != ''
				await Channel.addCommand commandName, data.handler, defer err, data
				res.redirect '/dashboard/commands/settings/' + commandName
			else
				res.redirect '/dashboard/commands'
		else
			res.redirect '/dashboard/commands'

	remove: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username
		data = req.body

		if data.command?
			await Channel.removeCommand data.command, defer err, data
			res.send
				removed: true
		else
			res.send 500

	save: (req, res) ->
		Channel = new Mikuia.Models.Channel req.user.username

		await Channel.getCommand req.params.name, defer err, data
		if !err && data?
			if Mikuia.Plugin.getHandler(data).settings?
				settings = Mikuia.Plugin.getHandler(data).settings
			else
				settings = {}
			settings._onlyBroadcaster =
				type: 'boolean'
			settings._onlyMods =
				type: 'boolean'
			settings._onlySubs =
				type: 'boolean'
			settings._minLevel =
				type: 'number'
			settings._coinCost =
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
			await Channel.getCommand req.params.name, defer err, handlerName

			if !err && handlerName? && Mikuia.Plugin.handlerExists handlerName
				if Mikuia.Plugin.getHandler(handlerName).settings?
					settings = Mikuia.Plugin.getHandler(handlerName).settings
				await Channel.getCommandSettings req.params.name, false, defer err, commandSettingData
				if !err && commandSettingData?
					userSettings = commandSettingData
			
			guide = null
			await fs.readFile 'plugins/' + Mikuia.Plugin.getHandler(handlerName).plugin + '/guides/' + handlerName + '.jade', defer err, guideFile
			if !err
				guide = jade.render guideFile

			res.render 'command',
				command: req.params.name
				guide: guide
				handlerName: handlerName
				settings: settings
				userSettings: userSettings