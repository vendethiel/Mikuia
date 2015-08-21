lol = require 'lol-js'

championStaticData = require './data/champion.json'
masteryStaticData = require './data/mastery.json'
runeStaticData = require './data/rune.json'

client = lol.client
	apiKey: Mikuia.settings.plugins.lol.apiKey
	defaultRegion: 'euw'
	rateLimit: Mikuia.settings.plugins.lol.rateLimit

championMappings = {}
championNameMappings = {}
championRealNames = {}
leagueNames =
	'BRONZE': 'Bronze'
	'SILVER': 'Silver'
	'GOLD': 'Gold'
	'PLATINUM': 'Platinum'
	'DIAMOND': 'Diamond'
	'MASTER': 'Master'
	'CHALLENGER': 'Challenger'

masteryCategories = {}

for championName, championInfo of championStaticData.data
	championMappings[championInfo.key] = championName
	championNameMappings[championName.toLowerCase()] = championName
	championNameMappings[championInfo.name.toLowerCase()] = championName
	championNameMappings[championInfo.name.split(' ').join('')] = championName
	championRealNames[championName] = championInfo.name

for treeName, treeCategories of masteryStaticData.tree
	for treeCategory in treeCategories
		for treeMastery in treeCategory
			if treeMastery?
				masteryCategories[treeMastery.masteryId] = treeName

Mikuia.Events.on 'lol.league.summary', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getSetting 'lol', 'region', defer err, region
		Channel.getSetting 'lol', 'name', defer err, name

	await client.getSummonersByName [name],
		region: region
	, defer err, summonerData

	if not err and summonerData?[name]?.id?
		await client.getLeaguesBySummoner summonerData[name].id, 
			region: region
		, defer err, leagueData

		if not err and leagueData?[summonerData[name].id]?
			for league in leagueData[summonerData[name].id]
				if league.queue == 'RANKED_SOLO_5x5'
					for player in league.entries
						console.log player
						if parseInt(player.playerOrTeamId) == summonerData[name].id
							Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse data.settings.format,
								division: player.division
								leaguePoints: player.leaguePoints
								losses: player.losses
								tier: leagueNames[league.tier]
								wins: player.wins
								winRatio: (player.wins / (player.wins + player.losses)) * 100 

Mikuia.Events.on 'lol.masteries.active.summary', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getSetting 'lol', 'region', defer err, region
		Channel.getSetting 'lol', 'name', defer err, name

	await client.getSummonersByName [name],
		region: region
	, defer err, summonerData

	if not err and summonerData?[name]?.id?
		await client.getSummonerMasteries summonerData[name].id, 
			region: region
		, defer err, masteryData

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

	await client.getSummonersByName [name],
		region: region
	, defer err, summonerData

	if not err and summonerData?[name]?.id?
		await client.getSummonerRunes summonerData[name].id, 
			region: region
		, defer err, runeData

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

Mikuia.Events.on 'lol.stats.ranked.champion', (data) =>
	Channel = new Mikuia.Models.Channel data.to

	await
		Channel.getSetting 'lol', 'region', defer err, region
		Channel.getSetting 'lol', 'name', defer err, name

	championId = null
	championName = 'Unknown'

	if data.tokens.length > 1
		championName = data.tokens.slice(1, data.tokens.length).join('').toLowerCase()
		if championNameMappings[championName]?
			championId = parseInt championStaticData.data[championNameMappings[championName]].key
			championName = championRealNames[championNameMappings[championName]]

	if !championId
		await client.getSummonersByName [name],
			region: region
		, defer err, summonerData

		if not err and summonerData?[name]?.id?
			await client.getSpectatorGameInfo summonerData[name].id,
				region: region
			, defer err, gameInfo

			if not err and gameInfo?.participants?
				for participant in gameInfo.participants
					if participant.summonerId == summonerData[name].id
						championId = participant.championId
						championName = championRealNames[championMappings[championId]]
			else
				Mikuia.Chat.say Channel.getName(), 'Not currently in-game.'

	if championId
		await client.getSummonersByName [name],
			region: region
		, defer err, summonerData

		if not err and summonerData?[name]?.id?
			await client.getRankedStatsForSummoner summonerData[name].id,
				region: region
			, defer err, stats

			if not err and stats?.champions?
				championFound = false
				for champion in stats.champions
					if champion.id == championId
						championFound = true

						formatData = {}
						for statName, statValue of champion.stats
							formatData[statName] = statValue

						formatData.championName = championName
						formatData.kdRatio = formatData.totalChampionKills / formatData.totalDeathsPerSession
						formatData.kdaRatio = (formatData.totalChampionKills + formatData.totalAssists) / formatData.totalDeathsPerSession
						formatData.winRatio = (formatData.totalSessionsWon / formatData.totalSessionsPlayed) * 100

						Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse(data.settings.format, formatData)

				if !championFound and championId?
					Mikuia.Chat.say Channel.getName(), 'No stats for ' + championName + '.'