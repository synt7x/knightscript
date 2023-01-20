function array(state)
    state:expect('[')

    local node = {
        type = 'array',
        elements = {}
    }

    if not state:test(']') then
        repeat
            table.insert(node.elements, expression.ast(state))
        until not state:accept(',')
    end

    state:expect(']')

    return node
end

return { ast = array }