class exports.Element
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@elements = {}

	getAll: (key) -> @elements[key]

	register: (key, name) ->
		if !@elements[key]
			@elements[key] = []
		if @elements[key].indexOf(name) == -1
			@elements[key].push name