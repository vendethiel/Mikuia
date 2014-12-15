moment = require 'moment'

module.exports = (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username

	await
		Channel.getFollowers defer err, followers
		Channel.getSupporterStart defer err, supporterStart
		Channel.getSupporterStatus defer err, supporterStatus
		Channel.isEnabled defer err2, enabled
		Channel.isLive defer err3, live
		Channel.isSupporter defer err, supporter

	tracker = {}
	if live
		await 
			Channel.trackGet 'viewers', defer err, tracker.viewers
			Channel.trackGet 'chatters', defer err, tracker.chatters
	await Channel.trackGet 'commands', defer err, tracker.commands
	await Channel.trackGet 'messages', defer err, tracker.messages

	supporterLeftText = moment.unix(supporterStatus).fromNow()

	# Best error handling EUNE
	if err then console.log err
	if err2 then console.log err2
	if err3 then console.log err3
	# DURRR

	res.render 'dashboard',
		channel: Channel.getName()
		enabled: enabled
		followers: followers
		live: live
		supporter: supporter
		supporterLeftText: supporterLeftText
		supporterStart: supporterStart
		supporterStatus: supporterStatus
		tracker: tracker