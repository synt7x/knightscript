local json = require('lib/json')
local parser = require('src/parser')
local traversal = parser.traversal

local function null()
    return {
        type = 'null'
    }
end

local function builtin(node)
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
            right = node.args[1] or null(),
            left = {
                type = 'string',
                value = '\\'
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
        local name = node.args[1] or null()
        local index = node.args[2] or null()
        local value = node.args[3] or null()

        local placeholder = {
            type = 'identifier',
            characters = '_'
        }

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
                width = placeholder
            }
        }
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
        walk(node.value)
    elseif node.type == 'call' then
        if node.name.type == 'identifier' then
            builtin(node)
        else
            walk(node.name)
        end
    elseif node.type == 'block' then
        walk(node.body)
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
    elseif node.type == 'index' then
        local name = node.name
        local index = node.value

        local placeholder = {
            type = 'identifier',
            characters = '_'
        }

        node.type = 'expr'
        node.left = {
            type = 'assignment',
            name = placeholder,
            value = index
        }
        node.right = {
            type = 'get',
            argument = name,
            start = placeholder,
            width = {
                type = 'if',
                condition = {
                    type = 'exact',
                    left = name,
                    right = {
                        type = 'number',
                        characters = '0'
                    }
                },
                body = placeholder,
                fallback = {
                    type = 'number',
                    characters = '1'
                }
            }
        }

        node.name = nil
        node.value = nil
    elseif node.type == 'array' then
        array(node)
    end

    return node
end

local function transform(ast)
    ast.body = walk(ast.body)
    return ast
end

return transform