Mikuia.Events.on 'twitch.message', (from, to, message) =>
	if message.indexOf('!lukanya') == 0
			Mikuia.Chat.say to, 'Hey, I\'m Lukanya, and I don\'t do too much at the moment... just leave me alone.'

Mikuia.Events.on 'base.dummy', (data) =>
	Mikuia.Chat.say data.to, data.settings.message