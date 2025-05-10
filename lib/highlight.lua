local symbols = {
    ['!'] = '!', [','] = ',', ['['] = '[', [']'] = ']',
    ['+'] = '+', ['-'] = '-', ['*'] = '*', ['/'] = '/',
    ['%'] = '%', ['^'] = '^', ['<'] = '<', ['>'] = '>',
    ['?'] = '?', ['&'] = '&', ['|'] = '|', ['='] = '=',
    ['@'] = '@', ['~'] = '~'
}

local space = {
    [';'] = ';', [':'] = ':', ['('] = '(', [')'] = ')'
}

local functions = {
    ['P'] = 'PROMPT', ['R'] = 'RANDOM', ['B'] = 'BLOCK', ['C'] = 'CALL',
    ['Q'] = 'QUIT', ['D'] = 'DUMP', ['O'] = 'OUTPUT', ['L'] = 'LENGTH',
    ['A'] = 'ASCII', ['W'] = 'WHILE', ['I'] = 'IF', ['G'] = 'GET', ['S'] = 'SET'
}

local literals = {
    ['T'] = 'TRUE', ['F'] = 'FALSE', ['N'] = 'NULL',
}

local colors = {
    red = '\27[31m',
    green = '\27[32m',
    yellow = '\27[33m',
    blue = '\27[34m',
    magenta = '\27[35m',
    cyan = '\27[36m',
    white = '\27[37m',
    reset = '\27[0m',
    grey = '\27[90m',
}

return function(line, options) 
    if options['no-color'] or options['no-ansi'] then
        return line
    end

    local characters = {}

    for i = 1, #line do
        table.insert(characters, line:sub(i, i))
    end

    local buffer = ''
    local index = 1

    while index <= #characters do
        local char = characters[index]
        local peek = characters[index + 1]

        local code = string.byte(char)

        if symbols[char] then
            buffer = buffer .. colors.blue .. char .. colors.reset
            index = index + 1
        elseif space[char] then
            buffer = buffer .. colors.grey .. char .. colors.reset
            index = index + 1
        elseif functions[char] then
            buffer = buffer .. colors.red .. char
            peek = characters[index + 1]
            if not peek then return end
            
            code = string.byte(peek)

            while code >= 65 and code <= 90 and index <= #characters do
                buffer = buffer .. peek
                index = index + 1
                peek = characters[index + 1]
                if not peek then break end

                code = string.byte(peek)
            end

            buffer = buffer .. colors.reset
            index = index + 1
        elseif literals[char] then
            buffer = buffer .. colors.green .. char
            peek = characters[index + 1]
            if not peek then break end

            code = string.byte(peek)

            while code >= 65 and code <= 90 and index < #characters do
                buffer = buffer .. peek
                index = index + 1
                peek = characters[index + 1]

                if not peek then break end

                code = string.byte(peek)
            end

            buffer = buffer .. colors.reset
            index = index + 1
        elseif char == '"' then
            buffer = buffer .. colors.yellow .. char
            index = index + 1
            char = characters[index]

            while char ~= '"' and index < #characters do
                buffer = buffer .. char
                index = index + 1
                char = characters[index]
            end

            buffer = buffer .. '"' .. colors.reset
            index = index + 1
        elseif char == '\'' then
            buffer = buffer .. colors.yellow .. char
            index = index + 1
            char = characters[index]

            while char ~= '\'' and index <= #characters do
                buffer = buffer .. char
                index = index + 1
                char = characters[index]
            end

            buffer = buffer .. '\'' .. colors.reset
            index = index + 1
        elseif char == '#' then
            buffer = buffer .. colors.grey .. char
            index = index + 1
            char = characters[index]

            while char ~= '\n' and index < #characters do
                buffer = buffer .. char
                index = index + 1
                char = characters[index]
            end

            buffer = buffer .. colors.reset
        elseif code >= 48 and code <= 57 then
            buffer = buffer .. colors.magenta
            while code >= 48 and code <= 57 and index <= #characters do
                buffer = buffer .. char
                index = index + 1
                char = characters[index]

                if not char then break end
                code = string.byte(char)
            end

            buffer = buffer .. colors.reset
        else
            buffer = buffer .. char
            index = index + 1
        end
    end

    return buffer
end