Mikuia.Events.on 'twitch.message', (from, to, message) =>
	if message == '!lukanya'
		Channel = new Mikuia.Models.Channel to
		await Channel.getSetting 'base', 'customMessage', defer err, data
		if !err
			Mikuia.Chat.say to, data

Mikuia.Events.on 'base.dummy', (data) =>
	console.log data
	Mikuia.Chat.say data.to, data.settings.message