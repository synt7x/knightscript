local lexer = {}

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
	self.token = {}
	
	if not input then return end

	for i = 1, #input do
		self:step(input:sub(i, i), input:sub(i + 1, i + 1))
	end

	return self.tokens
end

function lexer:step(character, peek)
	if not self.token.type then
		self:type(character, peek)
		return 
	end
	local code = string.byte(character)
	if self.token.type == 'identifier' then
		if character == '_' or code >= 97 and code < 123 or code >= 65 and code < 91 or code >= 47 and code < 59 then
			self.token.string = self.token.string .. character
		else
            if self.reserved[self.token.string] then
                self.token.type = self.token.string
            end
            
			table.insert(self.tokens, self.token)
			self.token = {}
			self:type(character, peek)
			return 
		end
	elseif self.token.type == 'number' then
		if code >= 47 and code < 59 or character == '_' or character == 'e' or character == 'E' and not self.token.scientific then
			if character == 'e' or character == 'E' then
				self.token.scientific = character
			end
			self.token.string = self.token.string .. character
		else
			table.insert(self.tokens, self.token)
			self.token = {}
			self:type(character, peek)
			return 
		end
	elseif self.token.type == 'string' then
		if character == self.token.delimiter and not self.token.escaped then
			table.insert(self.tokens, self.token)
			self.token = {}
		else
			self.token.string = self.token.string .. character
		end
		if character == '\\' then
			self.token.escaped = true
		else
			self.token.escaped = nil
		end
	elseif self.token.type == 'double' or self.token.type == 'compound' then
		self.token.string = self.token.string .. character
		self.token.type = self.token.string
		table.insert(self.tokens, self.token)
		self.token = {}
		return 
	elseif self.token.type == 'comment' then
		if character ~= '\n' then
			self.token.string = self.token.string .. character
		else
			table.insert(self.tokens, self.token)
			self.token = {}
		end
	end
end

function lexer:type(character, peek)
	local code = string.byte(character)
	if character == ' ' or character == '\t' or character == '\n' or character == '\r' then
		return 
	elseif character == '"' or character == "'" then
		self.token.type = 'string'
		self.token.string = ''
		self.token.delimiter = character
	elseif character == '_' or code >= 97 and code < 123 or code >= 65 and code < 91 then
		self.token.type = 'identifier'
		self.token.string = character
	elseif code >= 48 and code < 58 then
		self.token.type = 'number'
		self.token.string = character
	elseif character == '#' then
		self.token.type = 'comment'
		self.token.string = ''
	elseif character == '*' or character == '/' or character == '%' or character == '^' or character == '!' or character == '=' or character == '>' or character == '<' then
		if peek == '=' then
			self.token.type = 'compound'
			self.token.string = character
		else
			table.insert(self.tokens, {
				type = character,
				string = character
			})
		end
	elseif character == '+' or character == '-' or character == '&' or character == '|' then
		if peek == character then
			self.token.type = 'double'
			self.token.string = character
		elseif peek == '=' then
			self.token.type = 'compound'
			self.token.string = character
		else
			table.insert(self.tokens, {
				type = character,
				string = character
			})
		end
	else
		table.insert(self.tokens, {
			type = character,
			string = character
		})
	end
end

return lexer