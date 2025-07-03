local frog = require("lib/frog")
local json = require("lib/json")

local function null_expr(state)
	return {
		type = "null",
	}
end

local function unary_expr(state)
	if state:test("!") then
		-- Consume the '!' token
		return function(v)
			return {
				type = "not",
				argument = v,
			}
		end
	elseif state:test("-") then
		-- Consume the '-' token
		return function(v)
			return {
				type = "negate",
				argument = v,
			}
		end
	elseif state:test("#") then
		-- Consume the '#' token
		return function(v)
			return {
				type = "length",
				argument = v,
			}
		end
	end
end

local function binary_expr(state)
	if state:test("==") then
		-- Consume the '==' token
		return function(r, l)
			return {
				type = "exact",
				left = l,
				right = r,
			}
		end, 3
	elseif state:test("!=") then
		-- Consume the '!=' token
		return function(r, l)
			return {
				type = "not",
				argument = {
					type = "exact",
					left = l,
					right = r,
				},
			}
		end,
			3
	elseif state:test("<") then
		-- Consume the '<' token
		return function(r, l)
			return {
				type = "less",
				left = l,
				right = r,
			}
		end, 3
	elseif state:test("<=") then
		-- Consume the '<=' token
		return function(r, l)
			return {
				type = "or",
				left = {
					type = "less",
					left = l,
					right = r,
				},
				right = {
					type = "exact",
					left = l,
					right = r,
				},
			}
		end,
			3
	elseif state:test(">") then
		-- Consume the '>' token
		return function(r, l)
			return {
				type = "greater",
				left = l,
				right = r,
			}
		end, 3
	elseif state:test(">=") then
		-- Consume the '>=' token
		return function(r, l)
			return {
				type = "or",
				left = {
					type = "greater",
					left = l,
					right = r,
				},
				right = {
					type = "exact",
					left = l,
					right = r,
				},
			}
		end,
			3
	elseif state:test("&&") then
		-- Consume the '&&' token
		return function(r, l)
			return {
				type = "and",
				left = l,
				right = r,
			}
		end, 2
	elseif state:test("||") then
		-- Consume the '||' token
		return function(r, l)
			return {
				type = "or",
				left = l,
				right = r,
			}
		end, 1
	elseif state:test("&") then
		-- Consume the '&&' token
		return function(r, l)
			return {
				type = "and",
				left = l,
				right = r,
			}
		end, 2
	elseif state:test("|") then
		-- Consume the '||' token
		return function(r, l)
			return {
				type = "or",
				left = l,
				right = r,
			}
		end, 1
	elseif state:test("+") then
		-- Consume the '+' token
		return function(r, l)
			return {
				type = "add",
				left = l,
				right = r,
			}
		end, 10
	elseif state:test("-") then
		-- Consume the '-' token
		return function(r, l)
			return {
				type = "subtract",
				left = l,
				right = r,
			}
		end, 10
	elseif state:test("*") then
		-- Consume the '*' token
		return function(r, l)
			return {
				type = "multiply",
				left = l,
				right = r,
			}
		end, 11
	elseif state:test("/") then
		-- Consume the '/' token
		return function(r, l)
			return {
				type = "divide",
				left = l,
				right = r,
			}
		end, 11
	elseif state:test("%") then
		-- Consume the '%' token
		return function(r, l)
			return {
				type = "modulus",
				left = l,
				right = r,
			}
		end, 11
	elseif state:test("^") then
		-- Consume the '^' token
		return function(r, l)
			return {
				type = "exponent",
				left = l,
				right = r,
			}
		end, 14
	elseif state:test("!=") then
		-- Consume the '!=' token
		return function(r, l)
			return {
				type = "not",
				argument = {
					type = "exact",
					left = l,
					right = r,
				},
			}
		end,
			3
	end
end

local function compound_expr(state, node)
	if state:accept("+=") then
		return {
			type = "add",
			left = node,
			right = expression(state),
		}
	elseif state:accept("-=") then
		return {
			type = "subtract",
			left = node,
			right = expression(state),
		}
	elseif state:accept("*=") then
		return {
			type = "multiply",
			left = node,
			right = expression(state),
		}
	elseif state:accept("/=") then
		return {
			type = "divide",
			left = node,
			right = expression(state),
		}
	elseif state:accept("%=") then
		return {
			type = "modulus",
			left = node,
			right = expression(state),
		}
	elseif state:accept("^=") then
		return {
			type = "exponent",
			left = node,
			right = expression(state),
		}
	elseif state:accept("&=") then
		return {
			type = "and",
			left = node,
			right = expression(state),
		}
	elseif state:accept("|=") then
		return {
			type = "or",
			left = node,
			right = expression(state),
		}
	end
end

local function expression_stat(state)
	local node = index_expr(state)

	if state:test("=") then
		if not node or node.type ~= "identifier" and node.type ~= "index" then
			-- TODO: I think it may be possible to resolve the index into a set call
			-- I will work on this when I have time
			frog:throw(
				state.token,
				"Invalid assignment, the left side of the assignment must be an identifier",
				node.type == "index" and "You probably intended to use the set(array, index, value) function"
					or "Try replacing the left side with an identifier",
				"Parser"
			)

			os.exit(1)
		end

		-- Consume the '=' token
		state:accept("=")

		if node.type == "index" then
			return array_assignment(node, state, expression(state))
		end

		-- Create a new node for the assignment
		local assignment_node = {
			type = "assignment",
			name = node,
		}

		-- Get the value of the assignment
		assignment_node.value = expression(state)
		return assignment_node
	else
		local compound = compound_expr(state, node)

		if compound then
			return {
				type = "assignment",
				name = node,
				value = compound,
			}
		end
	end

	if not node then
		node = expression(state)
	end

	return node
end

function array_assignment(node, state, value)
	local name = node.name
	local index = node.value

	if node.type == "index" then
		local node, depth = array_assignment(name, state, value)

		if not depth then
			local tree = {
				type = "set",
				argument = node.name,
				start = index,
				width = {
					type = "true",
					characters = "true",
				},
				value = {
					type = "box",
					argument = node.value,
				},
			}

			node.value = tree
			return node, tree
		else
			local value = depth.value.argument
			local prev_arg = depth.argument
			local prev_index = depth.start
			local tree = {
				type = "set",
				argument = {
					type = "prime",
					argument = {
						type = "get",
						argument = prev_arg,
						start = prev_index,
						width = {
							type = "true",
							characters = "true",
						},
					},
				},
				start = index,
				width = {
					type = "number",
					characters = "1",
				},
				value = {
					type = "box",
					argument = value,
				},
			}

			depth.value.argument = tree
			return node, tree
		end

		return node
	elseif node.type == "identifier" then
		return {
			type = "assignment",
			name = node,
			value = value,
		}
	end
end

local function array(state)
	-- Accept the '[' token
	state:expect("[")

	local node = {
		type = "array",
		elements = {},
	}

	if state:accept("]") then
		return node
	end

	repeat
		table.insert(node.elements, expression(state))
	until not state:accept(",")

	state:expect("]")
	return node
end

local function literal(state)
	if state:test("number") then
		return state:accept("number")
	elseif state:test("string") then
		return state:accept("string")
	elseif state:test("true") then
		return state:accept("true")
	elseif state:test("false") then
		return state:accept("false")
	elseif state:test("null") then
		return state:accept("null")
	elseif state:test("[") then
		return array(state)
	else
		return index_expr(state)
	end
end

local function arity_expr(limit, state, precede)
	local result = {}
	local unary = unary_expr(state)

	if unary then
		local token = state.token
		state:skip()
		local value = arity_expr(12, state, false)

		if not value then
			frog:throw(token, "Missing expression following unary operation", "Add an expression here")

			os.exit(1)
		end
		result = unary(value)
	else
		result = literal(state)
	end

	local binary, precedence = binary_expr(state)
	-- binary returns a local function that takes two arguments and returns the AST node

	while binary do
		if not precedence then
			break
		end
		if precedence < limit then
			break
		end

		local token = state.token
		state:skip()

		local operand, value = arity_expr(precedence, state, true)
		if not result or not value then
			frog:throw(token, "Missing expression in binary operation", "Add an expression here")

			os.exit(1)
		end

		result = binary(value, result)
		binary = operand
	end

	if precede then
		return binary, result
	end

	if state:test("?") then
		if not result then
			frog:throw(state.token, "Missing condition in ternary", "Add an expression prior")

			os.exit(1)
		end

		state:accept("?")

		local truthy = expression(state)
		local node = {
			type = "or",
			left = {
				type = "and",
				left = result,
				right = truthy,
			},
		}

		if not truthy then
			frog:throw(state.token, "Missing truthy side of ternary", "Add an expression prior")

			os.exit(1)
		end

		local token = state.token
		state:expect(":")
		local falsey = expression(state)
		node.right = falsey

		if not falsey then
			frog:throw(token, "Missing falsey side of ternary", "Add an expression after")

			os.exit(1)
		end

		return node
	end

	return result
end

function expression(state)
	return arity_expr(0, state, false)
end

function index_expr(state)
	local identifier = identifier_expr(state)

	local level

	while state:test("[") or state:test("(") do
		if state:test("[") then
			-- Consume the '[' token
			state:accept("[")

			-- Get the index expression
			local index = expression(state)

			if not level then
				level = {
					type = "index",
					name = identifier,
					value = index,
				}
			else
				level = {
					type = "index",
					name = level,
					value = index,
				}
			end

			-- Consume the ']' token
			state:expect("]")
		elseif state:test("(") then
			-- Consume the '(' token
			state:accept("(")

			-- Get the arguments of the local function call
			local args = {}

			while not state:test(")") do
				local arg = expression(state)
				table.insert(args, arg)

				if not state:accept(",") then
					break
				end
			end

			-- Consume the ')' token
			state:expect(")")

			if not level then
				level = {
					type = "call",
					name = identifier,
					args = args,
				}
			else
				level = {
					type = "call",
					name = level,
					args = args,
				}
			end
		end
	end

	return level or identifier
end

function identifier_expr(state)
	if state:accept("(") then
		local expr = arity_expr(0, state)
		state:expect(")")
		return expr
	elseif state:test("identifier") then
		local identifier = state:expect("identifier")
		state:symbol(identifier)
		return identifier
	end
end

local function else_expr(state)
	-- Consume the 'else' token
	state:accept("else")
	-- Get the body of the else statement
	state:expect("{")
	local node = statement(state)
	state:expect("}")

	return node
end

local function elseif_expr(state)
	-- Consume the 'elseif' token
	state:accept("elseif")

	-- Create a new node for the elseif statement
	local node = {
		type = "if",
	}

	-- Get the condition of the elseif statement
	state:expect("(")
	node.condition = expression(state)
	state:expect(")")

	-- Get the body of the elseif statement
	state:expect("{")
	node.body = statement(state)
	state:expect("}")

	-- Check for else statements
	if state:test("else") then
		node.fallback = else_expr(state) or null_expr(state)
	elseif state:test("elseif") then
		node.fallback = elseif_expr(state) or null_expr(state)
	else
		node.fallback = null_expr(state)
	end

	return node
end

-- Handle if statements
local function if_expr(state)
	-- Consume the 'if' token
	state:accept("if")

	-- Create a new node for the if statement
	local node = {
		type = "if",
	}

	-- Get the condition of the if statement
	state:expect("(")
	node.condition = expression(state)
	state:expect(")")

	-- Get the body of the if statement
	state:expect("{")
	node.body = statement(state) or null_expr(state)
	state:expect("}")

	-- Check for elseif or else statements
	if state:test("elseif") then
		node.fallback = elseif_expr(state) or null_expr(state)
	elseif state:test("else") then
		node.fallback = else_expr(state) or null_expr(state)
	else
		node.fallback = null_expr(state)
	end

	return node
end

local function while_expr(state)
	-- Consume the 'while' token
	state:accept("while")

	-- Create a new node for the while statement
	local node = {
		type = "while",
	}

	-- Get the condition of the while statement
	state:expect("(")
	node.condition = expression(state)
	state:expect(")")

	-- Get the body of the while statement
	state:expect("{")

	if state:test("}") then
		node.body = null_expr(state)
	else
		node.body = statement(state)
	end

	state:expect("}")

	return node
end

local function for_condition(state)
	-- Get the identifier of the iterator
	local identifier = state:expect("identifier")
	state:symbol(identifier)

	-- Create a new node for the for condition
	local initial_node = {
		type = "assignment",
		name = identifier,
		scoped = true,
	}

	if state:test("in") or state:test(",") then
		local assignment_node = {
			type = "assignment",
			scoped = true,
		}

		if state:accept(",") then
			assignment_node.name = state:expect("identifier")
		end

		-- Consume the 'in' token
		state:expect("in")

		local array = expression(state)

		local follow_node = {
			type = "assignment",
			name = identifier,
			value = {
				type = "add",
				left = identifier,
				right = {
					type = "number",
					characters = "1",
				},
			},
		}

		local length_node = {
			type = "length",
			argument = array,
		}

		local condition_node = {
			type = "less",
			left = identifier,
			right = length_node,
		}

		local number = {
			type = "number",
			characters = 0,
		}

		initial_node.value = number

		if assignment_node.name then
			assignment_node.value = {
				type = "prime",
				argument = {
					type = "get",
					start = identifier,
					width = {
						type = "number",
						characters = "1",
					},
					argument = array,
				},
			}

			return initial_node, condition_node, follow_node, assignment_node
		end

		return initial_node, condition_node, follow_node
	elseif state:expect("=") then
		-- Consume the '=' token
		state:accept("=")

		initial_node.value = expression(state)

		state:expect(",")

		local condition_node = {
			type = "less",
			left = identifier,
			right = {
				type = "add",
				left = expression(state),
				right = {
					type = "number",
					characters = "1",
				},
			},
		}

		local follow_node = {}

		if state:accept(",") then
			follow_node = {
				type = "assignment",
				name = identifier,
				value = {
					type = "add",
					left = identifier,
					right = expression(state),
				},
			}
		else
			follow_node = {
				type = "assignment",
				name = identifier,
				value = {
					type = "add",
					left = identifier,
					right = {
						type = "number",
						characters = "1",
					},
				},
			}
		end

		return initial_node, condition_node, follow_node
	end
end

local function for_expr(state)
	-- Consume the 'for' token
	state:accept("for")

	-- Create a new node for the for statement
	local node = {
		type = "expr",
	}

	-- Create the 'while' part of the for statement
	local loop_node = {
		type = "while",
	}

	node.right = loop_node

	-- Get the body of the for statement
	state:expect("(")
	local initial, condition, follow, pre = for_condition(state)
	node.left = initial
	loop_node.condition = condition
	state:expect(")")

	-- Get the body of the for statement
	state:expect("{")
	local body = statement(state)

	if body then
		loop_node.body = {
			type = "expr",
			left = body,
			right = follow,
		}
	else
		loop_node.body = follow
	end

	if pre then
		loop_node.body = {
			type = "expr",
			left = pre,
			right = loop_node.body,
		}
	end

	state:expect("}")

	return node
end

local function function_expr(state)
	-- Consume the 'function' token
	state:accept("function")

	-- Create the assignment node for the function
	local node = {
		type = "assignment",
		name = state:expect("identifier"),
	}

	state:symbol(node.name)

	-- Get the arguments of the function
	state:expect("(")

	local args = {}

	while state:test("identifier") do
		local arg = state:expect("identifier")
		state:symbol(arg)

		table.insert(args, arg)
		if not state:test(",") then
			break
		end
		state:accept(",")
	end

	state:expect(")")
	state:expect("{")

	-- Create the body node for the function
	local block = {
		type = "block",
		args = args,
		name = node.name,
	}

	block.body = statement(state) or null_expr()
	state:expect("}")

	node.value = block
	return node
end

local function return_expr(state)
	-- Consume the 'return' token
	state:accept("return")

	-- In Knight, the return statement is the last expression
	return expression(state)
end

local function break_expr(state)
	-- TODO: Add expression to the 'while' and 'for' nodes as an additional condition
	-- TODO: In the symbol resolver, remove the break condition if it is not in the loop
	state:accept("break")

	return {
		type = "break",
	}
end

local function export_expr(state)
	-- TODO: Add export statement
	state:accept("export")
	return expression(state)
end

local function import_expr(state)
	-- TODO: Add import statement
	state:accept("import")

	local node = {
		type = "import",
	}

	if state:test("identifier") then
		node.value = state:accept("identifier")
	else
		node.value = array(state)
	end

	state:expect("from")

	node.file = state:expect("string")

	return node
end

local function local_expr(state)
	-- Consume the 'local' token
	state:accept("local")

	-- Create a new node for the local statement
	local node = {
		type = "assignment",
		name = state:expect("identifier"),
		scoped = true,
	}

	state:symbol(node.name)

	-- Get the value of the local statement
	state:expect("=")
	node.value = expression(state)

	return node
end

local function const_expr(state)
	-- Consume the 'const' token
	state:accept("const")

	-- Create a new node for the const statement
	local node = {
		type = "assignment",
		name = state:expect("identifier"),
		scoped = true,
	}

	state:symbol(node.name)

	-- Get the value of the const statement
	state:expect("=")
	node.value = expression(state)

	return node
end

function statement(state)
	-- Get the current token from the state variable
	local token = state.token

	-- Try to fit all tokens into a binary expression
	if not token or state:test("}") or state:test(")") then
		-- No token found, just return nil
		return

		-- Will result in a node with the structure
		-- { ... left = { ... } right = nil }
		-- This can be compressed into a single node
	end

	-- All elements are binary expressions
	local node = {
		type = "expr",
	}

	-- Get the node of the left side of the expression
	if state:test("if") then
		node.left = if_expr(state)
	elseif state:test("while") then
		node.left = while_expr(state)
	elseif state:test("for") then
		node.left = for_expr(state)
	elseif state:test("function") then
		node.left = function_expr(state)
	elseif state:test("return") then
		node.left = return_expr(state)
		return node
	elseif state:test("break") then
		node.left = break_expr(state)
	elseif state:test("export") then
		node.left = export_expr(state)
		return node
	elseif state:test("import") then
		node.left = import_expr(state)
	elseif state:test("local") then
		node.left = local_expr(state)
	elseif state:test("const") then
		node.left = const_expr(state)
	else
		node.left = expression_stat(state)

		if not node.left then
			frog:throw(state.token, "Invalid token", "Consider removing this token to satisfy the parser", "Parser")
			os.exit(1)
		end
	end

	-- The right side of the expression is another expression
	node.right = statement(state)
	return node
end

return statement
