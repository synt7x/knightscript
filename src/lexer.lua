local lexer = {}
local frog = require('lib/frog')

lexer.reserved = {
    ['for'] = true,
    ['while'] = true,
    ['if'] = true,
    ['elseif'] = true,
    ['else'] = true,
    ['function'] = true,
    ['return'] = true,
    ['break'] = true,
    ['export'] = true,
    ['import'] = true,
    ['from'] = true,
    ['in'] = true,
    ['true'] = true,
    ['false'] = true,
    ['null'] = true,
    ['local'] = true,
    ['const'] = true,
}

function lexer.new(input)
	local self = {}
	for name, value in pairs(lexer) do
		self[name] = value
	end

	self.tokens = {}
	self.token = {
		position = { frog.line, frog.char, file = frog.file }
	}
    self.comments = {}
	
	if not input then return end

	for line in input:gmatch("([^\n]*)\n?") do
        table.insert(frog:getLines(), line or '')
    end

	for i = 1, #input do
		self:step(input:sub(i, i), input:sub(i + 1, i + 1))
	end

    if self.token.type then
        if self.token.type == 'string' then
            frog:croak('Unclosed string')
        elseif self.token.type == 'comment' then
            table.insert(self.comment, self.token)
        else
            table.insert(self.tokens, self.token)
        end
    end

	return self.tokens, self.comments
end

function lexer:step(character, peek)
	if not self.token.type then
		self:type(character, peek)
		return 
	end

	local code = string.byte(character)
	if self.token.type == 'identifier' then
		if character == '_' or code >= 97 and code < 123 or code >= 47 and code < 59 then
			self.token.characters = self.token.characters .. character
		else
            if self.reserved[self.token.characters] then
                self.token.type = self.token.characters
            end
            
			table.insert(self.tokens, self.token)
			self.token = {
				position = { frog.line, frog.char, file = frog.file }
			}
			self:type(character, peek)
			return 
		end
	elseif self.token.type == 'number' then
		if code > 47 and code < 59 or character == '_' then
			if character ~= '_' then
				self.token.characters = self.token.characters .. character
			end
		else
			table.insert(self.tokens, self.token)
			self.token = {
				position = { frog.line, frog.char, file = frog.file }
			}
			self:type(character, peek)
			return 
		end
	elseif self.token.type == 'string' then
		if character == self.token.delimiter and not self.token.escaped then
			table.insert(self.tokens, self.token)
			self.token = {
				position = { frog.line, frog.char, file = frog.file }
			}
		else
			self.token.characters = self.token.characters .. character
		end
		if character == '\\' then
			self.token.escaped = true
		else
			self.token.escaped = nil
		end
	elseif self.token.type == 'double' or self.token.type == 'compound' then
		self.token.characters = self.token.characters .. character
		self.token.type = self.token.characters
		table.insert(self.tokens, self.token)
		self.token = {
			position = { frog.line, frog.char, file = frog.file }
		}
		return 
	elseif self.token.type == 'comment' then
		if #self.token.characters == 0 and character == '-' then
			return
		elseif character ~= '\n' then
			self.token.characters = self.token.characters .. character
		else
			table.insert(self.comments, self.token)
			frog:newline()
			self.token = {
				position = { frog.line, frog.char, file = frog.file }
			}
		end
	end

	frog:character()
end

function lexer:type(character, peek)
	self.token = {
		position = { frog.line, frog.char, file = frog.file }
	}

	local code = string.byte(character)
	if character == ' ' or character == '\t' or character == '\r' then
		frog:character()
		return
	elseif character == '\n' then
		frog:newline()
		return
	elseif character == '"' or character == "'" then
		self.token.type = 'string'
		self.token.characters = ''
		self.token.delimiter = character
	elseif character == '_' or code >= 97 and code < 123 then
		self.token.type = 'identifier'
		self.token.characters = character
	elseif code >= 65 and code < 91 then
		frog:throw(
			self.token,
			'Identifiers can only be lowercase', 'Change this uppercase character to lowercase'
		)

		os.exit(1)
	elseif code >= 48 and code < 58 then
		self.token.type = 'number'
		self.token.characters = character
	elseif character == '*' or character == '/' or character == '%' or character == '^' or character == '!' or character == '=' or character == '>' or character == '<' or character == '#' then
		if peek == '=' then
			self.token.type = 'compound'
			self.token.characters = character
		else
			table.insert(self.tokens, {
				type = character,
				string = character,
				position = { frog.line, frog.char, file = frog.file }
			})
		end
	elseif character == '+' or character == '-' or character == '&' or character == '|' then
		if peek == '=' then
			self.token.type = 'compound'
			self.token.characters = character
		elseif character == '-' and peek == '-' then
			self.token.type = 'comment'
			self.token.characters = ''
		else
			table.insert(self.tokens, {
				type = character,
				string = character,
				position = { frog.line, frog.char, file = frog.file }
			})
		end
	else
		table.insert(self.tokens, {
			type = character,
			string = character,
			position = { frog.line, frog.char, file = frog.file }
		})
	end

	frog:character()
end

return lexer