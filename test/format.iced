should = require 'should'
formatter = new (require('../core/Format').Format)
format = (str, o = {}) -> formatter.parse str, o

describe 'Format', ->
	it 'should do nothing for simple cases', ->
		format('hey you').should.equal 'hey you'

	describe 'new format', ->
		it 'should allow mixed expressions', ->
			format('foo {{"bar"}} baz').should.equal 'foo bar baz'

		it 'should parse expressions', ->
			format('{{ 2 }}').should.equal '2'

		it 'should parse math expressions', ->
			format('{{ 2 + 2 }}').should.equal '4'

		it 'should know about defined variables', ->
			format('{{ a + b }}', a: 5, b: 6).should.equal '11'

		it 'should find defined functions', ->
			format('{{ inc(a) }}', a: 5, inc: (x) -> x + 1).should.equal '6'
