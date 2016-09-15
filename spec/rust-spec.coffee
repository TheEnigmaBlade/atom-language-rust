# Utilities
token = (value, scope) ->
	scopes: [
		'source.rust'
		(if Array.isArray scope
     	scope
     else
       [scope])...
	]
	value: value

currentLine = 0
currentToken = -1

expectToken = (tokens, lineN, tokenN, value, scope) ->
	currentLine = lineN
	currentToken = tokenN
	t = tokens[lineN][tokenN]
	ct = token value, scope
	expect(t.value).toEqual ct.value
	expect(t.scopes).toEqual ct.scopes

expectNoScope = (tokens, lineN, tokenN, scope) ->
	currentLine = lineN
	currentToken = tokenN
	t = tokens[lineN][tokenN]
	expect(t.scopes).not.toContain scope

expectNext = (tokens, value, scope) ->
	expectToken(tokens, currentLine, currentToken+1, value, scope)

nextLine = ->
	currentLine += 1
	currentToken = -1

reset = ->
	currentLine = 0
	currentToken = -1

tokenize = (grammar, value) ->
	reset()
	grammar.tokenizeLines value

# Main
describe 'atom-language-rust', ->
	grammar = null
	
	# Setup
	beforeEach ->
		waitsForPromise ->
			atom.packages.activatePackage 'language-rust'
		runs ->
			grammar = atom.grammars.grammarForScopeName('source.rust')
	
	it 'should be ready to parse', ->
		expect(grammar).toBeDefined()
		expect(grammar.scopeName).toBe 'source.rust'
	
	# Tests
	
	describe 'when tokenizing comments', ->
		it 'should recognize line comments', ->
			tokens = tokenize grammar, '// test'
			expectNext tokens,
				'//',
				'comment.line.rust'
			expectNext tokens,
				' test',
				'comment.line.rust'
				
		it 'should recognize multiline comments', ->
			tokens = tokenize grammar, '/*\ntest\n*/'
			expectToken tokens, 0, 0,
				'/*',
				'comment.block.rust'
			expectToken tokens, 1, 0,
				'test',
				'comment.block.rust'
			expectToken tokens, 2, 0,
				'*/',
				'comment.block.rust'
		
		it 'should nest multiline comments', ->
			tokens = tokenize grammar, '/*\n/*\n*/\n*/'
			expectToken tokens, 0, 0,
				'/*',
				'comment.block.rust'
			expectToken tokens, 1, 0,
				'/*',
				['comment.block.rust', 'comment.block.rust']
			expectToken tokens, 2, 0,
				'*/',
				['comment.block.rust', 'comment.block.rust']
			expectToken tokens, 3, 0,
				'*/',
				'comment.block.rust'
	
	describe 'when tokenizing doc comments', ->
		it 'should recognize line doc comments', ->
			tokens = tokenize grammar, '//! test\n/// test'
			expectNext tokens,
				'//! ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'test',
				'comment.line.documentation.rust'
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'test',
				'comment.line.documentation.rust'
		
		it 'should recognize block doc comments', ->
			tokens = tokenize grammar, '/**\ntest\n*/'
			expectToken tokens, 0, 0,
				'/**',
				['comment.block.documentation.rust', 'invalid.deprecated.rust']
			expectToken tokens, 1, 0,
				'test',
				'comment.block.documentation.rust'
			expectToken tokens, 2, 0,
				'*/',
				['comment.block.documentation.rust', 'invalid.deprecated.rust']
		
		it 'should parse inline markdown', ->
			tokens = tokenize grammar, '''
				/// *italic*
				/// **bold**
				/// _italic_
				/// __underline__
				/// ***bolditalic***
				'''
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'bold',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'italic',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'_',
				['comment.line.documentation.rust', 'markup.italic.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens,
				'underline',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			expectNext tokens,
				'__',
				['comment.line.documentation.rust', 'markup.underline.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'bolditalic',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'*',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust', 'markup.italic.documentation.rust']
			expectNext tokens,
				'**',
				['comment.line.documentation.rust', 'markup.bold.documentation.rust']
		
		it 'should parse header markdown', ->
			tokens = tokenize grammar, '''
				/// # h1
				/// ## h2
				/// ### h3
				/// #### h4
				/// ##### h5
				/// ###### h6
				/// ####### h6
				'''
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h1',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'##',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h2',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'###',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h3',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h4',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'#####',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h5',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'######',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.heading.punctuation.definition.documentation.rust']
			expectNext tokens,
				'#',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust', 'markup.invalid.illegal.documentation.rust']
			expectNext tokens,
				' h6',
				['comment.line.documentation.rust', 'markup.heading.documentation.rust']
		
		it 'should parse link markdown', ->
			tokens = tokenize grammar, '''
				/// [text]()
				/// [text](http://link.com)
				/// [text](http://link.com "title")
				/// ![text](http://link.com)
				/// [text]
				/// [text]: http://link.com
				'''
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'()',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.invalid.illegal.documentation.rust']

			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				' ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'"title"',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'![text](',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			expectNext tokens,
				')',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]',
				'comment.line.documentation.rust'
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'[text]: ',
				['comment.line.documentation.rust', 'markup.link.documentation.rust']
			expectNext tokens,
				'http://link.com',
				['comment.line.documentation.rust', 'markup.link.documentation.rust', 'markup.link.entity.documentation.rust']
			
		it 'should parse code blocks', ->
			tokens = tokenize grammar, '''
				/// text `code` text
				/// ```rust
				/// impl such_code for wow {
				///     type Many = Tokens;
				/// }
				/// ```
				'''
			
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'text ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'`code`',
				['comment.line.documentation.rust', 'markup.code.raw.inline.documentation.rust']
			expectNext tokens,
				' text',
				'comment.line.documentation.rust'
			
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			expectNext tokens,
				'rust',
				['comment.line.documentation.rust', 'markup.bold.code.raw.block.name.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'impl such_code for wow {',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'///     ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'type Many = Tokens;',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'}',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
			nextLine()
			expectNext tokens,
				'/// ',
				'comment.line.documentation.rust'
			expectNext tokens,
				'```',
				['comment.line.documentation.rust', 'markup.code.raw.block.documentation.rust']
	
	describe 'when tokenizing strings', ->
		#TODO: unicode tests
		it 'should parse strings', ->
			tokens = tokenize grammar, '"test"'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			
			tokens = tokenize grammar, '"test\\ntset"'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens,
				'tset',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
		
		it 'should parse byte strings', ->
			tokens = tokenize grammar, 'b"test"'
			expectNext tokens,
				'b"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
			
			tokens = tokenize grammar, 'b"test\\ntset"'
			expectNext tokens,
				'b"',
				'string.quoted.double.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.rust'
			expectNext tokens,
				'\\n',
				['string.quoted.double.rust', 'constant.character.escape.rust']
			expectNext tokens,
				'tset',
				'string.quoted.double.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.rust'
		
		it 'should parse raw strings', ->
			tokens = tokenize grammar, 'r"test"'
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'r"test\\ntset"'
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'r##"test##"#tset"##'
			expectNext tokens,
				'r##"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test##"#tset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"##',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'r"test\ntset"'
			expectNext tokens,
				'r"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			nextLine()
			expectNext tokens,
				'tset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'r#"test#"##test"#'
			expectNext tokens,
				'r#"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test#',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"#',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'#',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'test',
				[]
		
		it 'should parse raw byte strings', ->
			tokens = tokenize grammar, 'br"test"'
			expectNext tokens,
				'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'br"test\\ntset"'
			expectNext tokens,
				'br"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test\\ntset',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			
			tokens = tokenize grammar, 'rb"test"'
			expectNext tokens,
				'rb',
				['string.quoted.double.raw.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'test',
				'string.quoted.double.raw.rust'
			expectNext tokens,
				'"',
				'string.quoted.double.raw.rust'
		
		it 'should parse character strings', ->
			tokens = tokenize grammar, '\'a\''
			#TODO
			
			tokens = tokenize grammar, '\'\\n\''
			#TODO
			
			tokens = tokenize grammar, '\'abc\''
			expectNext tokens,
				'\'',
				'string.quoted.single.rust'
			expectNext tokens,
				'a',
				'string.quoted.single.rust'
			expectNext tokens,
				'bc',
				['string.quoted.single.rust', 'invalid.illegal.rust']
			expectNext tokens,
				'\'',
				'string.quoted.single.rust'
		
		it 'should parse character byte strings', ->
			tokens = tokenize grammar, 'b\'a\''
			#TODO
		
		it 'should parse escape characters', ->
			#TODO
	
	describe 'when tokenizing format strings', ->
		#TODO

	describe 'when tokenizing floating-point literals', ->
		it 'should parse without type', ->
			tokens = tokenize grammar, '4.2'
			expectNext tokens,
				'4.2',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '4_2.0'
			expectNext tokens,
				'4_2.0',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '0_________0.6'
			expectNext tokens,
				'0_________0.6',
				'constant.numeric.float.rust'
		
		it 'should parse with type', ->
			tokens = tokenize grammar, '4f32'
			expectNext tokens,
				'4f32',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '4f64'
			expectNext tokens,
				'4f64',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '4.2f32'
			expectNext tokens,
				'4.2f32',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '3_________3f32'
			expectNext tokens,
				'3_________3f32',
				'constant.numeric.float.rust'
		
		it 'should parse with exponents', ->
			tokens = tokenize grammar, '3e8'
			expectNext tokens,
				'3e8',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '3E8'
			expectNext tokens,
				'3E8',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '3e+8'
			expectNext tokens,
				'3e+8',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '3e-8'
			expectNext tokens,
				'3e-8',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '2.99e8'
			expectNext tokens,
				'2.99e8',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '6.626e-34'
			expectNext tokens,
				'6.626e-34',
				'constant.numeric.float.rust'
			
			tokens = tokenize grammar, '3e8f64'
			expectNext tokens,
				'3e8f64',
				'constant.numeric.float.rust'
	
	describe 'when tokenizing integer literals', ->
		it 'should parse decimal', ->
			tokens = tokenize grammar, '13'
			expectNext tokens,
				'13',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '1_013'
			expectNext tokens,
				'1_013',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '_031'
			expectNoScope tokens, 0, 0,
				'constant.numeric.integer.decimal.rust'
		
		it 'should parse type suffixes', ->
			tokens = tokenize grammar, '101u8'
			expectNext tokens,
				'101u8',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '103u16'
			expectNext tokens,
				'103u16',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '107u32'
			expectNext tokens,
				'107u32',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '109u64'
			expectNext tokens,
				'109u64',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '113i8'
			expectNext tokens,
				'113i8',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '127i16'
			expectNext tokens,
				'127i16',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '131i32'
			expectNext tokens,
				'131i32',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '137i64'
			expectNext tokens,
				'137i64',
				'constant.numeric.integer.decimal.rust'
			
			tokens = tokenize grammar, '139int'
			expectNext tokens,
				'139',
				'constant.numeric.integer.decimal.rust'
			expectNext tokens,
				'int',
				['constant.numeric.integer.decimal.rust', 'invalid.illegal.rust']
			
			tokens = tokenize grammar, '149uint'
			expectNext tokens,
				'149',
				'constant.numeric.integer.decimal.rust'
			expectNext tokens,
				'uint',
				['constant.numeric.integer.decimal.rust', 'invalid.illegal.rust']
			
			tokens = tokenize grammar, '151is'
			expectNext tokens,
				'151',
				'constant.numeric.integer.decimal.rust'
			expectNext tokens,
				'is',
				['constant.numeric.integer.decimal.rust', 'invalid.illegal.rust']
			
			tokens = tokenize grammar, '157us'
			expectNext tokens,
				'157',
				'constant.numeric.integer.decimal.rust'
			expectNext tokens,
				'us',
				['constant.numeric.integer.decimal.rust', 'invalid.illegal.rust']
		
		it 'should parse hexadecimal', ->
			tokens = tokenize grammar, '0x123'
			expectNext tokens,
				'0x123',
				'constant.numeric.integer.hexadecimal.rust'
			
			tokens = tokenize grammar, '0xbeeF'
			expectNext tokens,
				'0xbeeF',
				'constant.numeric.integer.hexadecimal.rust'
			
			tokens = tokenize grammar, '0x1_2_3'
			expectNext tokens,
				'0x1_2_3',
				'constant.numeric.integer.hexadecimal.rust'
			
			tokens = tokenize grammar, '0x123u8'
			expectNext tokens,
				'0x123u8',
				'constant.numeric.integer.hexadecimal.rust'
			
			tokens = tokenize grammar, '0x123us'
			expectNext tokens,
				'0x123',
				'constant.numeric.integer.hexadecimal.rust'
			expectNext tokens,
				'us',
				['constant.numeric.integer.hexadecimal.rust', 'invalid.illegal.rust']
		
		it 'should parse octal', ->
			tokens = tokenize grammar, '0o123'
			expectNext tokens,
				'0o123',
				'constant.numeric.integer.octal.rust'
			
			tokens = tokenize grammar, '0o1_2_3'
			expectNext tokens,
				'0o1_2_3',
				'constant.numeric.integer.octal.rust'
			
			tokens = tokenize grammar, '0o123u8'
			expectNext tokens,
				'0o123u8',
				'constant.numeric.integer.octal.rust'
			
			tokens = tokenize grammar, '0o123us'
			expectNext tokens,
				'0o123',
				'constant.numeric.integer.octal.rust'
			expectNext tokens,
				'us',
				['constant.numeric.integer.octal.rust', 'invalid.illegal.rust']
		
		it 'should parse binary', ->
			tokens = tokenize grammar, '0b1111011'
			expectNext tokens,
				'0b1111011',
				'constant.numeric.integer.binary.rust'
			
			tokens = tokenize grammar, '0b1_11_10_11'
			expectNext tokens,
				'0b1_11_10_11',
				'constant.numeric.integer.binary.rust'
			
			tokens = tokenize grammar, '0b1111011u8'
			expectNext tokens,
				'0b1111011u8',
				'constant.numeric.integer.binary.rust'
			
			tokens = tokenize grammar, '0b1111011us'
			expectNext tokens,
				'0b1111011',
				'constant.numeric.integer.binary.rust'
			expectNext tokens,
				'us',
				['constant.numeric.integer.binary.rust', 'invalid.illegal.rust']
	
	
