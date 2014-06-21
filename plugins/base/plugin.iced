Mikuia.Events.on 'twitch.message', (from, to, message) =>
	if message == '!lukanya'
		Mikuia.Chat.say to, @Plugin.getSetting 'aboutMessage'