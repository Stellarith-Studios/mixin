local ERR_MIXIN_FUNC_NOT_FOUND = "Trying a mixin on non existent function %s on table %s"
local ERR_MIXIN_CANT_COPY = "A base function %s on table %s could not be copied for a mixin: %s"

if not fun then
	fun = {}
end

if not fun.clone then
	--- Clones a function invalidating all upvalue references. May return `nil` if the function could not be cloned.
	--- @param f function function to be cloned
	--- @return function? clone
	--- @return string? err clone error message
	function fun.clone(f)
		local ok, dumped = pcall(string.dump, f)
		if not ok then
			return nil, dumped
		end

		return load(dumped)
	end
end

if not fun.copy then
	--- Copies a function with all upvalues. May return `nil` if the function could not be copied.
	--- @param f function function to be copied
	--- @return function? copy
	--- @return string? copy error message
	function fun.copy(f)
		local copy, err = fun.clone(f)

		if not copy then
			return nil, err
		end

		local i = 1
		while true do
			local name, _ = debug.getupvalue(f, i)
			if not name then break end
			debug.upvaluejoin(copy, i, f, i)
			i = i + 1
		end

		return copy
	end
end

--- Replaces function with name `name` on table/class `t` with the mixin function `func`. The first argument of
--- a mixin function is always the base function it is the replacement for, this doesn't change the original
--- function pattern.
---
--- The parameters to the original function will be changed to match the mixin function except the first parameter
--- `base`, but it's recommended to only add optional parameters or make already existing parameters optional to
--- avoid errors.
---
--- Example:
---
--- ```lua
--- A = {}
---
--- function A.foo()
--- 	print("inner")
--- end
---
--- local function my_mixin(base, arg)
--- 	print(tostring(arg or "default")) -- arg is optional to avoid errors
--- 	base()
--- 	print("after")
--- end
---
--- A.foo()      -- prints "inner"
--- Mixin(A, "foo", my_mixin)
--- A.foo("bar") -- prints "bar\ninner\nafter"
--- ```
--- @param t table the table/class this mixin will be applied to
--- @param name string name of the function to be changed, this must exist on `t`
--- @param func fun(base: function, ...: any) replacement of the function with name `name` on `t`
--- @return string? result result of the mixin operation, `nil` if successful
function Mixin(t, name, func)
	--- @type function
	local base_ref = t[name]
	if not base_ref then
		return string.format(ERR_MIXIN_FUNC_NOT_FOUND, name, tostring(t))
	end

	local base, err = fun.copy(base_ref)

	if not base then
		return string.format(ERR_MIXIN_CANT_COPY, name, tostring(t), err)
	end

	t[name] = function(...) func(base, ...) end
end

return Mixin
