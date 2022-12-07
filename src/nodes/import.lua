function import(state)
    state:expect('import')

    local node = {
        type = 'import',
        value = externalname.ast(state)
    }

    state:expect('from')
    node.file = state:expect('string')

    while state:accept(';') do end

    return node
end

return { ast = import }