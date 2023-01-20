function namelist(state)
    local node = {}

    repeat
        table.insert(node, state:expect('identifier'))
    until not state:accept(',')

    return node
end

return { ast = namelist }