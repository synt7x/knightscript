function returnstat(state)
    state:expect('return')

    return {
        type = 'return',
        body = expression.ast(state)
    }
end

return { ast = returnstat }