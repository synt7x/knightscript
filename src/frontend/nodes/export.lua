function export(state)
    state:expect('export')

    local node = {
        type = 'export',
        value = externalname.ast(state)
    }

    while state:accept(';') do end

    return node
end

local function symbol(state)
    
end

return { ast = export, symbol = symbol }