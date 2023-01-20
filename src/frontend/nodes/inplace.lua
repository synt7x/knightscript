local frog = require('lib/frog')

function inplace(state)
    local fallback = state.token.string

    if not state:test('identifier') and not state:test('(') then
        local node = expression.ast(state)

        if node.type ~= 'ternary' then
            frog:croak('Unexpected token ' .. state.token.string .. ' in body.')
        end

        return node
    end

    local node = {
        name = name.ast(state)
    }

    if state:test('+=') or
       state:test('-=') or
       state:test('/=') or
       state:test('*=') or
       state:test('^=')
    then
        node.operation = state:accept('+=') or
                         state:accept('-=') or
                         state:accept('/=') or
                         state:accept('*=') or
                         state:accept('^=')
        node.type = 'inplace'
        node.body = expression.ast(state)
        return node
    elseif
        state:test('--') or
        state:test('++')
    then
        node.operation = state:accept('--') or state:accept('++')
        node.type = 'compound'
        return node
    elseif state:accept('=') then
        node.type = 'assignment'
        node.body = expression.ast(state)
        return node
    else
        node = node.name
        
        if not node.inplace then
            local ternary = ternary.ast(state)

            if ternary then
                ternary.name = node
                return ternary
            else
                frog:croak('Unexpected token ' .. fallback .. ' in body.')
            end
        end
    end

    return node
end

return { ast = inplace }