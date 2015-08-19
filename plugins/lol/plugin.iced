lol = require 'lol-js'
runeStaticData = require './data/rune.json'

client = lol.client
	apiKey: Mikuia.settings.plugins.lol.apiKey
	defaultRegion: 'euw'

Mikuia.Events.on 'lol.runes.active.list', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getSetting 'lol', 'region', defer err, region
		Channel.getSetting 'lol', 'name', defer err, name

	client.getSummonersByName [name],
		region: region
	, (err, summonerData) =>
		if not err and summonerData?[name]?.id?
			client.getSummonerRunes summonerData[name].id, (err, runeData) =>
				if not err and runeData?[summonerData[name].id]?
					for runePage in runeData[summonerData[name].id].pages
						if runePage.current
							runeList = {}
							for rune in runePage.slots
								if !runeList[rune.runeId]?
									runeList[rune.runeId] = 0
								runeList[rune.runeId]++

							runeCounts = []
							for runeId, runeCount of runeList
								runeCounts.push runeCount + 'x ' + runeStaticData.data[runeId].name

							Mikuia.Chat.say Channel.getName(), runeCounts.join ', '