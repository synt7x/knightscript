local json = require("lib/json")
local parser = require("src/parser")
local traversal = parser.traversal

local symbols = {}
local arguments = {}
local scope

local break_void = {
	type = "identifier",
	characters = "__break",
}

local stack = {
	type = "identifier",
	characters = "___",
}

local void = {
	type = "identifier",
	characters = "_",
}

local block_void = {
	type = "identifier",
	characters = "__b",
}

local function get_unique(symbols, index)
	if not index then
		if not symbols["_"] then
			return "_"
		elseif not symbols["v"] then
			return "v"
		elseif not symbols["void"] then
			return "void"
		end
	end

	if not symbols[index] and index and type(index) ~= "number" then
		return index
	end

	local n = 0
	local identifier = "_"

	while symbols[identifier] do
		identifier = "_" .. n
		n = n + 1
	end

	if index then
		identifier = "_" .. "_" .. index
	else
		if type(index) == "number" then
			arguments[identifier] = true
		end

		return identifier
	end

	n = 0

	while symbols[identifier] do
		identifier = "_" .. n .. "_" .. index
		n = n + 1
	end

	if type(index) == "number" then
		arguments[identifier] = true
	end

	return identifier
end

function rename(ast, identifier, target)
	if traversal.binary[ast.type] then
		if ast.right then
			rename(ast.left, identifier, target)

			return rename(ast.right, identifier, target)
		end

		return rename(ast.left, identifier, target)
	elseif traversal.unary[ast.type] then
		return rename(ast.argument, identifier, target)
	elseif ast.type == "block" then
		if ast.args then
			for i, arg in ipairs(ast.args) do
				rename(arg, identifier, target)
			end
		end

		return rename(ast.body, identifier, target)
	elseif ast.type == "call" then
		if ast.args then
			for i, arg in ipairs(ast.args) do
				rename(arg, identifier, target)
			end
		end

		return rename(ast.name, identifier, target)
	elseif ast.type == "assignment" then
		rename(ast.name, identifier, target)
		return rename(ast.value, identifier, target)
	elseif ast.type == "while" then
		rename(ast.condition, identifier, target)
		return rename(ast.body, identifier, target)
	elseif ast.type == "if" then
		rename(ast.condition, identifier, target)
		rename(ast.body, identifier, target)
		return rename(ast.fallback, identifier, target)
	elseif ast.type == "get" then
		rename(ast.argument, identifier, target)
		rename(ast.start, identifier, target)
		return rename(ast.width, identifier, target)
	elseif ast.type == "set" then
		rename(ast.argument, identifier, target)
		rename(ast.start, identifier, target)
		rename(ast.width, identifier, target)
		return rename(ast.value, identifier, target)
	elseif ast.type == "identifier" then
		if ast.characters == identifier.characters then
			ast.previous = identifier.characters
			ast.characters = target
			return ast
		end

		return false
	end
end

function has(ast, kind, loop)
	if traversal.binary[ast.type] then
		if ast.right then
			return has(ast.left, kind, loop) or has(ast.right, kind, loop)
		end

		return has(ast.left, kind, loop)
	elseif traversal.unary[ast.type] then
		return has(ast.argument, kind, loop)
	elseif ast.type == "block" then
		return has(ast.body, kind, loop)
	elseif ast.type == "call" then
		return has(ast.name, kind, loop)
	elseif ast.type == "assignment" then
		return has(ast.value, kind, loop)
	elseif ast.type == "while" then
		if loop then
			return false
		else
			return has(ast.condition, kind, loop) or has(ast.body, kind, loop)
		end
	elseif ast.type == "if" then
		return has(ast.condition, kind, loop) or has(ast.body, kind, loop) or has(ast.fallback, kind, loop)
	elseif ast.type == "get" then
		return has(ast.argument, kind, loop) or has(ast.start, kind, loop) or has(ast.width, kind, loop)
	elseif ast.type == "set" then
		return has(ast.argument, kind, loop)
			or has(ast.start, kind, loop)
			or has(ast.width, kind, loop)
			or has(ast.value, kind, loop)
	elseif ast.type == kind then
		return true
	else
		return false
	end
end

local function null()
	return {
		type = "null",
	}
end

local function builtin(node)
	local placeholder = void

	local identifier = node.name.characters
	if identifier == "print" then
		node.type = "output"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "dump" then
		node.type = "dump"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "write" then
		node.type = "output"
		walk(node.args[1])
		node.argument = {
			type = "add",
			left = node.args[1] or null(),
			right = {
				type = "string",
				characters = "\\",
			},
		}

		node.name = nil
		node.args = nil
	elseif identifier == "insert" then
		node.type = "assignment"
		walk(node.args[1])
		walk(node.args[2])

		node.value = {
			type = "add",
			left = node.args[1] or null(),
			right = {
				type = "box",
				argument = node.args[2] or null(),
			},
		}

		node.name = node.args[1] or null()
		node.args = nil
	elseif identifier == "set" then
		walk(node.args[1])
		walk(node.args[2])
		walk(node.args[3])

		local name = node.args[1] or null()
		local index = node.args[2] or null()
		local value = node.args[3] or null()

		node.type = "assignment"
		node.name = name
		node.value = {
			type = "set",
			argument = name,
			value = {
				type = "box",
				argument = value,
			},
			start = index,
			width = {
				type = "number",
				characters = "1",
			},
		}

		node.args = nil
	elseif identifier == "join" then
		node.type = "exponent"

		walk(node.args[1])
		walk(node.args[2])

		node.left = node.args[1] or null()
		node.right = node.args[2] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "length" then
		node.type = "length"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "quit" then
		node.type = "quit"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "ascii" then
		node.type = "ascii"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "tail" then
		node.type = "ultimate"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "head" then
		node.type = "prime"
		walk(node.args[1])
		node.argument = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "push" then
		walk(node.args[1])
		walk(node.args[2])

		local name = node.args[1] or null()
		local value = node.args[2] or null()

		node.type = "assignment"

		node.name = name
		node.value = {
			type = "add",
			left = {
				type = "box",
				argument = value,
			},
			right = name,
		}

		node.args = nil
	elseif identifier == "pop" then
		walk(node.args[1])

		local name = node.args[1] or null()
		node.type = "expr"

		node.left = {
			type = "assignment",
			name = placeholder,
			value = {
				type = "prime",
				argument = name,
			},
		}

		node.right = {
			type = "expr",
			left = {
				type = "assignment",
				name = name,
				value = {
					type = "ultimate",
					argument = name,
				},
			},
			right = placeholder,
		}

		node.name = nil
		node.args = nil
	elseif identifier == "read" then
		node.type = "prompt"
		node.name = nil
		node.args = nil
	elseif identifier == "prompt" then
		node.type = "expr"
		walk(node.args[1])
		node.left = {
			type = "output",
			argument = {
				type = "add",
				left = node.args[1] or null(),
				right = {
					type = "string",
					characters = " \\",
				},
			},
		}

		node.right = {
			type = "prompt",
		}

		node.name = nil
		node.args = nil
	elseif identifier == "string" then
		node.type = "add"
		node.left = {
			type = "string",
			characters = "",
		}

		walk(node.args[1])
		node.right = node.args[1] or null()

		node.name = nil
		node.args = nil
	elseif identifier == "number" then
		node.type = "add"
		node.left = {
			type = "number",
			characters = "0",
		}

		walk(node.args[1])
		node.right = node.args[1] or null()

		node.name = nil
		node.args = nil
	end

	return node
end

local function array(node)
	if #node.elements == 1 then
		walk(node.elements[1])

		node.type = "box"
		node.argument = node.elements[1]
	elseif #node.elements > 1 then
		node.type = "add"

		local element = node

		for i = 1, #node.elements do
			walk(node.elements[i])

			element.left = {
				type = "box",
				argument = node.elements[i],
			}

			if i == #node.elements - 1 then
				walk(node.elements[i + 1])
				element.right = {
					type = "box",
					argument = node.elements[i + 1],
				}

				break
			end

			element.right = {
				type = "add",
			}

			element = element.right
		end
	end

	node.elements = nil
end

function walk(node)
	if not node then
		return
	end

	if node.type == "expr" then
		scope = node

		if not node.right then
			local left = node.left

			node.left = nil
			node.right = nil

			for k, v in pairs(left) do
				node[k] = v
			end

			walk(node)

			return node
		end

		walk(node.left)
		walk(node.right)
	elseif traversal.binary[node.type] then
		walk(node.left)
		walk(node.right)
	elseif traversal.unary[node.type] then
		walk(node.argument)
	elseif node.type == "assignment" then
		local scope = scope
		walk(node.name)
		walk(node.value)

		if node.scoped and scope then
			print(json(scope))

			local identifier = node.name.characters
			local name = get_unique(symbols, identifier)

			rename(scope, {
				type = "identifier",
				characters = identifier,
			}, name)
		end
	elseif node.type == "call" then
		local root = node
		local original = node.name

		if node.name.type == "identifier" then
			builtin(node)
		else
			walk(node.name)
		end

		if node.args and #node.args > 0 then
			local args = node.args
			local name = node.name

			node.name = {}
			node = node.name

			if arguments[original.characters] then
				name = block_void

				node.type = "expr"
				node.left = {
					type = "assignment",
					name = name,
					value = original,
				}
				node.right = {}
				node = node.right
			end

			for i, arg in ipairs(args) do
				walk(arg)

				node.type = "expr"
				node.left = {
					type = "assignment",
					name = {
						type = "identifier",
						characters = get_unique(symbols, i),
					},
					value = arg,
				}

				node.right = {}

				if i == #args then
					node.right = name
				end

				node = node.right
			end

			if arguments[original.characters] then
				root.type = "expr"

				root.left = {
					type = "assignment",
					name = void,
					value = {
						type = "call",
						name = root.name,
					},
				}

				root.right = {
					type = "expr",
					left = {
						type = "assignment",
						name = original,
						value = name,
					},
					right = void,
				}

				root.name = nil
			end
		end
	elseif node.type == "block" then
		for i, arg in ipairs(node.args) do
			local name = get_unique(symbols, i)
			rename(node.body, arg, name)
		end

		walk(node.body)

		for i, arg in ipairs(node.args) do
			local name = get_unique(symbols, i)
			rename(node.body, arg, name)
		end
	elseif node.type == "while" then
		if has(node.body, "break", true) then
			local condition = node.condition

			node.condition = {
				type = "and",
				left = condition,
				right = {
					type = "not",
					argument = break_void,
				},
			}

			node.type = "expr"
			node.left = {
				type = "while",
				condition = node.condition,
				body = node.body,
			}

			node.right = {
				type = "assignment",
				name = break_void,
				value = {
					type = "null",
					characters = "null",
				},
			}

			node.condition = nil
			node.body = nil

			walk(node.left.condition)
			walk(node.left.body)
		else
			walk(node.condition)
			walk(node.body)
		end
	elseif node.type == "if" then
		walk(node.condition)
		walk(node.body)
		walk(node.fallback)
	elseif node.type == "get" then
		walk(node.argument)
		walk(node.start)
		walk(node.width)
	elseif node.type == "set" then
		walk(node.argument)
		walk(node.start)
		walk(node.width)
		walk(node.value)
	elseif node.type == "break" then
		node.type = "assignment"
		node.name = break_void
		node.value = {
			type = "true",
			characters = "true",
		}
	elseif node.type == "index" then
		walk(node.name)
		walk(node.value)

		local name = node.name
		local index = node.value

		node.type = "prime"
		node.argument = {
			type = "get",
			argument = name,
			start = index,
			width = {
				type = "true",
				characters = "true",
			},
		}

		node.name = nil
		node.value = nil
	elseif node.type == "array" then
		array(node)
	end

	return node
end

local function transform(ast, st)
	symbols = st
	void.characters = get_unique(symbols)
	stack.characters = get_unique(symbols, "stack")
	break_void.characters = get_unique(symbols, "break")
	block_void.characters = get_unique(symbols, "b")

	symbols[void.characters] = true
	symbols[block_void.characters] = true

	if has(ast.body, "break") then
		ast.body = {
			type = "expr",
			left = {
				type = "assignment",
				name = break_void,
				value = {
					type = "null",
					characters = "null",
				},
			},
			right = walk(ast.body),
		}
	else
		ast.body = walk(ast.body)
	end

	ast.body = walk(ast.body)
	return ast
end

return transform
