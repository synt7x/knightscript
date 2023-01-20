local config = require('config')
local frog = require('lib/frog')
local program = require('src/frontend/nodes/program')

local symbols = {}

function symbols.new(tree)
	local self = {}
	for name, value in pairs(symbols) do
		self[name] = value
	end

	self.body = tree.body
    self.symbolId = 0
    
    self.body.globals = {}
    self.globals = self.body.globals
    self.ancestory = {}
    self.parent = self.body
    self.index = 1

    program.symbol(self)
	return self
end

function symbols:reference(node)
    local symbol = self.globals[node.string]

    if symbol then
        table.insert(symbol.references, node)
    else
        self.globals[node.string] = {
            references = {
                node
            },
            name = node.string,
            definitions = {},
            scope = {
                ['end'] = node
            },
            id = self.symbolId,
        }

        self.symbolId = self.symbolId + 1
    end
end

function symbols:definition(node)
    local symbol = self.globals[node.string]

    if symbol then
        table.insert(symbol.definitions, node)
        symbol.scope.start = node
        node.id = symbol.id
    else
        self.globals[node.string] = {
            references = {},
            name = node.string,
            definitions = {
                node
            },
            scope = {
                ['end'] = node
            },
            id = self.symbolId,
        }

        node.id = self.symbolId
        self.symbolId = self.symbolId + 1
    end
end

function symbols:localdefinition(node)
    node.id = self.symbolId
    self.symbolId = self.symbolId + 1

    table.insert(self.parent.locals.definitions, node)

    for i = self.index + 1, #self.parent.body do
        local propagation = self.parent.body[self.index]
        
        if propagation.locals then
            table.insert(propagation.locals.definitions, node)
        end
    end
end

function symbols:checklocality(parent, node)
    if parent.locals and parent.locals[node.string] then
        return true
    end

    return false
end

function symbols:initializelocals(node)
    self.parent = node
    self.index = #node.body

    node.locals = {
        references = {},
        definitions = {},
    }

    return node.locals
end

function symbols:enter(node)
	table.insert(self.ancestory, self.node)
end

function symbols:exit()
	table.remove(self.ancestory)
end

return symbols