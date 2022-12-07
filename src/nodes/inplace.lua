local frog = require('lib/frog')

function inplace(state)
    if not state:test('identifier') and not state:test('(') then
        local node = expression.ast(state)

        if node.type ~= 'ternary' then
            frog:error('Unexpected token ' .. state.token.string .. ' in body.')
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
        node.operation = state:test('+=') or
                         state:test('-=') or
                         state:test('/=') or
                         state:test('*=') or
                         state:test('^=')
        node.type = 'inplace'
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
    end
end

return { ast = inplace }