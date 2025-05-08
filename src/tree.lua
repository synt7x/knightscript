local frog = require('lib/frog')
local json = require('lib/json')

local function null_expr(state)
    return {
        type = 'null'
    }
end

local function unary_expr(state)
    if state:test('!') then
        -- Consume the '!' token
        state:accept('!')
        return function(v)
            return {
                type = 'not',
                argument = v
            }
        end
    elseif state:test('-') then
        -- Consume the '-' token
        state:accept('-')
        return function(v)
            return {
                type = 'negate',
                argument = v
            }
        end
    end
end

local function binary_expr(state)
    if state:test('==') then
        -- Consume the '==' token
        state:accept('==')
        return function(r, l)
            return {
                type = 'exact',
                left = r,
                right = l,
            }
        end, 3
    elseif state:test('!=') then
        -- Consume the '!=' token
        state:accept('!=')
        return function(r, l)
            return {
                type = 'not',
                argument = {
                    type = 'exact',
                    left = r,
                    right = l,
                }
            }
        end, 3
    elseif state:test('<') then
        -- Consume the '<' token
        state:accept('<')
        return function(r, l)
            return {
                type = 'less',
                left = r,
                right = l,
            }
        end, 3
    elseif state:test('<=') then
        -- Consume the '<=' token
        state:accept('<=')
        return function(r, l)
            return 
        end, 3
    elseif state:test('>') then
        -- Consume the '>' token
        state:accept('>')
        return function(r, l)
            return {
                type = 'greater',
                left = r,
                right = l,
            }
        end, 3
    elseif state:test('>=') then
        -- Consume the '>=' token
        state:accept('>=')
        return function(r, l)
        end, 3
    elseif state:test('&&') then
        -- Consume the '&&' token
        state:accept('&&')
        return function(r, l)
            return {
                type = 'and',
                left = r,
                right = l,
            }
        end, 2
    elseif state:test('||') then
        -- Consume the '||' token
        state:accept('||')
        return function(r, l)
            return {
                type = 'or',
                left = r,
                right = l,
            }
        end, 1
    elseif state:test('+') then
        -- Consume the '+' token
        state:accept('+')
        return function(r, l)
            return {
                type = 'add',
                left = r,
                right = l,
            }
        end, 10
    elseif state:test('-') then
        -- Consume the '-' token
        state:accept('-')
        return function(r, l)
            return {
                type = 'subtract',
                left = r,
                right = l,
            }
        end, 10
    elseif state:test('*') then
        -- Consume the '*' token
        state:accept('*')
        return function(r, l)
            return {
                type = 'multiply',
                left = r,
                right = l,
            }
        end, 11
    elseif state:test('/') then
        -- Consume the '/' token
        state:accept('/')
        return function(r, l)
            return {
                type = 'divide',
                left = r,
                right = l,
            }
        end, 11
    elseif state:test('%') then
        -- Consume the '%' token
        state:accept('%')
        return function(r, l)
            return {
                type = 'modulus',
                left = r,
                right = l,
            }
        end, 11
    elseif state:test('^') then
        -- Consume the '^' token
        state:accept('^')
        return function(r, l)
            return {
                type = 'exponent',
                left = r,
                right = l,
            }
        end, 14
    end
end

local function expression_stat(state)
    local node = index_expr(state)

    if state:test('=') then
        if not node or node.type ~= 'identifier' then
            frog:throw(
                state.token,
                'Invalid assignment, the left side of the assignment must be an identifier',
                node.type == 'index' and 'You probably intended to use the set(array, index, value) function' or 'Try replacing the left side with an identifier',
                'Parser'
            )

            os.exit(1)
        end

        -- Consume the '=' token
        state:accept('=')

        -- Create a new node for the assignment
        local assignment_node = {
            type = 'assignment',
            name = node,
        }

        -- Get the value of the assignment
        assignment_node.value = expression(state)
        return assignment_node
    end

    return node
end

local function array(state)
    -- Accept the '[' token
    state:expect('[')

    local node = {
        type = 'array',
        elements = {}
    }

    if state:accept(']') then
        return node
    end

    repeat
        table.insert(node.elements, expression(state))
    until not state:accept(',')

    state:expect(']')
    return node
end

local function literal(state)
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
        return array(state)
    else
        return index_expr(state)
    end
end

local function arity_expr(limit, state, precede)
    local result = {}
    local unary = unary_expr(state)

    if unary then
        result = unary(expression(state))
    else
        result = literal(state)
    end

    local binary, precedence = binary_expr(state)
    -- binary returns a local function that takes two arguments and returns the AST node

    while binary do
        if not precedence then break end
        if precedence < limit then break end

        local operand, value = arity_expr(precedence, state, true)
        result = binary(result, value)
        binary = operand
    end

    if precede then
        return binary, result
    end

    return result
end

function expression(state)
    return arity_expr(0, state, false)
end

function index_expr(state)
    local identifier = identifier_expr(state)

    local level

    while state:test('[') or state:test('(') do
        if state:test('[') then
            -- Consume the '[' token
            state:accept('[')

            -- Get the index expression
            local index = expression(state)

            if not level then
                level = {
                    type = 'index',
                    name = identifier,
                    value = index,
                }
            else
                level = {
                    type = 'index',
                    name = level,
                    value = index,
                }
            end

            -- Consume the ']' token
            state:expect(']')
        elseif state:test('(') then
            -- Consume the '(' token
            state:accept('(')

            -- Get the arguments of the local function call
            local args = {}

            while not state:test(')') do
                local arg = expression(state)
                table.insert(args, arg)

                if not state:accept(',') then
                    break
                end
            end

            -- Consume the ')' token
            state:expect(')')

            if not level then
                level = {
                    type = 'call',
                    name = identifier,
                    args = args,
                }
            else
                level = {
                    type = 'call',
                    name = level,
                    args = args,
                }
            end
        end
    end

    return level or identifier
end

function identifier_expr(state)
    if state:accept('(') then
        local expr = arity_expr(state, 0)
        state:expect(')')
        return expr
    elseif state:test('identifier') then
        return state:expect('identifier')
    end
end

-- Handle if statements
local function if_expr(state)
    -- Consume the 'if' token
    state:accept('if')

    -- Create a new node for the if statement
    local node = {
        type = 'if',
    }

    -- Get the condition of the if statement
    state:expect('(')
    node.condition = expression(state)
    state:expect(')')

    -- Get the body of the if statement
    state:expect('{')
    node.body = statement(state)
    state:expect('}')

    -- Check for elseif or else statements
    if state:test('elseif') then
        node.fallback = elseif_expr(state) or null_expr(state)
    elseif state:test('else') then
        node.fallback = else_expr(state) or null_expr(state)
    else
        node.fallback = null_expr(state)
    end

    return node
end

local function elseif_expr(state)
    -- Consume the 'elseif' token
    state:accept('elseif')

    -- Create a new node for the elseif statement
    local node = {
        type = 'if',
    }

    -- Get the condition of the elseif statement
    state:expect('(')
    node.condition = expression(state)
    state:expect(')')

    -- Get the body of the elseif statement
    state:expect('{')
    node.body = statement(state)
    state:expect('}')

    -- Check for else statements
    if state:test('else') then
        node.fallback = else_expr(state) or null_expr(state)
    end

    return node
end

local function else_expr(state)
    -- Consume the 'else' token
    state:accept('else')

    -- Create a new node for the else statement
    local node

    -- Get the body of the else statement
    state:expect('{')
    node = statement(state)
    state:expect('}')

    return node
end

local function while_expr(state)
    -- Consume the 'while' token
    state:accept('while')

    -- Create a new node for the while statement
    local node = {
        type = 'while',
    }

    -- Get the condition of the while statement
    state:expect('(')
    node.condition = expression(state)
    state:expect(')')

    -- Get the body of the while statement
    state:expect('{')
    
    if state:test('}') then
        node.body = null_expr(state)
    else
        node.body = statement(state)
    end

    state:expect('}')

    return node
end

local function for_condition(state)
    -- Get the identifier of the iterator
    local identifier = state:expect('identifier')

    -- Create a new node for the for condition
    local initial_node = {
        type = 'assignment',
        name = identifier,
    }

    if state:test('in') then
        -- Consume the 'in' token
        state:accept('in')

        local length_node = {
            type = 'length',
            value = expression(state),
        }

        local condition_node = {
            type = 'less',
            left = identifier,
            right = length_node,
        }

        local number = {
            type = 'number',
            value = 0,
        }

        initial_node.value = number
        return initial_node, condition_node
    elseif state:expect('=') then
        -- Consume the '=' token
        state:accept('=')

        initial_node.value = expression(state)
        
        state:expect(',')

        local condition_node = {
            type = 'less',
            left = identifier,
            right = {
                type = 'add',
                left = expression(state),
                right = {
                    type = 'number',
                    characters = '1'
                }
            }
        }

        local follow_node = {}

        if state:accept(',') then
            follow_node = {
                    type = 'assignment',
                    name = identifier,
                    value = {
                        type = 'add',
                        left = identifier,
                        right = expression(state)
                    }
                }
        else
            follow_node = {
                    type = 'assignment',
                    name = identifier,
                    value = {
                        type = 'add',
                        left = identifier,
                        right = {
                            type = 'number',
                            characters = '1'
                        }
                    }
            }
        end


        return initial_node, condition_node, follow_node
    end
end

local function for_expr(state)
    -- Consume the 'for' token
    state:accept('for')

    -- Create a new node for the for statement
    local node = {
        type = 'expr',
    }

    -- Create the 'while' part of the for statement
    local loop_node = {
        type = 'while',
    }

    node.right = loop_node

    -- Get the body of the for statement
    state:expect('(')
    local initial, condition, follow = for_condition(state)
    node.left = initial
    loop_node.condition = condition
    state:expect(')')

    -- Get the body of the for statement
    state:expect('{')
    local body = statement(state)
    
    if body then
        loop_node.body = {
            type = 'expr',
            left = body,
            right = follow
        }
    else
        loop_node.body = follow
    end

    state:expect('}')

    return node
end

local function function_expr(state)
    -- Consume the 'function' token
    state:accept('function')

    -- Create the assignment node for the function
    local node = {
        type = 'assignment',
        name = state:expect('identifier'),
    }

    -- Get the arguments of the function
    state:expect('(')

    local args = {}

    while state:test('identifier') do
        local arg = state:expect('identifier')
        table.insert(args, arg)
        if not state:test(',') then
            break
        end
        state:accept(',')
    end

    state:expect(')')
    state:expect('{')

    -- Create the body node for the function
    local block = {
        type = 'block',
        args = args,
    }

    block.body = statement(state) or null_expr()
    state:expect('}')

    node.value = block
    return node
end

local function return_expr(state)
    -- Consume the 'return' token
    state:accept('return')

    -- In Knight, the return statement is the last expression
    return expression(state)
end

local function break_expr(state)
    -- TODO: Add expression to the 'while' and 'for' nodes as an additional condition
    -- TODO: In the symbol resolver, remove the break condition if it is not in the loop
end

local function export_expr(state)
    -- TODO: Add export statement
    state:accept('export')
    return expression(state)
end

local function import_expr(state)
    -- TODO: Add import statement
    state:accept('import')

    local node = {
        type = 'import'
    }

    if state:test('identifier') then
        node.value = state:accept('identifier')
    else
        node.value = array(state)
    end

    state:expect('from')

    node.file = state:expect('string')

    return node
end

local function local_expr(state)
    -- Consume the 'local' token
    state:accept('local')

    -- Create a new node for the local statement
    local node = {
        type = 'assignment',
        name = state:expect('identifier'),
        scoped = true,
    }

    -- Get the value of the local statement
    state:expect('=')
    node.value = expression(state)

    return node
end

local function const_expr(state)
    -- Consume the 'const' token
    state:accept('const')

    -- Create a new node for the const statement
    local node = {
        type = 'assignment',
        name = state:expect('identifier'),
        scoped = true,
    }

    -- Get the value of the const statement
    state:expect('=')
    node.value = expression(state)

    return node
end

function statement(state)
    -- Get the current token from the state variable
    local token = state.token

    -- Try to fit all tokens into a binary expression
    if not token or state:test('}') or state:test(')') then
        -- No token found, just return nil
        return

        -- Will result in a node with the structure
        -- { ... left = { ... } right = nil }
        -- This can be compressed into a single node
    end

    -- All elements are binary expressions
    local node = {
        type = 'expr',
    }

    -- Get the node of the left side of the expression
    if state:test('if') then
        node.left = if_expr(state)
    elseif state:test('while') then
        node.left = while_expr(state)
    elseif state:test('for') then
        node.left = for_expr(state)
    elseif state:test('function') then
        node.left = function_expr(state)
    elseif state:test('return') then
        node.left = return_expr(state)
        return node
    elseif state:test('break') then
        node.left = break_expr(state)
    elseif state:test('export') then
        node.left = export_expr(state)
        return node
    elseif state:test('import') then
        node.left = import_expr(state)
    elseif state:test('local') then
        node.left = local_expr(state)
    elseif state:test('const') then
        node.left = const_expr(state)
    else
        node.left = expression_stat(state) 
    end

    -- The right side of the expression is another expression
    node.right = statement(state)
    return node
end

return statement