function export(state)
    state:expect('export')

    local node = {
        type = 'export',
        value = externalname.ast(state)
    }

    while state:accept(';') do end

    return node
end

return { ast = export }