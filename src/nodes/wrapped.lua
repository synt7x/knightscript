local expression = require('src/nodes/expression')

function wrapped(state)
    if state:accept('(') then
        local expr = expression.ast(state)
        state:expect(')')

        return expr
    else
        return state:expect('identifier')
    end
end

return { ast = wrapped }