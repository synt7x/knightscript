function statement(state)
    state:accept(';')

    if state:test('function') then
        table.insert(state.tree, functionstat.ast(state))
    elseif state:test('if') then
        table.insert(state.tree, ifstat.ast(state))
    elseif state:test('while') then
        table.insert(state.tree, ifstat.ast(state))
    elseif state:test('for') then
        table.insert(state.tree, forstat.ast(state))
    else
        os.exit(1)
    end
end

return { ast = statement }