cli = require 'cli-color'

chatActivity = {}
lastMessage = {}

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	liveChannel = new Mikuia.Models.Channel to
	await liveChannel.isLive defer err, live

	if live
		Channel = new Mikuia.Models.Channel user.username
		await Channel.isBanned defer err, isBanned

		if !isBanned
			gibePoints = user.username not of lastMessage or new Date().getTime() / 1000 > lastMessage[user.username] + 60

			chatActivity[user.username] ?= {}
			chatActivity[user.username][liveChannel.getName()] = 10

			if gibePoints and user.username isnt to.replace '#', ''
				await Channel.addExperience to.replace('#', ''), Math.round(Math.random() * 1), chatActivity[user.username][liveChannel.getName()], defer whatever

				lastMessage[user.username] = new Date().getTime() / 1000

updateLevels = () ->
	await Mikuia.Database.get 'mikuia:lastUpdate', defer err, time
	seconds = (((new Date()).getTime() / 1000) - parseInt(time))
	
	multiplier = Math.round(seconds / 60)
	Mikuia.Log.info cli.yellowBright('Levels') + ' / ' + cli.whiteBright('Updating levels with a ') + cli.yellowBright(multiplier + 'x') + cli.whiteBright(' multiplier... (') + cli.yellowBright(Math.floor(seconds) + 's') + cli.whiteBright(' since last update)')
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
					pointsToAdd = Math.round(Math.random() * 1) + 3
				else if activeChannels == 2
					pointsToAdd = 2
				else if activeChannels == 3
					pointsToAdd = 1

				pointsToAdd *= multiplier

				if pointsToAdd > 20
					pointsToAdd = 20

				for channel in channels
					if pointsToAdd && viewer != channel
						if !chatActivity[viewer]?
							chatActivity[viewer] = {}
							chatActivity[viewer][channel] = 0
						await Channel.addExperience channel, pointsToAdd, chatActivity[viewer][channel], defer whatever
						chatActivity[viewer][channel] -= multiplier

setInterval () =>
	updateLevels()
, 60000
updateLevels()