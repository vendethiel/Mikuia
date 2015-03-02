cli = require 'cli-color'

chatActivity = {}
dropTimer = {}

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	liveChannel = new Mikuia.Models.Channel to
	await liveChannel.isLive defer err, live

	if live
		await liveChannel.getSetting 'coins', 'idleTime', defer error, idleTime

		chatActivity[user.username] ?= {}
		chatActivity[user.username][liveChannel.getName()] = idleTime

updateCoins = () =>
	Mikuia.Log.info cli.yellowBright('Coins') + ' / ' + cli.whiteBright('Updating coins...')

	await Mikuia.Streams.getAll defer err, streams
	if !err and streams?
		for stream in streams
			Channel = new Mikuia.Models.Channel stream

			viewers = []

			await Channel.isPluginEnabled 'coins', defer error, isEnabled
			if isEnabled

				await
					Channel.getSetting 'coins', 'dropTime', defer error, dropTime
					Channel.getSetting 'coins', 'dropValue', defer error, dropValue
					Channel.getSetting 'coins', 'idleTime', defer error, idleTime
					Channel.getSetting 'coins', 'rewardIdlers', defer error, rewardIdlers

				dropTimer[stream] ?= 0
				dropTimer[stream]++

				if dropTimer[stream] == parseInt dropTime
					chatters = Mikuia.Chat.getChatters stream
					for categoryName, category of chatters
						for chatter in category
							viewers.push chatter

					for viewer in viewers
						Viewer = new Mikuia.Models.Channel viewer
						goAhead = true

						if not rewardIdlers
							if chatActivity[viewer]?[stream]?
								if chatActivity[viewer][stream] == 0
									goAhead = false
							else
								goAhead = false

						await Viewer.isBot defer error, isBot
						if goAhead and not isBot and viewer isnt stream
							coinAmount = dropValue
							console.log viewer + ' gets ' + coinAmount + ' ' + stream + ' coins!'
							await Mikuia.Database.hincrby 'channel:' + stream + ':coins', viewer, coinAmount, defer whatever

					dropTimer[stream] = 0

	for viewerName, viewer of chatActivity
		for streamName, idleTime of viewer
			if chatActivity[viewerName][streamName] > 0
				chatActivity[viewerName][streamName]-- 

setInterval	updateCoins, 60000

# updateLevels = () ->
# 	await Mikuia.Database.get 'mikuia:lastUpdate', defer err, time
# 	seconds = (((new Date()).getTime() / 1000) - parseInt(time))
	
# 	multiplier = Math.round(seconds / 60)
# 	Mikuia.Log.info cli.yellowBright('Levels') + ' / ' + cli.whiteBright('Updating levels with a ') + cli.yellowBright(multiplier + 'x') + cli.whiteBright(' multiplier... (') + cli.yellowBright(Math.floor(seconds) + 's') + cli.whiteBright(' since last update)')
# 	if !err
# 		await Mikuia.Database.set 'mikuia:lastUpdate', parseInt((new Date()).getTime() / 1000), defer err2, response
		
# 		viewers = {}
# 		await Mikuia.Streams.getAll defer err, streams
# 		if !err && streams?
# 			for stream in streams
# 				chatters = Mikuia.Chat.getChatters stream

# 				for categoryName, category of chatters
# 					for chatter in category
# 						if !viewers[chatter]?
# 							viewers[chatter] = []
# 						viewers[chatter].push stream

# 			for viewer, channels of viewers
# 				Channel = new Mikuia.Models.Channel viewer
# 				pointsToAdd = 0

# 				activeChannels = 0
# 				if chatActivity[viewer]?
# 					for activityChannel, activityValue of chatActivity[viewer]
# 						if activityValue > 0 && activityChannel in streams
# 							activeChannels++

# 				if activeChannels == 1
# 					pointsToAdd = Math.round(Math.random() * 1) + 3
# 				else if activeChannels == 2
# 					pointsToAdd = 2
# 				else if activeChannels == 3
# 					pointsToAdd = 1

# 				pointsToAdd *= multiplier

# 				if pointsToAdd > 20
# 					pointsToAdd = 20

# 				for channel in channels
# 					if pointsToAdd && viewer != channel
# 						if !chatActivity[viewer]?
# 							chatActivity[viewer] = {}
# 							chatActivity[viewer][channel] = 0
# 						await Channel.addExperience channel, pointsToAdd, chatActivity[viewer][channel], defer whatever
# 						chatActivity[viewer][channel] -= multiplier

# setInterval () =>
# 	updateLevels()
# , 60000
# updateLevels()