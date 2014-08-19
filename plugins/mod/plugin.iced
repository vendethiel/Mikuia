Mikuia.Element.register 'dashboardPagePlugin',
	plugin: 'mod'
	pages:
		'/':
			name: 'Mod Tools - Index'
			icon: 'icon-settings'
		'/words':
			name: 'Mod Tools - Banned Words'
			icon: 'icon-settings'

checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

Mikuia.Events.on 'twitch.message', (user, to, message) =>
	Channel = new Mikuia.Models.Channel to
	await Channel.isPluginEnabled 'mod', defer err, enabled
	if !err && enabled

		# Banned Words
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

		mods = Mikuia.Chat.mods Channel.getName()
		if timeout && Mikuia.settings.bot.name.toLowerCase() in mods && user.username not in mods
			Mikuia.Chat.say Channel.getName(), '.timeout ' + user.username + ' 10'
			Mikuia.Chat.say Channel.getName(), 'MOM GET THE CAMERA, ' + user.username.toUpperCase() + ' JUST GOT REKT!'

Mikuia.Web.get '/dashboard/plugins/mod', checkAuth, (req, res) ->
	res.render '../../plugins/mod/views/index'

Mikuia.Web.get '/dashboard/plugins/mod/words', checkAuth, (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username
	await Channel._smembers 'plugin:mod:bannedWords', defer whatever, words

	res.render '../../plugins/mod/views/words',
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


# Mikuia.Web.post '/dashboard/plugins/osu/auth', (req, res) =>
# 	if req.body.authCode? && codes[req.body.authCode]?
# 		Channel = new Mikuia.Models.Channel req.user.username

# 		await Channel.setSetting 'osu', 'name', codes[req.body.authCode], defer err, data
# 		@Plugin.Log.info 'Authenticated ' + cli.yellowBright(codes[req.body.authCode]) + '.'
# 		delete codes[req.body.authCode]

# 	res.redirect '/dashboard/settings'

# # np! continuing the old path so people don't have to reconfigure osu!np
# Mikuia.Web.post '/plugins/osu/post/:username', (req, res) ->
# 	console.log req.body

# 	res.send 200
