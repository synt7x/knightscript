local config = require("config")
local frog = require("lib/frog")

local defaults = {
	-- String values
	["o"] = "a.kn", -- File to output to
	["P"] = "knight", -- Halt and output at given pass
	["f"] = "pretty", -- Format of output (pretty, block, golf)

	-- Boolean values
	["v"] = false, -- Version
	["h"] = false, -- Display help message
	["m"] = false, -- Minify compiled output
	["G"] = false, -- Golf compiled output
	["q"] = false, -- Silent mode
	["Q"] = false, -- Quiet mode
}

function getflags(args)
	local flags = defaults
	local inputs = {}
	local last

	for i = 1, #args do
		local argument = args[i]

		if argument:sub(1, 1) == "-" and not last then
			local char = argument:sub(2, 2)

			if char == "o" then
				if char == "o" and #argument > 2 then
					flags["o"] = argument:sub(3, #argument)
				else
					last = "o"
				end
			elseif char == "v" or argument == "--version" then
				flags["v"] = true
			elseif char == "h" or argument == "--help" then
				flags["h"] = true
			elseif char == "Q" or argument == "--silent" then
				flags["Q"] = true
			elseif char == "q" or argument == "--quiet" then
				flags["q"] = true
			elseif char == "P" or argument == "--pass" then
				if char == "P" and #argument > 2 then
					flags["P"] = argument:sub(3, #argument)
				else
					last = "P"
				end
			elseif char == "f" or argument == "--format" then
				if char == "f" and #argument > 2 then
					flags["f"] = argument:sub(3, #argument)
				else
					last = "f"
				end
			elseif char == "m" or argument == "--minify" then
				flags["m"] = true
			elseif char == "G" or argument == "--golf" then
				flags["G"] = true
			else
				flags[argument] = true
			end
		elseif last then
			if type(flags[last]) == "table" then
				table.insert(flags[last], argument)
			else
				flags[last] = argument
			end

			last = nil
		else
			table.insert(inputs, argument)
		end
	end

	return flags, inputs
end

return function(args)
	local flags, inputs = getflags(args)

	frog:setOptions(flags)

	if flags.h then
		frog:print(
			string.format("Usage: %s [options] [files]\n       %s\n", string.lower(config.name), config.description)
		)

		frog:print("Options:")
			:print("  -h, --help            Display extended help")
			:print("  -v, --version         Display version information")
			:print("  -q, --silent          Disable all output")
			:print("  -Q, --quiet           Disable all output except errors\n")
			:print("  --no-color            Disable colors in output")
			:print("  --no-ansi             Disable ANSI escape codes in output\n")
			:print("Compiler:")
			:print("  -o <file>             Output to <file>")
			:print("  -P, --pass <pass>     Halt and output at <tokens, comments, pre, ast, knight>")
			:print("  -m, --minify          Minify compiled output")
			:print("  -G, --golf          Change compiled output for optimal golf display")
			:print("  -f <format>           Set output format to <format>")
		os.exit(0)
	elseif flags.v then
		frog:print(string.format("%s v%s (%s)", config.name, config.version, config.branch))
		os.exit(0)
	elseif #inputs == 0 then
		frog:print(string.format("Usage: %s [options] [files]", string.lower(config.name)))

		frog:print("       -h, --help          Display extended help")
			:print("       -v, --version       Display version information")
		os.exit(0)
	end

	return flags, inputs
end
