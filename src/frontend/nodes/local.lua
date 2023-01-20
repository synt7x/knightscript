function localstat(state)
    local node = {
        ['local'] = true,
        ['name'] = name.ast(state)
    }

    state:expect('=')
    
    node.type = 'assignment'
    node.body = expression.ast(state)
    
    return node
end

return { ast = localstat }