function ifstat(state)
    state:expect('if')
    state:expect('(')

    local node = {
        type = 'if',
        condition = expression.ast(state),
        body = {}
    }

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

return { ast = ifstat }