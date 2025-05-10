local frog = require('lib/frog')
local cli = require('src/cli')
local lexer = require('src/lexer')
local parser = require('src/parser')
local transform = require('src/transformer')
local emit = require('src/emit')

local flags, inputs = cli(arg)

for i, input in ipairs(inputs) do
    local file = io.open(input, 'r')

    if file then
        frog.file = input
        local text = file:read('*a')
        file:close()

        local tokens, comments = lexer.new(text)
        frog:dump('tokens', tokens)
        frog:dump('comments', comments)

        local ast, symbols = parser.new(flags, tokens, comments)
        frog:dump('pre', ast)
        frog:dump('ast', transform(ast, symbols))

        frog:dump('knight', emit.new(ast, flags))
    else
        frog:croak('Could not open file: ' .. input)
    end
end