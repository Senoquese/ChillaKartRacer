
--Seed the random number generator
--Note: os.time() returns time in seconds, fine for an initial seed like this
--Not good for most other cases
math.randomseed(os.time())

--Replace the error function to log the error message before throwing it?
--[[local oldError = error
function LuaError(strData)

	GetConsole():Print(strData)
	oldError(strData)

end
error = LuaError]]

--Replace the print function to print to our console
function LuaPrint(strData)

	if type(strData) ~= "string" then
		strData = tostring(strData)
	end
	GetConsole():Print(strData)

end
print = LuaPrint


--Taken from http://lua-users.org/wiki/SplitJoin
--Concat the contents of the parameter list,
--separated by the string delimiter (just like in perl)
--example: WUtil_StringJoin(", ", {"Anna", "Bob", "Charlie", "Dolores"})
function WUtil_StringJoin(delimiter, list)
	local len = getn(list)
	if len == 0 then
		return ""
	end
	local string = list[1]
	for i = 2, len do
		string = string .. delimiter .. list[i]
	end
	return string
end


function StartsWith(string, startstr)

    local startLen = startstr:len()

    if string:len() >= startLen and string:sub(1, startLen) == startstr then
        return true
    end

    return false

end


--Taken from http://lua-users.org/wiki/SplitJoin
--Split text into a list consisting of the strings in text,
--separated by strings matching delimiter (which may be a pattern). 
--example: WUtil_StringSplit(",%s*", "Anna, Bob, Charlie, Dolores")
function WUtil_StringSplit(delimiter, text)
	local list = {}
	local pos = 1
	if string.find("", delimiter, 1) then --this would result in endless loops
		error("delimiter matches empty string!")
	end
	while 1 do
		local first, last = string.find(text, delimiter, pos)
		if first then --found?
			table.insert(list, string.sub(text, pos, first - 1))
			pos = last + 1
		else
			table.insert(list, string.sub(text, pos))
			break
		end
	end
	return list
end


--Ease value u between range lower a and higher b
function DELETEEase(u, a, b)
	local k
	local s = a + b
	if s == 0.0 then
		return u
	end
	if s > 1.0 then
		a = a / s
		b = b / s
	end
	k = 1.0 / (2.0 - a - b)
	if u < a then
		return ((k / a) * u * u)
	elseif u < 1.0 - b then
		return k * (2 * u - a)
	else
		u = 1.0 - u
		return (1.0 - (k / b) * u * u)
	end
end


--Return true if the passed in object is valid, false otherwise
function IsValid(object)

	PUSH_PROFILE("IsValid(object)")

	--Assume it is valid to start
	local validTest = true
	--If the object is nil
	if object == nil then
		validTest = false
	elseif type(object) == "function" then
		validTest = true
	elseif type(object) == "number" then
		validTest = true
	elseif type(object) == "string" then
		validTest = true
	elseif type(object) == "boolean" then
		validTest = true
	--If this is a shared object it will have a __ok member that is true or false
	elseif object.__ok == false then
		validTest = false
	end

	POP_PROFILE("IsValid(object)")

	--This Lua object or Shared object is valid
	return validTest

end


local vars = { }
function DefineVar(varName, varSet, varGet)

	vars[varName] = { varSet, varGet }

end


function SetVar(varName, varValue)

	if IsValid(vars[varName]) then
		vars[varName][1](varValue)
	else
		print("No Var with name: " .. varName)
	end

end


function PrintVar(varName)

	if IsValid(vars[varName]) then
		print(varName .. " = " .. tostring(vars[varName][2]()))
	else
		print("No Var with name: " .. varName)
	end

end


function PrintVars()

	for varName, varValue in pairs(vars) do
		print(varName .. " = " .. tostring(varValue[2]()))
	end

end


function ExtractPlayerIDFromState(stateParam)

	local playerID = stateParam:GetName()
	local startLoc = string.find(playerID, "_")
	return tonumber(string.sub(playerID, 1, startLoc - 1))

end


function MemStats()

	AllocatorNedPrintStats(GetConsole())

end