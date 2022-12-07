array = require('src/nodes/array')
binary = require('src/nodes/binary')
export = require('src/nodes/export')
expression = require('src/nodes/expression')
externalname = require('src/nodes/externalname')
forstat = require('src/nodes/for')
functionstat = require('src/nodes/function')
ifstat = require('src/nodes/if')
import = require('src/nodes/import')
literal = require('src/nodes/literal')
name = require('src/nodes/name')
namelist = require('src/nodes/namelist')
statement = require('src/nodes/statement')
ternary = require('src/nodes/ternary')
unary = require('src/nodes/unary')
whilestat = require('src/nodes/while')
wrapped = require('src/nodes/wrapped')

local frog = require('lib/frog')

function program(state)
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

return { ast = program }