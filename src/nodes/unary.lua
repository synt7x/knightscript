function unary(state)
    local node = {
        type = 'unary',
        body = {}
    }

    if state:accept('-') then
        node.operation = '-'
    elseif state:accept('!') then
        node.operation = '!'
    else
        return nil
    end

    return node
end

return { ast = unary }