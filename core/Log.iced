cli = require 'cli-color'
moment = require 'moment'

class exports.Log
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	log: (message, status, color) ->
		if status?
			if color?
				console.log moment().format('HH:mm:ss') + ' [' + color(status) + '] ' + message
			else
				console.log moment().format('HH:mm:ss') + ' [' + status + '] ' + message
		else
			console.log moment().format('HH:mm:ss') + '[UNKNOWN] ' + message

	success: (message) ->
		@log message, 'Success', cli.greenBright

	info: (message) ->
		@log message, 'Info', cli.whiteBright
	
	warning: (message) ->
		@log message, 'Warning', cli.yellowBright
	
	error: (message) ->
		@log message, 'Error', cli.redBright
	
	fatal: (message) ->
		@log message, 'Fatal', cli.red
		process.exit()