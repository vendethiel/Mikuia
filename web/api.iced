express = require 'express'

app = module.exports.app = express()

app.get '/user/:username', (req, res) =>
	Channel = new Mikuia.Models.Channel req.params.username

	await Channel.exists defer err, channelExists
	if not err and channelExists
		res.send 'Yeah, the channel exists!'
	else
		res.send 500

app.get '/*', (req, res) =>
	res.send 'Hello!'

app.head '/*', (req, res) =>
	res.send 'Hi Mashape!'