local frog = require('lib/frog')
local cli = require('src/cli')
local lexer = require('src/frontend/lexer')
local parser = require('src/frontend/parser')
local symbols = require('src/frontend/symbols')
local flags, inputs = cli(arg)

for i, input in ipairs(inputs) do
    local file = io.open(input, 'r')

    if file then
        local text = file:read('*a')
        file:close()

        local tokens, comments = lexer.new(text)
        frog:dump('tokens', tokens)
        frog:dump('comments', comments)

        local ast = parser.new(tokens, flags, comments)
        frog:dump('ast', ast)
        
        local symboltable = symbols.new(ast)
        frog:dump('symbols', symboltable)
    else
        frog:croak('Could not open file: ' .. input)
    end
end