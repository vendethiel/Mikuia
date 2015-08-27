checkAuth = (req, res, next) ->
	if req.isAuthenticated()
		return next()
	res.redirect '/login'

Mikuia.Element.register 'dashboardPagePlugin',
	plugin: 'coins'
	pages:
		'/':
			name: 'Coins'
			icon: 'icon-wallet'

Mikuia.Web.get '/dashboard/plugins/coins', checkAuth, (req, res) ->
	await Mikuia.Database.zrevrangebyscore 'channel:' + req.user.username + ':coins', '+inf', '-inf', 'withscores', defer whatever, coins

	coinRawData = Mikuia.Tools.chunkArray coins, 2
	displayNames = {}
	isStreamer = {}
	logos = {}

	for data in coinRawData
		if data.length > 0
			channel = new Mikuia.Models.Channel data[0]
			coinAmount = data[1]

			await
				channel.isStreamer defer err, isStreamer[data[0]]
				channel.getDisplayName defer err, displayNames[data[0]]
				channel.getLogo defer err, logos[data[0]]

	res.render '../../plugins/coins/views/index',
		coins: coinRawData
		displayNames: displayNames
		isStreamer: isStreamer
		logos: logos

Mikuia.Web.post '/dashboard/plugins/coins/edit', checkAuth, (req, res) ->
	if req.body.method? and req.body.amount? and req.body.username?

		Viewer = new Mikuia.Models.Channel req.body.username
		
		switch req.body.method
			when 'give'
				await Mikuia.Database.zincrby 'channel:' + req.user.username + ':coins', req.body.amount, Viewer.getName(), defer error, whatever
			when 'set'
				await Mikuia.Database.zadd 'channel:' + req.user.username + ':coins', req.body.amount, Viewer.getName(), defer error, whatever
			when 'take'
				await Mikuia.Database.zincrby 'channel:' + req.user.username + ':coins', parseInt(req.body.amount) * -1, Viewer.getName(), defer error, whatever

	res.send 200