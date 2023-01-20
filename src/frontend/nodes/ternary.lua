function ternary(state)
    local node = {
        type = 'ternary',
    }

    if not state:accept('?') then
        return nil
    end

    node.truthy = expression.ast(state)

    state:expect(':')

    node.falsey = expression.ast(state)

    return node

end

return { ast = ternary }