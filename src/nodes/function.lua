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

return { ast = functionstat }