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

local function symbol(state, node)
    for i, name in ipairs(node.value) do
        state:definition(name)
    end
end

return { ast = import, symbol = symbol }