function literal(state)
    if state:test('number') then
        return state:accept('number')
    elseif state:test('string') then
        return state:accept('string')
    elseif state:test('true') then
        return state:accept('true')
    elseif state:test('false') then
        return state:accept('false')
    elseif state:test('null') then
        return state:accept('null')
    elseif state:test('[') then
        return array.ast(state)
    elseif state:test('function') then
        return functionstat.ast(state)
    else
        return name.ast(state)
    end
end

return { ast = literal }