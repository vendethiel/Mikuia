challenges = {}
leaderboard = new Mikuia.Models.Leaderboard '1v1rating'
leaderboard.setDisplayName '1v1 Rating'
leaderboard.setDisplayHtml '<i class="fa fa-star" style="color: orange;"></i> <%value%>'

Mikuia.Events.on 'fun.1v1', (data) =>
	if data.tokens.length >= 2
		Channel = new Mikuia.Models.Channel data.to
		Attacker = new Mikuia.Models.Channel data.user.username
		Defender = new Mikuia.Models.Channel data.tokens[1]

		await Attacker.isBot defer err, isBot

		if Attacker.getName() == Defender.getName()
			return

		if isBot
			return

		chatters = Mikuia.Chat.getChatters data.to.replace('#', '')
		for categoryName, category of chatters
			if category.indexOf(Defender.getName()) > -1
				if challenges[Channel.getName()]?[Defender.getName()]?[Attacker.getName()]?
					delete challenges[Channel.getName()][Defender.getName()][Attacker.getName()]

					await
						Attacker.getDisplayName defer whatever, attackerDisplayName
						Defender.getDisplayName defer whatever, defenderDisplayName
						Attacker.getTotalLevel defer whatever, attackerTotalLevel
						Defender.getTotalLevel defer whatever, defenderTotalLevel
						Attacker.getLevel Channel.getName(), defer whatever, attackerLevel
						Defender.getLevel Channel.getName(), defer whatever, defenderLevel
						Mikuia.Leagues.addFight Attacker.getName(), defer whatever
						Mikuia.Leagues.addFight Defender.getName(), defer whatever
						Mikuia.Leagues.getFightCount Attacker.getName(), defer whatever, attackerFightCount
						Mikuia.Leagues.getFightCount Defender.getName(), defer whatever, defenderFightCount
						Mikuia.Leagues.getRating Attacker.getName(), defer whatever, attackerRating
						Mikuia.Leagues.getRating Defender.getName(), defer whatever, defenderRating

					attackerRating = parseInt attackerRating
					defenderRating = parseInt defenderRating
					oldAttackerRating = attackerRating
					oldDefenderRating = defenderRating


					# Streamers automatically get Level 100 on their own channels... bit OP.
					# Maybe the total level should be copied here?
					# Maybe the highest level on their channel achieved by someone?
					# No idea.

					if Attacker.getName() == Channel.getName()
						attackerLevel = 100

					if Defender.getName() == Channel.getName()
						defenderLevel = 100

					attackerFightLevel = Math.round(parseInt(attackerTotalLevel) + Math.pow(attackerLevel, 1.5))
					defenderFightLevel = Math.round(parseInt(defenderTotalLevel) + Math.pow(defenderLevel, 1.5))

					# Let's avoid problems with zeros, lol
					attackerFightLevel = Math.max 1, attackerFightLevel
					defenderFightLevel = Math.max 1, defenderFightLevel

					# Calculating chances based on fight levels! o-o
					attackerChance = attackerFightLevel / (attackerFightLevel + defenderFightLevel)
					defenderChance = defenderFightLevel / (attackerFightLevel + defenderFightLevel)
					attackerChancePercent = Math.round(attackerChance * 10000) / 100

					# Calculating chances based on ELO (only for rating purposes)
					attackerEloChance = 1 / (1 + Math.pow(10, (defenderRating - attackerRating) / 400))
					defenderEloChance = 1 / (1 + Math.pow(10, (attackerRating - defenderRating) / 400))

					random = Math.random()
					attackerWin = null

					if random < attackerChance
						attackerWin = true
					else
						attackerWin = false

					chatMessage = null
					kFactor = 50

					if attackerWin
						chatMessage += ' and WON!'

						if attackerRating > 2400
							kFactor = 24
						else if attackerRating > 2100
							kFactor = 32

						eloChange = Math.floor(((kFactor * (1 - attackerChance)) + (kFactor * (1 - attackerEloChance))) / 2)
						attackerRating += eloChange
						defenderRating -= eloChange

						chatMessage = attackerDisplayName + ' <' + attackerChancePercent + '%> WON (' + attackerRating + ')[+' + eloChange + '] with ' + defenderDisplayName + ' (' + defenderRating + ')[-' + eloChange + ']'

						await
							Mikuia.Leagues.addFightWin Attacker.getName(), defer err
							Mikuia.Leagues.addFightLoss Defender.getName(), defer err
					
					else
						chatMessage += ' and LOST.'

						if defenderRating > 2400
							kFactor = 16
						else if defenderRating > 2100
							kFactor = 24

						eloChange = Math.floor(((kFactor * (1 - defenderChance)) + (kFactor * (1 - defenderEloChance))) / 2)
						attackerRating -= eloChange
						defenderRating += eloChange

						chatMessage = attackerDisplayName + ' <' + attackerChancePercent + '%> lost (' + attackerRating + ')[-' + eloChange + '] with ' + defenderDisplayName + ' (' + defenderRating + ')[+' + eloChange + ']'

						await
							Mikuia.Leagues.addFightWin Defender.getName(), defer err
							Mikuia.Leagues.addFightLoss Attacker.getName(), defer err
				
					Mikuia.Chat.say data.to, chatMessage

					await
						Mikuia.Leagues.updateRating Attacker.getName(), attackerRating, defer err
						Mikuia.Leagues.updateRating Defender.getName(), defenderRating, defer err

					if attackerFightCount == 10
						Mikuia.Chat.sayUnfiltered data.to, '.me > ' + attackerDisplayName + ' has been placed in ' + Mikuia.Leagues.getLeagueFullText(attackerRating) + '!'

					if attackerFightCount > 10
						if Mikuia.Leagues.getLeague(oldAttackerRating) > Mikuia.Leagues.getLeague(attackerRating)
							Mikuia.Chat.sayUnfiltered data.to, '.me > ' + attackerDisplayName + ' fell down to ' + Mikuia.Leagues.getLeagueText(attackerRating) + '!'
						else if Mikuia.Leagues.getLeague(attackerRating) > Mikuia.Leagues.getLeague(oldAttackerRating)
							Mikuia.Chat.sayUnfiltered data.to, '.me > ' + attackerDisplayName + ' has advanced to ' + Mikuia.Leagues.getLeagueText(attackerRating) + '!'

					if defenderFightCount == 10
						Mikuia.Chat.sayUnfiltered data.to, '.me > ' + defenderDisplayName + ' has been placed in ' + Mikuia.Leagues.getLeagueFullText(defenderRating) + '!'
					
					if defenderFightCount > 10
						if Mikuia.Leagues.getLeague(oldDefenderRating) > Mikuia.Leagues.getLeague(defenderRating)
							Mikuia.Chat.sayUnfiltered data.to, '.me > ' + defenderDisplayName + ' fell down to ' + Mikuia.Leagues.getLeagueText(defenderRating) + '!'
						else if Mikuia.Leagues.getLeague(defenderRating) > Mikuia.Leagues.getLeague(oldDefenderRating)
							Mikuia.Chat.sayUnfiltered data.to, '.me > ' + defenderDisplayName + ' has advanced to ' + Mikuia.Leagues.getLeagueText(defenderRating) + '!'

					if parseInt(data.settings.timeoutLength) > 0
						if attackerWin
							timeoutName = Defender.getName()
						else
							timeoutName = Attacker.getName()

						Mikuia.Chat.sayUnfiltered data.to, '.timeout ' + timeoutName + ' ' + data.settings.timeoutLength

				else
					challenges[Channel.getName()] ?= {}
					challenges[Channel.getName()][Attacker.getName()] ?= {}
					challenges[Channel.getName()][Attacker.getName()][Defender.getName()] = true

Mikuia.Events.on 'fun.roll', (data) =>
	Channel = new Mikuia.Models.Channel data.user.username
	await Channel.getDisplayName defer err, displayName

	if data.settings?.limit? && !isNaN data.settings.limit
		limit = data.settings.limit
	else
		limit = 100

	if data.settings?.blockOverride? && !data.settings.blockOverride
		if data.tokens[1]?
			if !isNaN data.tokens[1]
				limit = data.tokens[1]

	roll = Math.floor(Math.random() * limit)
	Mikuia.Chat.say data.to, displayName + ' rolled ' + roll + '.'