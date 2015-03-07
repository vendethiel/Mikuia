request = require 'request'
urlregex = require 'url-regex'

Mikuia.Element.register 'dashboardPagePlugin',
	plugin: 'mod'
	pages:
		'/':
			name: 'Mod Tools'
			icon: 'icon-settings'

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	Channel = new Mikuia.Models.Channel to
	await Channel.isPluginEnabled 'mod', defer err, enabled
	if !err && enabled
		doTimeout = false
		timeoutReason = ''

		# ============
		# Banned Words
		# ============

		await Channel.getSetting 'mod', 'bannedWords', defer err, bannedWordsEnabled

		if bannedWordsEnabled
			await Channel._smembers 'plugin:mod:bannedWords', defer whatever, words
			lowercaseMessage = message.toLowerCase()
			timeout = false

			for word in words
				if lowercaseMessage.length > word.length
					# Match "word..."
					if lowercaseMessage.indexOf(word + ' ') == 0
						timeout = true
					# Match "...word"
					if lowercaseMessage.indexOf(' ' + word) == lowercaseMessage.length - word.length - 1
						timeout = true
					# Match "...word..."
					if lowercaseMessage.indexOf(' ' + word + ' ') > -1
						timeout = true
				# Match "word"
				if lowercaseMessage == word
					timeout = true

			if timeout
				doTimeout = true
				timeoutReason = 'bannedWord'

		# ============
		# Link Banning
		# ============

		await Channel.getSetting 'mod', 'bannedLinks', defer err, bannedLinksEnabled

		if bannedLinksEnabled
			if urlregex().test(message)
				await Channel._smembers 'plugin:mod:whitelistedDomains', defer whatever, domains

				tokens = message.match urlregex()
				domainMatched = false

				domains.push '*.mikuia.tv'

				for domain in domains
					regex = ''

					if domain.indexOf('*.') == 0
						regex = regex + '(http:\/\/|https:\/\/|)(([a-z0-9-]+\.)+|)'
						domain = domain.slice 2, domain.length
					else
						regex = regex + '(http:\/\/|https:\/\/|)'

					domain = domain.split('.').join('\.')
					domain = domain.split('*').join('.*')

					regex = regex + domain

					if regex.charAt(regex.length - 1) != '*'
						regex = regex + '(\/[a-zA-Z0-9-/&?#%]*|)'

						for token in tokens
							token = token.trim()
							expr = new RegExp regex
							results = expr.exec token
							if results && results[0] == results.input
								domainMatched = true

				if !domainMatched
					doTimeout = true
					timeoutReason = 'bannedLink'

		# ===========
		# Punishments
		# ===========

		if doTimeout
			mods = Mikuia.Chat.mods Channel.getName()
			if mods?
				if Mikuia.settings.bot.name.toLowerCase() in mods
					if user.username not in mods

						await
							Channel._get 'plugin:mod:warnings:' + user.username, defer whatever, warnings
							Channel.getSetting 'mod', 'enableMessages', defer whatever, enableMessages
							Channel.getSetting 'mod', 'timeoutCooldown', defer whatever, timeoutCooldown
							Channel.getSetting 'mod', 'timeoutDuration', defer whatever, timeoutDuration
							Channel.getSetting 'mod', 'timeoutMultiplier', defer whatever, timeoutMultiplier
							Channel.getSetting 'mod', 'timeoutWarnings', defer whatever, timeoutWarnings

						timeoutCooldown = parseInt timeoutCooldown
						timeoutDuration = parseInt timeoutDuration
						timeoutMultiplier = parseFloat timeoutMultiplier
						timeoutWarnings = parseInt timeoutWarnings

						isBan = false
						permBan = false
						type = 'warning'

						# Banning
						if warnings? && warnings >= timeoutWarnings || timeoutWarnings == 0
							await Channel.getSetting 'mod', 'banDuration', defer whatever, banDuration
							
							if banDuration == 0
								permBan = true

							isBan = true
							timeoutDuration = banDuration
							type = 'ban'

						if !permBan
							if !warnings
								warnings = 0

							if warnings > 0 && !isBan
								timeoutDuration = timeoutDuration * Math.pow(timeoutMultiplier, warnings)

							Mikuia.Chat.say Channel.getName(), '.timeout ' + user.username + ' ' + timeoutDuration

							await Channel._setex 'plugin:mod:warnings:' + user.username, timeoutCooldown, parseInt(warnings) + 1, defer whatever, whatever2
						else
							Mikuia.Chat.say Channel.getName(), '.ban ' + user.username

						if enableMessages
							await Channel.getSetting 'mod', timeoutReason + 'Message', defer whatever, timeoutMessageFormat
							Mikuia.Chat.say Channel.getName(), Mikuia.Format.parse timeoutMessageFormat,
								username: user.username
								type: type
								duration: timeoutDuration
						 

Mikuia.Web.get '/dashboard/plugins/mod', checkAuth, (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username
	await Channel._smembers 'plugin:mod:bannedWords', defer whatever, words
	await Channel._smembers 'plugin:mod:whitelistedDomains', defer whatever, domains

	res.render '../../plugins/mod/views/index',
		domains: domains
		words: words

Mikuia.Web.post '/dashboard/plugins/mod/words/add', checkAuth, (req, res) ->
	if req.body.word?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._sadd 'plugin:mod:bannedWords', req.body.word.trim(), defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/words/remove', checkAuth, (req, res) ->
	if req.body.word?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._srem 'plugin:mod:bannedWords', req.body.word, defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/domains/add', checkAuth, (req, res) ->
	if req.body.domain?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._sadd 'plugin:mod:whitelistedDomains', req.body.domain.trim(), defer whatever, reply

	res.send 200

Mikuia.Web.post '/dashboard/plugins/mod/domains/remove', checkAuth, (req, res) ->
	if req.body.domain?
		Channel = new Mikuia.Models.Channel req.user.username
		await Channel._srem 'plugin:mod:whitelistedDomains', req.body.domain, defer whatever, reply

	res.send 200