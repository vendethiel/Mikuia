moment = require 'moment'

module.exports = (req, res) ->
	Channel = new Mikuia.Models.Channel req.user.username

	await
		Channel.getSupporterStart defer err1, supporterStart
		Channel.getSupporterStatus defer err2, supporterStatus
		Channel.isEnabled defer err3, enabled
		Channel.isLive defer err4, live
		Channel.isSupporter defer err5, supporter

	tracker = {}
	if live
		await 
			Channel.trackGet 'viewers', defer err, tracker.viewers
			Channel.trackGet 'chatters', defer err, tracker.chatters
	await Channel.trackGet 'commands', defer err, tracker.commands
	await Channel.trackGet 'followers', defer err, tracker.followers
	await Channel.trackGet 'messages', defer err, tracker.messages

	supporterLeftText = moment.unix(supporterStatus).fromNow()

	for err in [err1, err2, err3, err4, err5]
		console.log 'dashboard error', err if err

	res.render 'dashboard', {
		enabled, live, supporter, supporterLeftText,
		supporterStart, supporterStatus, tracker
		channel: Channel.getName()
	}
