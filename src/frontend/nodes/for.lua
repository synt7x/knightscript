function forstat(state)
    state:expect('for')
    state:expect('(')

    local node = {
        type = 'for',
        variable = {
            state:expect('identifier')
        },
        body = {}
    }

    if state:accept('=') then
        node.initial = expression.ast(state)
        state:expect(',')

        node.limit = expression.ast(state)

        if state:accept(',') then
            node.step = expression.ast(state)
        end
    else
        node.key = node.variable
        node.variable = nil

        if node.accept(',') then
            node.value = state:expect('identifier')
        end

        state:expect('in')

        node.iterator = expression.ast(state)
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

return { ast = forstat }