lol = require 'lol-js'

masteryStaticData = require './data/mastery.json'
runeStaticData = require './data/rune.json'

client = lol.client
	apiKey: Mikuia.settings.plugins.lol.apiKey
	defaultRegion: 'euw'

masteryCategories = {}
for treeName, treeCategories of masteryStaticData.tree
	for treeCategory in treeCategories
		for treeMastery in treeCategory
			if treeMastery?
				masteryCategories[treeMastery.masteryId] = treeName

console.log masteryCategories

Mikuia.Events.on 'lol.masteries.active.summary', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getSetting 'lol', 'region', defer err, region
		Channel.getSetting 'lol', 'name', defer err, name

	client.getSummonersByName [name],
		region: region
	, (err, summonerData) =>
		if not err and summonerData?[name]?.id?
			client.getSummonerMasteries summonerData[name].id, (err, masteryData) =>
				if not err and masteryData?[summonerData[name].id]?
					for masteryPage in masteryData[summonerData[name].id].pages
						if masteryPage.current

							points =
								Offense: 0
								Defense: 0
								Utility: 0

							for mastery in masteryPage.masteries
								points[masteryCategories[mastery.id]] += mastery.rank

							Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse data.settings.format,
								pageName: masteryPage.name
								offensePoints: points.Offense
								defensePoints: points.Defense
								utilityPoints: points.Utility

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