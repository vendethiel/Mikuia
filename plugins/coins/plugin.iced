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

			await
				Channel.isPluginEnabled 'coins', defer error, isEnabled
				Channel.isSupporter defer error, isSupporter

			if isEnabled and isSupporter

				await
					Channel.getSetting 'coins', 'dropAnnounce', defer error, dropAnnounce
					Channel.getSetting 'coins', 'dropChance', defer error, dropChance
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

					luckers = []
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
							if Math.round(Math.random() * 100) < dropChance
								await
									Mikuia.Database.zincrby 'channel:' + stream + ':coins', coinAmount, viewer, defer whatever
									Viewer.getDisplayName defer error, displayName
								luckers.push displayName

					if luckers.length > 0 and dropAnnounce
						Mikuia.Chat.sayUnfiltered stream, '.me > Dropping coins for: ' + luckers.join(', ') + '!'

					dropTimer[stream] = 0

	for viewerName, viewer of chatActivity
		for streamName, idleTime of viewer
			if chatActivity[viewerName][streamName] > 0
				chatActivity[viewerName][streamName]-- 

setInterval updateCoins, 60000

showBalance = (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.isSupporter defer error, isSupporter
		Mikuia.Database.zscore 'channel:' + data.to.replace('#', '') + ':coins', data.user.username, defer error, coinBalance
		
	if !error and isSupporter
		Channel = new Mikuia.Models.Channel data.to
		Viewer = new Mikuia.Models.Channel data.user.username

		if !coinBalance?
			coinBalance = 0

		await
			Viewer.getDisplayName defer err, displayName
			Channel.getSetting 'coins', 'name', defer error, name
			Channel.getSetting 'coins', 'namePlural', defer error, namePlural

		if parseInt(coinBalance) == 1
			Mikuia.Chat.say data.to, displayName + ': ' + coinBalance + ' ' + name + '.'
		else
			Mikuia.Chat.say data.to, displayName + ': ' + coinBalance + ' ' + namePlural + '.'

Mikuia.Events.on 'coins.balance', (data) =>
	showBalance data

Mikuia.Events.on 'coins.command', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await Channel.isSupporter defer error, isSupporter
	if isSupporter and data.tokens.length > 1
		trigger = data.tokens[1]

		switch trigger
			when 'add', 'remove', 'set', 'take'
				if data.tokens.length == 4 && data.user.username == data.to.replace('#', '')
					username = data.tokens[2]
					coinAmount = data.tokens[3]
					
					Channel = new Mikuia.Models.Channel data.to
					Viewer = new Mikuia.Models.Channel username

					await
						Channel.getSetting 'coins', 'name', defer error, name
						Channel.getSetting 'coins', 'namePlural', defer error, namePlural
						Viewer.getDisplayName defer error, displayName

					if trigger is 'add'
						await Mikuia.Database.zincrby 'channel:' + Channel.getName() + ':coins', coinAmount, Viewer.getName(), defer whatever

						if parseInt(coinAmount) == 1
							Mikuia.Chat.say data.to, 'Gave 1 ' + name + ' to ' + displayName + '.'
						else
							Mikuia.Chat.say data.to, 'Gave ' + coinAmount + ' ' + namePlural + ' to ' + displayName + '.'
					else if trigger is 'remove' or trigger is 'take'
						await Mikuia.Database.zincrby 'channel:' + Channel.getName() + ':coins', coinAmount * -1, Viewer.getName(), defer whatever

						if parseInt(coinAmount) == 1
							Mikuia.Chat.say data.to, 'Took 1 ' + name + ' from ' + displayName + '.'
						else
							Mikuia.Chat.say data.to, 'Took ' + coinAmount + ' ' + namePlural + ' from ' + displayName + '.'
					else if trigger is 'set'
						await Mikuia.Database.zadd 'channel:' + Channel.getName() + ':coins', coinAmount, Viewer.getName(), defer whatever

						if parseInt(coinAmount) == 1
							Mikuia.Chat.say data.to, displayName + ' now has 1 ' + name + '.'
						else
							Mikuia.Chat.say data.to, displayName + ' now has ' + coinAmount + ' ' + namePlural + '.'

			when 'give', 'pay'
				if data.tokens.length == 4
					username = data.tokens[2]
					coinAmount = parseInt data.tokens[3]

					if coinAmount > 0
						Channel = new Mikuia.Models.Channel data.to
						Recipient = new Mikuia.Models.Channel username
						Sender = new Mikuia.Models.Channel data.user.username
						
						await
							Channel.getSetting 'coins', 'name', defer error, name
							Channel.getSetting 'coins', 'namePlural', defer error, namePlural
							Sender.getDisplayName defer error, senderDisplayName
							Recipient.getDisplayName defer error, recipientDisplayName
							Mikuia.Database.zscore 'channel:' + Channel.getName() + ':coins', Sender.getName(), defer whatever, senderCoins

						if senderCoins >= coinAmount
							await
								Mikuia.Database.zincrby 'channel:' + Channel.getName() + ':coins', coinAmount * -1, Sender.getName(), defer whatever
								Mikuia.Database.zincrby 'channel:' + Channel.getName() + ':coins', coinAmount, Recipient.getName(), defer whatever

							if coinAmount == 1
								Mikuia.Chat.say data.to, senderDisplayName + ' -> ' + recipientDisplayName + ' (' + coinAmount + ' ' + name + ')'
							else
								Mikuia.Chat.say data.to, senderDisplayName + ' -> ' + recipientDisplayName + ' (' + coinAmount + ' ' + namePlural + ')'

			when 'help'
				Mikuia.Chat.say data.to, 'There\'s no help for you! :D'

	else
		showBalance data
