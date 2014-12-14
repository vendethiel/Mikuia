module.exports = (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username

	await
		Channel.isDonator defer err, donator
		Channel.isEnabled defer err2, enabled
		Channel.isLive defer err3, live

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
	if err3 then console.log err3
	# DURRR

	res.render 'dashboard',
		donator: donator
		enabled: enabled
		live: live
		tracker: tracker