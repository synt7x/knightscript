function ifstat(state)
    state:expect('if')
    state:expect('(')

    local node = {
        type = 'if',
        condition = expression.ast(state),
        body = {}
    }

    state:expect(')')

    if not state:test('{') then
        state:enter(node, node.body)

        statement.ast(state)

        state:exit()
        return node
    end

    state:expect('{')

    state:enter(node, node.body)

    while not state:test('}') do
        statement.ast(state)
    end

    state:exit()

    state:expect('}')

    return node
end

return { ast = ifstat }