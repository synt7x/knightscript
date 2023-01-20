function functionstat(state)
    state:expect('function')

    local node = {
        type = 'function',
        name = state:accept('identifier'),
        parameters = {},
        body = {}
    }

    state:expect('(')

    if not state:test(')') then
        node.parameters = namelist.ast(state)
    end

    state:expect(')')
    state:expect('{')

    state:enter(node, node.body)

    while not state:test('}') do
        statement.ast(state)
    end

    state:exit()

    state:expect('}')

    return node
end

local function symbol(state, node)
    state:initializelocals(node)
    state:enter(node)

    if node.name then
        state:definition(node.name)
    end

    for i, parameter in ipairs(node.parameters) do
        state:localdefinition(parameter)
    end

    for i = #node.body, 1, -1 do
        statement.symbol(state, node.body[i])
    end

    state:exit()
end

return { ast = functionstat, symbol = symbol }