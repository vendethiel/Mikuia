Mikuia.Events.on 'fun.roll', (data) =>
	if data.settings?.limit? && !isNaN data.settings.limit
		limit = data.settings.limit
	else
		limit = 100

	if data.settings?.blockOverride? && !data.settings.blockOverride
		if data.tokens[1]?
			if !isNaN data.tokens[1]
				limit = data.tokens[1]

	roll = Math.floor(Math.random() * limit)
	Mikuia.Chat.say data.to, data.user.username + ' rolled ' + roll + '.'