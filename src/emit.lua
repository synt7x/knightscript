local emit = {}

local json = require('lib/json')
local parser = require('src/parser')
local traversal = parser.traversal

function emit.new(ast)
    local self = {}
    for name, value in pairs(emit) do
        self[name] = value
    end

    self.buffer = ''
    self.node = ast.body

    self:walk(self.node)

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

function emit:builtin(characters)
    if self.last then
        --self:build(' ')
    end

    self:build(characters)
        
    self.last = 'builtin'
end

function emit:variable(characters)
    if self.last then
        --self:build(' ')
    end

    self:build(characters)
        
    self.last = 'variable'
end

function emit:string(characters, delimiter)
    if self.last then
        --self:build(' ')
    end

    self:build(delimiter or '"')
    self:build(characters)
    self:build(delimiter or '"')

    self.last = 'string'
end

function emit:operator(characters)
    if self.last and characters ~= ';' then
        --self:build(' ')
    end

    self:build(characters)
        
    self.last = 'operator'
end

function emit:number(characters)
    if self.last == 'variable' then
        self:build(' ')
    end

    self:build(characters)
    self.last = 'number'
end

function emit:walk(ast)
    self.node = ast

    if traversal.binary[ast.type] then
        self:operator(traversal.binary[ast.type])
        self:walk(ast.left)

        if ast.type == 'expr' then
            self:build('\n')

            if ast.right.type ~= 'expr' then
                self:build(':')
            end
        end
        
        self:walk(ast.right)
    elseif self:test('output') then
        self:builtin('OUTPUT')
        self:walk(ast.argument)
    elseif self:test('output') then
        self:builtin('DUMP')
        self:walk(ast.argument)
    elseif self:test('prompt') then
        self:builtin('PROMPT')
    elseif self:test('random') then
        self:builtin('RANDOM')
    elseif traversal.unary[ast.type] then
        self:operator(traversal.unary[ast.type])
        self:walk(ast.argument)
    elseif self:test('block') then
        self:builtin('BLOCK')
        self:walk(ast.body)
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
        self:walk(ast.body)
    elseif self:test('if') then
        self:builtin('IF')
        self:walk(ast.condition)
        self:walk(ast.body)
        self:walk(ast.fallback)
    elseif self:test('identifier') then
        self:variable(ast.characters)
    elseif self:test('string') then
        self:string(ast.characters, ast.delimiter)
    elseif self:test('number') then
        self:number(ast.characters)
    elseif self:test('array') then
        self:operator('@')
    else
        print(ast.type)
    end
end

local format = {}
function format:build(ast)
    if traversal.binary[ast.type] then
        if ast.type == 'expr' then
            self.buffer = self.buffer .. '\n'
        end
        self:emit(traversal.binary[ast.type])
        self:build(ast.left)

        print(json(ast))

        self:build(ast.right)
    elseif ast.type == 'prime' then
        self:emit('[')
        self:build(ast.argument)
    elseif ast.type == 'ultimate' then
        self:emit(']')
        self:build(ast.argument)
    elseif traversal.unary[ast.type] then
        self:emit(traversal.unary[ast.type])
        self:build(ast.argument)
    elseif ast.type == 'identifier' then
        local name = ast.characters
        self:emit(name)
    elseif ast.type == 'assignment' then
        self:emit('=')
        self:build(ast.name)
        self:build(ast.value)
    elseif ast.type == 'block' then
        self:emit('BLOCK')
        self:build(ast.body)
    elseif ast.type == 'call' then
        self:emit('CALL')
        self:build(ast.name)
    elseif ast.type == 'if' then
        self:emit('IF')
        self:build(ast.condition)
        self:build(ast.body)
        self:build(ast.fallback)
    elseif ast.type == 'while' then
        self:emit('WHILE')
        self:build(ast.condition)
        self:build(ast.body)
    elseif ast.type == 'get' then
        self:emit('GET')
        self:build(ast.start)
        self:build(ast.width)
        self:build(ast.argument)
    elseif ast.type == 'set' then
        self:emit('SET')
        self:build(ast.start)
        self:build(ast.width)
        self:build(ast.value)
		self:build(ast.argument)
    elseif ast.type == 'string' then
        self:emit('"' .. ast.characters .. '"')
    elseif ast.type == 'number' then
        self:emit(ast.characters)
    elseif ast.type == 'null' then
        self:emit('NULL')
    elseif ast.type == 'boolean' then
        if ast.value then
            self:emit('TRUE')
        else
            self:emit('FALSE')
        end
    elseif ast.type == 'list' then
        self:emit('@')
    else
        frog:throw(
            ast.token,
            string.format('Panic during format, recieved unknown node of type %s', ast.type),
            'Please report this as a bug in the issue tracker (https://github.com/synt7x/knightc/issues/new)',
            'Fatal'
        )

        os.exit(1)
    end
end

return emit