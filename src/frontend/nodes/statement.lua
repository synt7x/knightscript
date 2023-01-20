local function statement(state)
    while state:accept(';') do end

    if state:test('function') then
        table.insert(state.tree, functionstat.ast(state))
    elseif state:test('if') then
        table.insert(state.tree, ifstat.ast(state))
    elseif state:test('while') then
        table.insert(state.tree, whilestat.ast(state))
    elseif state:test('for') then
        table.insert(state.tree, forstat.ast(state))
    elseif state:test('return') then
        table.insert(state.tree, returnstat.ast(state))
    elseif state:accept('break') then
        table.insert(state.tree, { type = 'break' })
    elseif state:accept('local') then
        table.insert(state.tree, localstat.ast(state))
    elseif state.token then
        table.insert(state.tree, inplace.ast(state))
    end
end

local function symbol(state, node)
    if node.type == 'function' then
        functionstat.symbol(state, node)
    else
        print('unknown statement type: ' .. node.type)
    end
end

return { ast = statement, symbol = symbol }