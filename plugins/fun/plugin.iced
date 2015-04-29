challenges = {}

Mikuia.Events.on 'fun.1v1', (data) =>
	if data.tokens.length >= 2
		Channel = new Mikuia.Models.Channel data.to
		Attacker = new Mikuia.Models.Channel data.user.username
		Defender = new Mikuia.Models.Channel data.tokens[1]

		chatters = Mikuia.Chat.getChatters data.to.replace('#', '')
		for categoryName, category of chatters
			if category.indexOf(Defender.getName()) > -1
				if challenges[Defender.getName()]?[Attacker.getName()]?
					delete challenges[Defender.getName()][Attacker.getName()]

					await
						Attacker.getTotalLevel defer whatever, attackerTotalLevel
						Defender.getTotalLevel defer whatever, defenderTotalLevel
						Attacker.getLevel Channel.getName(), defer whatever, attackerLevel
						Defender.getLevel Channel.getName(), defer whatever, defenderLevel

					if Attacker.getName() == Channel.getName()
						attackerLevel = 100

					if Defender.getName() == Channel.getName()
						defenderLevel = 100

					attackerFightLevel = attackerTotalLevel + attackerLevel ^ 1.5
					defenderFightLevel = defenderTotalLevel + defenderLevel ^ 1.5

					if attackerFightLevel == 0
						attackerFightLevel = 1

					if defenderFightLevel == 0
						defenderFightLevel = 1

					attackerChance = attackerFightLevel / (attackerFightLevel + defenderFightLevel)
					attackerChancePercent = Math.round(attackerChance * 10000) / 100

					random = Math.random()
					attackerWin = null

					if random < attackerChance
						attackerWin = true
					else
						attackerWin = false

					chatMessage = Attacker.getName() + ' (' + attackerTotalLevel + '/' + attackerLevel + '[' + attackerFightLevel + '] - ' + attackerChancePercent + '%) 1v1\'d ' + Defender.getName() + ' (' + defenderTotalLevel + '/' + defenderLevel + '[' + defenderFightLevel + '])' 

					if attackerWin
						chatMessage += ' and WON!'
					else
						chatMessage += ' and LOST.'
					
					Mikuia.Chat.say data.to, chatMessage

					if parseInt(data.settings.timeoutLength) > 0
						if attackerWin
							timeoutName = Defender.getName()
						else
							timeoutName = Attacker.getName()

						Mikuia.Chat.sayUnfiltered data.to, '.timeout ' + timeoutName + ' ' + data.settings.timeoutLength

				else
					challenges[Attacker.getName()] ?= {}
					challenges[Attacker.getName()][Defender.getName()] = true

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