function externalname(state)
    local node

    if state:accept('[') then
        node = namelist.ast(state)
        state:expect(']')
    else
        node = { state:expect('identifier') }
    end

    return node
end

return { ast = externalname }