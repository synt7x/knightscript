function binary(state)
    local expression = {
        type = 'binary'
    }

    if state:accept('+') then
        expression.operator = '+'
    elseif state:accept('-') then
        expression.operator = '-'
    elseif state:accept('*') then
        expression.operator = '*'
    elseif state:accept('/') then
        expression.operator = '/'
    elseif state:accept('%') then
        expression.operator = '%'
    elseif state:accept('^') then
        expression.operator = '^'
    elseif state:accept('==') then
        expression.operator = '=='
    elseif state:accept('!=') then
        expression.operator = '!='
    elseif state:accept('<=') then
        expression.operator = '<='
    elseif state:accept('>=') then
        expression.operator = '>='
    elseif state:accept('<') then
        expression.operator = '<'
    elseif state:accept('>') then
        expression.operator = '>'
    elseif state:accept('&&') then
        expression.operator = '&&'
    elseif state:accept('||') then
        expression.operator = '||'
    else
        return nil
    end

    return expression
end

return { ast = binary }