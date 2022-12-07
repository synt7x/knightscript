function statement(state)
    while state:accept(';') do end

    if state:test('function') then
        table.insert(state.tree, functionstat.ast(state))
    elseif state:test('if') then
        table.insert(state.tree, ifstat.ast(state))
    elseif state:test('while') then
        table.insert(state.tree, ifstat.ast(state))
    elseif state:test('for') then
        table.insert(state.tree, forstat.ast(state))
    elseif state.token then
        table.insert(state.tree, inplace.ast(state))
    end
end

return { ast = statement }