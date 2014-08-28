cli = require 'cli-color'

lastMessage = {}

Mikuia.Events.on 'twitch.message', (user, to, message) =>

	liveChannel = new Mikuia.Models.Channel to
	await liveChannel.isLive defer err, live

	if live
		gibePoints = false

		if user.username not in Object.keys(lastMessage)
			gibePoints = true
		else
			if (new Date()).getTime() / 1000 > lastMessage[user.username] + 20
				gibePoints = true

		if gibePoints && user.username != to.replace('#', '')
			Channel = new Mikuia.Models.Channel user.username
			await Channel.addExperience to.replace('#', ''), 1, defer whatever

			lastMessage[user.username] = (new Date()).getTime() / 1000

Mikuia.Events.on 'twitch.updated', =>
	await Mikuia.Database.get 'mikuia:lastUpdate', defer err, time
	if !err && parseInt((new Date()).getTime() / 1000) > parseInt(time) + 240
		await Mikuia.Database.set 'mikuia:lastUpdate', parseInt((new Date()).getTime() / 1000), defer err2, response
		
		viewers = {}
		await Mikuia.Streams.getAll defer err, streams
		if !err && streams?
			for stream in streams
				@Plugin.Log.info 'Gathering viewers of ' + cli.yellowBright(stream) + '...'

				chatters = Mikuia.Chat.getChatters stream

				for categoryName, category of chatters
					for chatter in category
						if !viewers[chatter]?
							viewers[chatter] = []
						viewers[chatter].push stream

			for viewer, channels of viewers
				@Plugin.Log.info viewer + ' - ' + channels
				Channel = new Mikuia.Models.Channel viewer
				pointsToAdd = 0

				if channels.length == 1
					pointsToAdd = 20
				else if channels.length == 2
					pointsToAdd = 10
				else if channels.length == 3
					pointsToAdd = 5

				for channel in channels
					if pointsToAdd && viewer != channel
						await Channel.addExperience channel, pointsToAdd, defer whatever