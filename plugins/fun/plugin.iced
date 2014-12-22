Mikuia.Events.on 'fun.roll', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	await Channel.getDisplayName defer err, displayName

	if data.settings?.limit? && !isNaN data.settings.limit
		limit = data.settings.limit
	else
		limit = 100

	if data.settings?.blockOverride? && !data.settings.blockOverride
		if data.tokens[1]?
			if !isNaN data.tokens[1]
				limit = data.tokens[1]

	roll = Math.floor(Math.random() * limit)
	Mikuia.Chat.say data.to, displayName + ' rolled ' + roll + '.'