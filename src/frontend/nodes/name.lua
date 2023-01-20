function name(state)
    local node = wrapped.ast(state)
    local body = node

    while state:test('(') or state:test('[') do
        if state:accept('(') then
            body.call = {
                type = 'call',
                arguments = {}
            }

            if not state:test(')') then
                repeat
                    table.insert(body.call.arguments, expression.ast(state))
                until not state:accept(',')
            end

            body = body.call
            state:expect(')')

            node.inplace = true
        else
            state:expect('[')
            body.index = {
                type = 'index',
                index = expression.ast(state)
            }

            body = body.index
            state:expect(']')

            node.inplace = nil
        end
    end

    return node
end

return { ast = name }