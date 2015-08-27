countdown = require 'countdown'
moment = require 'moment'

countdown.setLabels	'ms|s|m|h|d|w|mo|y|dc|ct|ml',
	'ms|s|m|h|d|w|mo|y|dc|ct|ml',
	' ',
	' ',
	'',
	(n) -> n.toString()

class exports.Format
	constructor: (@Mikuia) ->

	parse: (format, data) ->
		re = /<%([^%>]+)?%>/g

		matches = []
		while match = re.exec format
			matches.push match

		for match in matches
			if data[match[1]]?
				format = format.replace match[0], data[match[1]]
			else if match[1].indexOf('/') > -1
				tokens = match[1].split '/'
				if data[tokens[tokens.length - 1]]?
					variable = data[tokens[tokens.length - 1]]
					tokens.splice tokens.length - 1, 1
					for token in tokens
						switch token

							# Math!
							when "ceil"
								variable = Math.ceil variable
							when "commas"
								# http://stackoverflow.com/questions/2901102/how-to-print-a-number-with-commas-as-thousands-separators-in-javascript
								parts = variable.toString().split '.'
								parts[0] = parts[0].replace /\B(?=(\d{3})+(?!\d))/g, ','
								variable = parts.join '.'
							when "floor"
								variable = Math.floor variable
							when "round"
								variable = Math.round variable
							when "round1"
								variable = Math.round(variable * 10) / 10
							when "round2"
								variable = Math.round(variable * 100) / 100
							when "round3"
								variable = Math.round(variable * 1000) / 1000
							when "round4"
								variable = Math.round(variable * 10000) / 10000

							# Strings!
							when "lower"
								variable = variable.toString().toLowerCase()
							when "upper"
								variable = variable.toString().toUpperCase()

							# Dates!
							when "countdown"
								variable = countdown(new Date(variable)).toString()
							when "timeago"
								variable = moment(variable).fromNow()

					format = format.replace match[0], variable
				else
					format = format.replace match[0], '!undefined!'
			else
				format = format.replace match[0], ''

		return format
