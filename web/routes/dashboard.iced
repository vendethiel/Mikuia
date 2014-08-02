module.exports = (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username

	await
		Channel.isEnabled defer err, enabled
		Channel.isLive defer err2, live

	tracker = {}
	if live
		await 
			Channel.trackGet 'viewers', defer err, tracker.viewers
			Channel.trackGet 'chatters', defer err, tracker.chatters
	await Channel.trackGet 'commands', defer err, tracker.commands
	await Channel.trackGet 'messages', defer err, tracker.messages

	# Best error handling EUNE
	if err then console.log err
	if err2 then console.log err2

	res.render 'dashboard',
		enabled: enabled
		live: live
		tracker: tracker