addDummy = (username, channel, tokens) =>
	Channel = new Mikuia.Models.Channel channel
	isMod = checkMod channel, username

	if isMod
		if tokens.length == 1 || tokens.length == 2
			Mikuia.Chat.say channel, 'You failed D:'
		else if tokens.length > 2
			command = tokens[1]
			text = tokens.slice(2, tokens.length).join ' '

			await
				Channel.addCommand command, 'base.dummy', defer err, data
				Channel.setCommandSetting command, 'message', text, defer err2, data
			if !err & !err2
				Mikuia.Chat.say channel, 'Command "' + command + '" probably added.'
			else
				Mikuia.Chat.say channel, 'Um, something failed. Oops.'

removeCommand = (username, channel, tokens) =>
	Channel = new Mikuia.Models.Channel channel
	isMod = checkMod channel, username

	if isMod
		if tokens.length == 1 || tokens.length > 2
			Mikuia.Chat.say channel, 'Fail.'
		else if tokens.length == 2
			command = tokens[1]
			await Channel.removeCommand command, defer err, data
			if !err
				Mikuia.Chat.say channel, 'Command "' + command + '" probably removed.'
			else
				Mikuia.Chat.say channel, 'I probably screwed something up... oh well.'

Mikuia.Events.on 'base.add.dummy', (data) =>
	addDummy data.user.username, data.to, data.tokens

Mikuia.Events.on 'base.dummy', (data) =>
	Mikuia.Chat.say data.to, data.settings.message

Mikuia.Events.on 'base.levels', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	if Channel.getName() != data.to
		await
			Channel.getDisplayName defer err, displayName
			Channel.getExperience data.to.replace('#', ''), defer err2, experience
			Mikuia.Database.zrevrank 'levels:' + data.to.replace('#', '') + ':experience', data.user.username, defer err3, rank

		level = Mikuia.Tools.getLevel experience
		Mikuia.Chat.say data.to, displayName + ': #' + (rank + 1) + ' - Lv ' + level + ' (' + experience + ' / ' + Mikuia.Tools.getExperience(level + 1) + ' XP)'

Mikuia.Events.on 'base.remove', (data) =>
	removeCommand data.user.username, data.to, data.tokens

Mikuia.Events.on 'base.uptime', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await Channel.isLive defer err, isLive

	if isLive
		await Mikuia.Streams.get Channel.getName(), defer err, stream

		startTime = (new Date(stream.created_at)).getTime() / 1000
		endTime = Math.floor((new Date()).getTime() / 1000)

		totalTime = endTime - startTime

		seconds = totalTime % 60
		minutes = ((totalTime - seconds) / 60) % 60
		hours = ((totalTime - seconds) - (60 * minutes)) / 3600

		if minutes < 10
			minutes = '0' + minutes

		if seconds < 10
			seconds = '0' + seconds

		Mikuia.Chat.say data.to, 'Uptime: ' + hours + 'h ' + minutes + 'm ' + seconds + 's'
	else
		Mikuia.Chat.say data.to, 'The stream is not live.'		

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
					addDummy from.username, to, tokens.slice 1
				when 'levels'
					Mikuia.Chat.say to, 'Levels for this channel: http://mikuia.tv/levels/' + Channel.getName()
				when 'mods'
					if isMod
						moderators = Mikuia.Chat.mods to
						if moderators?
							Mikuia.Chat.say to, 'This is what I know:' + JSON.stringify(moderators)
				when 'remove'
					removeCommand from.username, to, tokens.slice 1
				else
					# do nothing

checkMod = (channel, username) ->
	if channel == username
		return true
	else
		moderators = Mikuia.Chat.mods channel
		if moderators? && username in moderators
			return true
		else
			return false