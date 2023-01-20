array = require('src/frontend/nodes/array')
binary = require('src/frontend/nodes/binary')
export = require('src/frontend/nodes/export')
expression = require('src/frontend/nodes/expression')
externalname = require('src/frontend/nodes/externalname')
forstat = require('src/frontend/nodes/for')
functionstat = require('src/frontend/nodes/function')
ifstat = require('src/frontend/nodes/if')
import = require('src/frontend/nodes/import')
inplace = require('src/frontend/nodes/inplace')
literal = require('src/frontend/nodes/literal')
localstat = require('src/frontend/nodes/local')
name = require('src/frontend/nodes/name')
namelist = require('src/frontend/nodes/namelist')
returnstat = require('src/frontend/nodes/return')
statement = require('src/frontend/nodes/statement')
ternary = require('src/frontend/nodes/ternary')
unary = require('src/frontend/nodes/unary')
whilestat = require('src/frontend/nodes/while')
wrapped = require('src/frontend/nodes/wrapped')

local frog = require('lib/frog')

local function program(state)
    state:enter(state.tree, state.tree.body)

    while state:test('import') do
        table.insert(state.tree, import.ast(state))
    end

    while state.token do
        if state:test('export') then
            break
        end

        statement.ast(state)
    end

    while state:test('export') do
        table.insert(state.tree, export.ast(state))
    end

    while state.token do
        frog:croak('Unexpected token: ' .. state:skip().type)
    end

    state:exit()

    return state.tree
end

local function symbol(state)
    state:initializelocals(state)

    for i = #state.body, 1, -1 do
        if state.body[i].type == 'import' then
            import.symbol(state, state.body[i])
        elseif state.body[i].type == 'export' then
            export.symbol(state, state.body[i])
        else
            statement.symbol(state, state.body[i])
        end
    end
end

return { ast = program, symbol = symbol }