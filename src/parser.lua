local config = require('config')
local frog = require('lib/frog')
local program = require('src/nodes/program')

local parser = {}

function parser.new(tokens, flags, comments)
	local self = {}
	for name, value in pairs(parser) do
		self[name] = value
	end
	self.tokens = tokens
	self.index = 1
	self.flags = flags
	self.tree = {
		type = 'program',
		version = config.version,
		body = {},
        comments = comments
	}

    self.token = self.tokens[self.index]
	self.ancestory = {}
	self.node = self.tree
	return program.ast(self)
end

function parser:skip()
	if not self.token then
		return 
	end
	self.index = self.index + 1
	self.token = self.tokens[self.index]
	return self.tokens[self.index - 1]
end

function parser:test(tokenType, tokenString)
	if not self.token then
		return 
	end
	if tokenString then
		if self.token.type == tokenType and self.token.string == tokenString then
			return self.token
		end
	else
		if self.token.type == tokenType then
			return self.token
		end
	end
	return nil
end

function parser:accept(tokenType, tokenString)
	if not self.token then
		return 
	end

	if self:test(tokenType, tokenString) then
		self.index = self.index + 1
        self.token = self.tokens[self.index]
        return self.tokens[self.index - 1]
	end
end

function parser:peek(tokenType, tokenString)
	self.index = self.index + 1
	self.token = self.tokens[self.index]
	local peeked = self:test(tokenType, tokenString)
	
	self.token = self.tokens[self.index]
	return peeked
end

function parser:expect(tokenType, tokenString)
	local assertion = self:accept(tokenType, tokenString)
	if assertion then
		return assertion
	end

    if not self.token then
        frog:croak('Expected ' .. tokenType .. ' but got EOF')
        os.exit(1)
    end

	if tokenString then
		frog:croak('Expected ' .. tokenType .. " '" .. tokenString .. "' but got " .. self.token.type .. " '" .. self.token.string .. "'")
	else
		frog:croak('Expected ' .. tokenType .. ' but got ' .. self.token.type)
	end

    while not self:accept(tokenType, tokenString) do
        if not self:skip() then os.exit(1) end
    end

	return nil
end

function parser:enter(node, body)
	table.insert(self.ancestory, {
		self.tree,
		self.node
	})
	self.tree = body
	self.node = node
end

function parser:exit()
	local ancestor = table.remove(self.ancestory)
	self.tree = ancestor[1]
	self.node = ancestor[2]
end

return parser