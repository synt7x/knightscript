local frog = {}
local json = require('lib/json')
local highlight = require('lib/highlight')

frog.errors = 0
frog.line = 1
frog.char = 1
frog.lines = {}
frog.options = {
    ['q'] = false,
    ['Q'] = false,
    ['no-color'] = false,
    ['no-ansi'] = false
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

function frog:setOptions(options)
    self.options = options
end

function frog:character()
    self.char = self.char + 1
end

function frog:getLines()
    return self.lines
end

function frog:newline()
    self.char = 1
    self.line = self.line + 1
end

function frog:print(...)
    if self.options['q'] or self.options['Q'] then return self end
    print(...)
    return self
end

function frog:printf(...)
    return self:print(string.format(...))
end

function frog:croak(message)
    if self.options['Q'] then return self end
    print(message)
    return self
end

function frog:colorize(color)
    if self.options['no-color'] or self.options['no-ansi'] then
        return ''
    end

    return color
end

function frog:throw(token, error, hint, type, a)
    if frog.errors > 0 then
        io.write('\n')
    end

    self:croak(self:colorize(type == 'Warn' and colors.yellow or colors.red) .. (type or 'Error') .. self:colorize(colors.reset) .. ': ' .. error)
    if token and self.lines[token.position[1]] then
        local line = self.lines[token.position[1]]:gsub('\t', ' ')
        
        if self.lines[token.position[1] - 1] then
            local line = self.lines[token.position[1] - 1]:gsub('\t', ' ')
            self:croak(self:colorize(colors.grey) .. '| ' .. self:colorize(colors.reset) .. highlight(line, self.options))
        end
        
        self:croak(self:colorize(colors.grey) .. '| ' .. self:colorize(colors.reset) .. highlight(line, self.options))
            :croak(
                self:colorize(colors.grey) .. '| '
                .. string.rep('-', token.position[2] - 1)
                .. string.rep('^', token.type == 'string'
                and #token.characters + 2 or token.characters and #token.characters or 1)
                .. self:colorize(colors.reset)
            )
        self:croak(
            self:colorize(colors.grey) .. '> ' .. self:colorize(colors.reset) ..
            self.file .. ':' .. token.position[1] .. ':' .. token.position[2]
        )
    end

    self:croak(self:colorize(colors.blue) .. 'Help: ' .. self:colorize(colors.reset) .. hint)
    frog.errors = frog.errors + 1
end

function frog:dump(stage, object)
    if self.options['P'] == stage then
        local file = io.open(self.options['o'], 'w')

        if file then
            file:write(json(object))
        else
            self:error('Could not open file: ' .. self.options['o'])
        end

        os.exit(0)
    end
end

function frog:write(stage, object)
    if self.options['P'] == stage then
        local file = io.open(self.options['o'], 'w')

        if file then
            file:write(object)
        else
            self:error('Could not open file: ' .. self.options['o'])
        end

        os.exit(0)
    end
end

function frog:text(stage, object)
    if self.options['P'] == stage then
        local file = io.open(self.options['o'], 'w')

        if file then
            file:write(object)
        else
            self:error('Could not open file: ' .. self.opions['o'])
        end

        os.exit(0)
    end
end

return frog