local priority = {
    ['+'] = { 10, 10 }, ['-'] = { 10, 10 },
    ['*'] = { 11, 11 }, ['%'] = { 11, 11 },
    ['^'] = { 14, 13 },
    ['/'] = { 11, 11 },
    ['=='] = { 3, 3 },
    ['!='] = { 3, 3 },
    ['<'] = { 3, 3 }, ['>'] = { 3, 3 },
    ['<='] = { 3, 3 }, ['>='] = { 3, 3 },
    ['&&'] = { 2, 2 }, ['||'] = { 1, 1 },
    ['?'] = { 0, 0 }
}

function expression(state, limit, operation)
    limit = limit or 0
    local node = {}
    local unary = unary.ast(state)

    if unary then
        node = unary
        node.body = expression.ast(state, 12)
    else
        node = literal.ast(state)
    end

    local binary = binary.ast(state)
    while binary do
        if not priority[binary.operator] then break end
        if priority[binary.operator][1] < limit then break end

        local operation, right = expression.ast(state, priority[binary.operator][2], true)
        
        binary.right = right
        binary.left = node
        node = binary

        binary = operation
    end

    if operation then return binary, node end

    local ternary = ternary.ast(state)
    if ternary then
        ternary.condition = node
        node = ternary
    end

    return node
end

return { ast = expression }