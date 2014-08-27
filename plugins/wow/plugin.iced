request = require 'request'

bracketNames =
	'ARENA_BRACKET_2v2': '2v2'
	'ARENA_BRACKET_3v3': '3v3'
	'ARENA_BRACKET_5v5': '5v5'
	'ARENA_BRACKET_RBG': 'rbg'
regionEndpoints =
	'us': 'us.battle.net'
	'eu': 'eu.battle.net'
	'kr': 'kr.battle.net'
	'tw': 'tw.battle.net'
	'cn': 'www.battlenet.com.cn'

userData = {}

getData = (region, realm, name, callback) =>
	request 'http://' + regionEndpoints[region] + '/api/wow/character/' + realm + '/' + name + '?fields=pvp,stats', (error, response, body) ->
		if !error && response.statusCode == 200
			jsonData = {}
			try
				jsonData = JSON.parse body
			catch e
				console.log e

			callback false, jsonData
		else
			callback true, null

checkRankUpdates = (stream, callback) =>
	await Mikuia.Database.hget 'mikuia:stream:' + stream, 'game', defer err, game
	if err || game? || game.indexOf('World of Warcraft') == -1
		callback err, null
	else
		Channel = new Mikuia.Models.Channel stream
		await Channel.isPluginEnabled 'wow', defer err, enabled

		if !err && enabled
			await
				Channel.getSetting 'wow', 'region', defer err, region
				Channel.getSetting 'wow', 'realm', defer err2, realm
				Channel.getSetting 'wow', 'name', defer err3, name
				Channel.getSetting 'wow', 'updates', defer err4, updates

			if !err4 && updates
				await getData region, realm, name, defer err, data
				console.log data.pvp.brackets.ARENA_BRACKET_3v3.rating

Mikuia.Events.on 'wow.character', (data) =>
	Channel = new Mikuia.Models.Channel data.to
	await Channel.isPluginEnabled 'wow', defer err, enabled

	if !err && enabled
		await
			Channel.getSetting 'wow', 'region', defer err, region
			Channel.getSetting 'wow', 'realm', defer err2, realm
			Channel.getSetting 'wow', 'name', defer err3, name

		if region in Object.keys(regionEndpoints) and name?
			await getData region, realm, name, defer err, jsonData
			if !err && jsonData?
				formatData = {}

				for bracketName, bracket of jsonData.pvp.brackets
					for name, value of bracket
						formatData['pvp.' + bracketNames[bracketName] + '.' + name] = value

				Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse data.settings.format, formatData

# setInterval () =>
# 	await Mikuia.Streams.getAll defer err, streams
# 	if !err && streams?
# 		for stream in streams
# 			await checkRankUpdates stream, defer err, status
# , 15000