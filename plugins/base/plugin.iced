Mikuia.Events.on 'base.dummy', (data) =>
	sendMessage = true

	if data.settings.onlyMods
		if !checkMod data.to, data.user.username
			sendMessage = false

	if data.settings.onlySubs
		if 'subscriber' not in data.user.special
			sendMessage = false

	if sendMessage
		Mikuia.Chat.say data.to, data.settings.message

Mikuia.Events.on 'base.levels', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	await Channel.getExperience data.to.replace('#', ''), defer err, experience
	await Mikuia.Database.zrevrank 'levels:' + data.to.replace('#', '') + ':experience', data.user.username, defer err, rank

	level = Mikuia.Tools.getLevel experience
	Mikuia.Chat.say data.to, data.user.username + ': #' + (rank + 1) + ' - Lv ' + level + ' (' + experience + ' / ' + Mikuia.Tools.getExperience(level + 1) + ' XP)'

Mikuia.Events.on 'twitch.message', (from, to, message) =>
	globalCommand = @Plugin.getSetting 'globalCommand'
	if message.indexOf(globalCommand) == 0
		if message.trim() == globalCommand
			Mikuia.Chat.say to, 'Hey, I\'m Mikuia, and I\'m a bot made by Maxorq / Hatsuney! Learn more about me at http://mikuia.tv'
		else
			tokens = message.trim().split ' '
			trigger = tokens[1]

			Channel = new Mikuia.Models.Channel to
			isMod = checkMod to, from.username
			switch trigger
				when 'dummy'
					if isMod
						if tokens.length == 2 || tokens.length == 3
							Mikuia.Chat.say to, 'Usage: ' + globalCommand + ' dummy [command] [text]'
						else if tokens.length > 3
							command = tokens[2]
							text = tokens.slice(3, tokens.length).join ' '

							await
								Channel.addCommand command, 'base.dummy', defer err, data
								Channel.setCommandSetting command, 'message', text, defer err2, data
							if !err & !err2
								Mikuia.Chat.say to, 'Command "' + command + '" probably added.'
							else
								Mikuia.Chat.say to, 'Um, something failed. Oops.'
				when 'levels'
					Mikuia.Chat.say to, 'Levels for this channel: http://mikuia.tv/levels/' + Channel.getName()
				when 'mods'
					if isMod
						moderators = Mikuia.Chat.mods to
						if moderators?
							Mikuia.Chat.say to, 'This is what I know:' + JSON.stringify(moderators)
				when 'remove'
					if isMod
						if tokens.length == 2 || tokens.length > 3
							Mikuia.Chat.say to, 'Usage: ' + globalCommand + ' remove [command]'
						else if tokens.length == 3
							command = tokens[2]
							await Channel.removeCommand command, defer err, data
							if !err
								Mikuia.Chat.say to, 'Command "' + command + '" probably removed.'
							else
								Mikuia.Chat.say to, 'I probably screwed something up... oh well.'
				else
					# do nothing

checkMod = (channel, username) ->
	moderators = Mikuia.Chat.mods channel
	if moderators? && username in moderators
		return true
	else
		return false