local config = require("config")
local frog = require("lib/frog")
local json = require("lib/json")

local parser = {}
local tree = require("src/tree")

function parser.new(flags, tokens, comments)
	local self = {}
	for name, value in pairs(parser) do
		self[name] = value
	end
	self.tokens = tokens
	self.index = 1
	self.flags = flags
	self.tree = {
		type = "program",
		version = config.version,
		body = {},
		comments = comments,
	}

	self.token = self.tokens[self.index]
	self.ancestory = {}
	self.symbols = {}
	self.node = self.tree
	self.node.body = tree(self)

	if self.token then
		frog:throw(
			self.token,
			"Extraneous token following body",
			'Try removing this token or inserting a ";" prior',
			"Parser"
		)

		os.exit(1)
	end

	return self.tree, self.symbols
end

function parser:symbol(identifier)
	self.symbols[identifier.characters] = true
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
		frog:throw(
			self.tokens[self.index - 1],
			"Expected " .. tokenType .. " but got EOF",
			"Add a " .. tokenType .. " to satisfy the parser"
		)
		os.exit(1)
	end

	if tokenString then
		frog:throw(
			self.token,
			"Expected "
				.. tokenType
				.. ' "'
				.. tokenString
				.. '" but got '
				.. self.token.type
				.. " '"
				.. self.token.string
				.. "'",
			'Replace this with "' .. tokenString .. '"'
		)
	else
		frog:throw(
			self.token,
			"Expected " .. tokenType .. " but got " .. self.token.type,
			"Use " .. tokenType .. " here instead of " .. self.token.type
		)
	end

	while not self:accept(tokenType, tokenString) do
		if not self:skip() then
			os.exit(1)
		end
	end

	return nil
end

function parser:enter(node, body)
	table.insert(self.ancestory, {
		self.tree,
		self.node,
	})

	self.tree = body
	self.node = node
end

function parser:exit()
	local ancestor = table.remove(self.ancestory)
	self.tree = ancestor[1]
	self.node = ancestor[2]
end

parser.traversal = {
	binary = {
		["add"] = "+",
		["subtract"] = "-",
		["multiply"] = "*",
		["divide"] = "/",
		["expr"] = ";",
		["exact"] = "?",
		["and"] = "&",
		["or"] = "|",
		["less"] = "<",
		["greater"] = ">",
		["modulus"] = "%",
		["exponent"] = "^",
	},

	unary = {
		["quit"] = "Q",
		["output"] = "O",
		["dump"] = "D",
		["length"] = "L",
		["not"] = "!",
		["prime"] = "[",
		["ultimate"] = "]",
		["box"] = ",",
		["ascii"] = "A",
		["negate"] = "~",
	},

	literal = {
		["number"] = true,
		["string"] = true,
		["array"] = true,
		["boolean"] = true,
		["null"] = true,
	},
}

return parser
