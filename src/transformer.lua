local json = require('lib/json')
local parser = require('src/parser')
local traversal = parser.traversal

local symbols = {}
local void = {
    type = 'identifier',
    characters = '_'
}

local function get_unique(symbols, index)
    if not index then
        if not symbols['_'] then
            return '_'
        elseif not symbols['v'] then
            return 'v'
        elseif not symbols['void'] then
            return 'void'
        end
    end

    local n = 0
    local identifier = '_'

    while symbols[identifier] do
        identifier = '_' .. n
        n = n + 1
    end

    if index then
        identifier = '_' .. '_' .. index
    else
        return identifier
    end

    n = 0

    while symbols[identifier] do
        identifier = '_' .. n .. '_' .. index
        n = n + 1
    end

    return identifier
end

function rename(ast, identifier, target)
    if traversal.binary[ast.type] then
        rename(ast.left, identifier, target)
        rename(ast.right, identifier, target)
    elseif traversal.unary[ast.type] then
        rename(ast.argument, identifier, target)
    elseif ast.type == 'block' then
        rename(ast.body, identifier, target)
    elseif ast.type == 'call' then
        rename(ast.name, identifier, target)
    elseif ast.type == 'assignment' then
        rename(ast.name, identifier, target)
        rename(ast.value, identifier, target)
    elseif ast.type == 'while' then
        rename(ast.condition, identifier, target)
        rename(ast.body, identifier, target)
    elseif ast.type == 'if' then
        rename(ast.condition, identifier, target)
        rename(ast.body, identifier, target)
        rename(ast.fallback, identifier, target)
    elseif ast.type == 'get' then
        rename(ast.argument, identifier, target)
        rename(ast.start, identifier, target)
        rename(ast.width, identifier, target)
    elseif ast.type == 'set' then
        rename(ast.argument, identifier, target)
        rename(ast.start, identifier, target)
        rename(ast.width, identifier, target)
        rename(ast.value, identifier, target)
    elseif ast.type == 'identifier' then
        if ast.characters == identifier.characters then
            ast.characters = target
        end
    end
end

local function null()
    return {
        type = 'null'
    }
end

local function builtin(node)
    local placeholder = void

    local identifier = node.name.characters
    if identifier == 'print' then
        node.type = 'output'
        walk(node.args[1])
        node.argument = node.args[1] or null()
        
        node.name = nil
        node.args = nil
    elseif identifier == 'dump' then
        node.type = 'dump'
        walk(node.args[1])
        node.argument = node.args[1] or null()
            
        node.name = nil
        node.args = nil
    elseif identifier == 'write' then
        node.type = 'output'
        walk(node.args[1])
        node.argument = {
            type = 'add',
            left = node.args[1] or null(),
            right = {
                type = 'string',
                characters = '\\'
            }
        }

        node.name = nil
        node.args = nil
    elseif identifier == 'insert' then
        node.type = 'assignment'
        walk(node.args[1])
        walk(node.args[2])

        node.value = {
            type = 'add',
            left = node.args[1] or null(),
            right = {
                type = 'box',
                argument = node.args[2] or null()
            }
        }

        node.name = node.args[1] or null()
        node.args = nil
    elseif identifier == 'set' then
        walk(node.args[1])
        walk(node.args[2])
        walk(node.args[3])

        local name = node.args[1] or null()
        local index = node.args[2] or null()
        local value = node.args[3] or null()

        node.type = 'expr'
        node.left = {
            type = 'assignment',
            name = placeholder,
            value = index
        }

        node.right = {
            type = 'assignment',
            name = name,
            value = {
                type = 'set',
                argument = name,
                value = {
                    type = 'box',
                    argument = value
                },
                start = placeholder,
                width = {
                    type = 'number',
                    characters = '1'
                }
            }
        }

        node.args = nil
        node.name = nil
    elseif identifier == 'join' then
        node.type = 'exponent'

        walk(node.args[1])
        walk(node.args[2])

        node.left = node.args[1] or null()
        node.right = node.args[2] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'length' then
        node.type = 'length'
        walk(node.args[1])
        node.argument = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'quit' then
        node.type = 'quit'
        walk(node.args[1])
        node.argument = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'ascii' then
        node.type = 'ascii'
        walk(node.args[1])
        node.argument = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'tail' then
        node.type = 'ultimate'
        walk(node.args[1])
        node.argument = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'head' then
        node.type = 'prime'
        walk(node.args[1])
        node.argument = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'push' then
        walk(node.args[1])
        walk(node.args[2])

        local name = node.args[1] or null()
        local value = node.args[2] or null()

        node.type = 'assignment'

        node.name = name
        node.value = {
            type = 'add',
            left = {
                type = 'box',
                argument = value
            },
            right = name
        }

        node.args = nil
    elseif identifier == 'pop' then
        walk(node.args[1])

        local name = node.args[1] or null()
        node.type = 'expr'

        node.left = {
            type = 'assignment',
            name = placeholder,
            value = {
                type = 'prime',
                argument = name
            }
        }

        node.right = {
            type = 'expr',
            left = {
                type = 'assignment',
                name = name,
                value = {
                    type = 'ultimate',
                    argument = name
                }
            },
            right = placeholder
        }

        node.name = nil
        node.args = nil
    elseif identifier == 'read' then
        node.type = 'prompt'
        node.name = nil
        node.args = nil
    elseif identifier == 'prompt' then
        node.type = 'expr'
        walk(node.args[1])
        node.left = {
            type = 'output',
            argument = {
                type = 'add',
                left = node.args[1] or null(),
                right = {
                    type = 'string',
                    characters = ' \\'
                }
            }
        }

        node.right = {
            type = 'prompt'
        }

        node.name = nil
        node.args = nil
    elseif identifier == 'string' then
        node.type = 'add'
        node.left = {
            type = 'string',
            characters = ''
        }

        walk(node.args[1])
        node.right = node.args[1] or null()

        node.name = nil
        node.args = nil
    elseif identifier == 'number' then
        node.type = 'add'
        node.left = {
            type = 'number',
            characters = '0'
        }

        walk(node.args[1])
        node.right = node.args[1] or null()
        
        node.name = nil
        node.args = nil
    end

    return node
end

local function array(node)
    if #node.elements == 1 then
        walk(node.elements[1])

        node.type = 'box'
        node.argument = node.elements[1]
    elseif #node.elements > 1 then
        node.type = 'add'

        local element = node
        
        for i = 1, #node.elements do
            walk(node.elements[i])

            element.left = {
                type = 'box',
                argument = node.elements[i]
            }

            if i == #node.elements - 1 then
                walk(node.elements[i + 1])
                element.right = {
                    type = 'box',
                    argument = node.elements[i + 1]
                }

                break
            end

            element.right = {
                type = 'add'
            }

            element = element.right
        end
    end

    node.elements = nil
end

function walk(node)
    if not node then return end
    local placeholder = void

    if node.type == 'expr' then
        if not node.right then
            local left = node.left

            node.left = nil
            node.right = nil

            for k, v in pairs(left) do
                node[k] = v
            end

            walk(node)

            return node
        end

        walk(node.left)
        walk(node.right)
    elseif traversal.binary[node.type] then
        walk(node.left)
        walk(node.right)
    elseif traversal.unary[node.type] then
        walk(node.argument)
    elseif node.type == 'assignment' then
        walk(node.name)
        walk(node.value)
    elseif node.type == 'call' then
        if node.name.type == 'identifier' then
            builtin(node)
        else
            walk(node.name)
        end

        if node.args and #node.args > 0 then
            local name = node.name
            node.name = nil

            for i, arg in ipairs(node.args) do
                walk(arg)

                node.type = 'expr'
                node.left = {
                    type = 'assignment',
                    name = {
                        type = 'identifier',
                        characters = get_unique(symbols, i)
                    },
                    value = arg
                }

                node.right = {
                    type = 'call'
                }

                node = node.right
            end

            node.name = name
        end
    elseif node.type == 'block' then
        walk(node.body)
        for i, arg in ipairs(node.args) do
            local name = get_unique(symbols, i)
            rename(node.body, arg, name)
        end
    elseif node.type == 'while' then
        walk(node.condition)
        walk(node.body)
    elseif node.type == 'if' then
        walk(node.condition)
        walk(node.body)
        walk(node.fallback)
    elseif node.type == 'get' then
        walk(node.argument)
        walk(node.start)
        walk(node.width)
    elseif node.type == 'set' then
        walk(node.argument)
        walk(node.start)
        walk(node.width)
        walk(node.value)
    elseif node.type == 'index' then
        walk(node.name)
        walk(node.value)

        local name = node.name
        local index = node.value

        node.type = 'prime'
        node.argument = {
            type = 'get',
            argument = name,
            start = index,
            width = {
                type = 'number',
                characters = '1'
            }
        }

        node.name = nil
        node.value = nil
    elseif node.type == 'array' then
        array(node)
    end

    return node
end

local function transform(ast, st)
    symbols = st
    void.characters = get_unique(symbols)

    ast.body = walk(ast.body)
    return ast
end

return transform