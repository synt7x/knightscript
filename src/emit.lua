local emit = {}

local json = require('lib/json')
local parser = require('src/parser')
local traversal = parser.traversal

function emit.new(ast, flags)
    local self = {}
    for name, value in pairs(emit) do
        self[name] = value
    end

    self.buffer = ''
    self.node = ast.body
    self.tabs = 0

    self.minify = flags.m

    self:walk(self.node, true)

    return self.buffer
end

function emit:test(type)
    if self.node.type == type then
        return true
    end
end

function emit:build(characters)
    self.buffer = self.buffer .. characters
end

function emit:indent()
    self.tabs = self.tabs + 1
end

function emit:dedent()
    self.tabs = self.tabs - 1
end

function emit:line()
    if not self.minify then
        self:build('\n')
        self:build(string.rep('\t', self.tabs))
    end
end

function emit:space()
    self:build(' ')
end

function emit:builtin(characters)
    if self.last == 'builtin' or not self.minify then
        self:space()
    end

    if not self.minify then
        self:build(characters)
    else
        self:build(characters:sub(1, 1))
    end
        
    self.last = 'builtin'
end

function emit:variable(characters)
    if self.last == 'variable' or not self.minify then
        self:space()
    end

    self:build(characters)
        
    self.last = 'variable'
end

function emit:string(characters, delimiter)
    if not self.minify then
        self:space()
    end

    self:build(delimiter or '"')
    self:build(characters)
    self:build(delimiter or '"')

    self.last = 'string'
end

function emit:operator(characters)
    if self.last and not self.minify and characters ~= ';' then
        self:space()
    end

    self:build(characters)
        
    self.last = 'operator'
end

function emit:number(characters)
    if self.last == 'variable' or self.last == 'number' or not self.minify then
        self:space()
    end

    self:build(characters)
    self.last = 'number'
end

function emit:walk(ast, root)
    self.node = ast

    if traversal.binary[ast.type] then
        if ast.type == 'expr' and not root then
            if ast.left.type ~= 'expr' then
                self:line()
            end
        end

        self:operator(traversal.binary[ast.type])
        self:walk(ast.left)
        self:walk(ast.right)
    elseif self:test('output') then
        self:builtin('OUTPUT')
        self:walk(ast.argument)
    elseif self:test('dump') then
        self:builtin('DUMP')
        self:walk(ast.argument)
    elseif self:test('prompt') then
        self:builtin('PROMP')
    elseif self:test('random') then
        self:builtin('RANDOM')
    elseif traversal.unary[ast.type] then
        self:operator(traversal.unary[ast.type])
        self:walk(ast.argument)
    elseif self:test('block') then
        self:builtin('BLOCK')
        self:indent()
        self:walk(ast.body)
        self:dedent()
    elseif self:test('call') then
        self:builtin('CALL')
        self:walk(ast.name)
    elseif self:test('assignment') then
        self:operator('=')
        self:walk(ast.name)
        self:walk(ast.value)
    elseif self:test('while') then
        self:builtin('WHILE')
        self:walk(ast.condition)
        self:indent()
        self:walk(ast.body)
        self:dedent()
    elseif self:test('if') then
        self:builtin('IF')
        self:walk(ast.condition)
        self:indent()
        self:walk(ast.body)
        self:walk(ast.fallback)
        self:dedent()
    elseif self:test('get') then
        self:builtin('GET')
        self:walk(ast.argument)
        self:walk(ast.start)
        self:walk(ast.width)
    elseif self:test('set') then
        self:builtin('SET')
        self:walk(ast.argument)
        self:walk(ast.start)
        self:walk(ast.width)
        self:walk(ast.value)
    elseif self:test('identifier') then
        self:variable(ast.characters)
    elseif self:test('string') then
        self:string(ast.characters, ast.delimiter)
    elseif self:test('number') then
        self:number(ast.characters)
    elseif self:test('array') then
        self:operator('@')
    elseif self:test('null') then
        self:builtin('NULL')
    elseif self:test('true') then
        self:builtin('TRUE')
    elseif self:test('false') then
        self:builtin('FALSE')
    else
        print(ast.type)
    end
end

return emit