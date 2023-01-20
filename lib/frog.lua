local frog = {}
local json = require('lib/json')

frog.options = {
    ['q'] = false,
    ['Q'] = false,
}

function frog:setOptions(options)
    self.options = options
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

function frog:dump(stage, object)
    if self.options['P'] == stage then
        local file = io.open(self.options['o'] .. '.lua', 'w')

        if file then
            file:write(json(object))
        else
            self:error('Could not open file: ' .. input)
        end

        os.exit(0)
    end
end

return frog