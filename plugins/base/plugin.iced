Mikuia.Events.on 'message', (from, to, message) ->
	if message == '!lukanya'
		Mikuia.Chat.say to, 'Hi, I\'m Lukanya, and I don\'t do anything useful! Leave me alone.'