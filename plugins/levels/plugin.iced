cli = require 'cli-color'

chatActivity = {}
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

		if !chatActivity[user.username]?
			chatActivity[user.username] = {}
			
		chatActivity[user.username][liveChannel.getName()] = 20

		if gibePoints && user.username != to.replace('#', '')
			Channel = new Mikuia.Models.Channel user.username
			await Channel.addExperience to.replace('#', ''), Math.floor(Math.random() * 4), chatActivity[user.username][liveChannel.getName()], defer whatever

			lastMessage[user.username] = (new Date()).getTime() / 1000

Mikuia.Events.on 'twitch.updated', =>
	await Mikuia.Database.get 'mikuia:lastUpdate', defer err, time
	seconds = (((new Date()).getTime() / 1000) - parseInt(time))
	
	multiplier = Math.round(seconds / 60)
	@Plugin.Log.info seconds + ' seconds since last update! (' + multiplier + 'x)'
	if !err
		await Mikuia.Database.set 'mikuia:lastUpdate', parseInt((new Date()).getTime() / 1000), defer err2, response
		
		viewers = {}
		await Mikuia.Streams.getAll defer err, streams
		if !err && streams?
			for stream in streams
				chatters = Mikuia.Chat.getChatters stream

				for categoryName, category of chatters
					for chatter in category
						if !viewers[chatter]?
							viewers[chatter] = []
						viewers[chatter].push stream

			for viewer, channels of viewers
				Channel = new Mikuia.Models.Channel viewer
				pointsToAdd = 0

				activeChannels = 0
				if chatActivity[viewer]?
					for activityChannel, activityValue of chatActivity[viewer]
						if activityValue > 0 && activityChannel in streams
							activeChannels++

				if activeChannels == 1
					pointsToAdd = 4
				else if activeChannels == 2
					pointsToAdd = 2
				else if activeChannels == 3
					pointsToAdd = 1

				pointsToAdd *= multiplier

				for channel in channels
					if pointsToAdd && viewer != channel
						if !chatActivity[viewer]?
							chatActivity[viewer] = {}
							chatActivity[viewer][channel] = 0
						await Channel.addExperience channel, pointsToAdd, chatActivity[viewer][channel], defer whatever
						chatActivity[viewer][channel] -= multiplier