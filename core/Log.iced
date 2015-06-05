cli = require 'cli-color'
fs = require 'fs'
moment = require 'moment'

class exports.Log
	constructor: (@Mikuia) ->

	consoleLog: (message) =>
		console.log message
		fs.appendFileSync 'logs/mikuia/' + moment().format('YYYY-MM-DD') + '.txt', message + '\n'

	log: (message, status, color) ->
		if status?
			if color?
				@consoleLog moment().format('HH:mm:ss') + ' [' + color(status) + '] ' + message
			else
				@consoleLog moment().format('HH:mm:ss') + ' [' + status + '] ' + message
		else
			@consoleLog moment().format('HH:mm:ss') + '[UNKNOWN] ' + message

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
		process.exit 1
