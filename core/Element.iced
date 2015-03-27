module.exports = class Element
	constructor: (Mikuia) ->
		@Mikuia = Mikuia
		@elements = {}

	getAll: (key) -> @elements[key]

	preparePanels: (key, callback) =>
		panels = @getAll key + '.panel'
		results = []

		if panels?.length
			for panel in panels
				plugin = Mikuia.Plugin.get panel.plugin
				await plugin.getPanel panel.id, defer response
				results.push
					title: panel.title,
					content: response

		callback results

	register: (name, value) ->
		@elements[key] ?= []
		if value not in @elements[key]
			@elements[key].push value
