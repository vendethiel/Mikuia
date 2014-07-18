class exports.Format
	constructor: (Mikuia) ->
		@Mikuia = Mikuia

	parse: (format, data) ->
		re = /<%([^%>]+)?%>/g

		matches = []
		while match = re.exec format
			matches.push match

		for match in matches
			if data[match[1]]?
				format = format.replace match[0], data[match[1]]

		return format