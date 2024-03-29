local modulePaths = { }

function UseModule(moduleFileName, modulePath)

    modulePath = FindAndReplace(modulePath, "/", "\\")
    if modulePath:sub(modulePath:len()) ~= "\\" then
        modulePath = modulePath .. "\\"
    end
	RegisterPath(modulePath)
	require(moduleFileName)

end


function IsPathRegistered(modulePath)

	if modulePath == nil or string.len(modulePath) == 0 then
		return true
	end

	for index, modulePathName in ipairs(modulePaths) do
		if modulePathName == modulePath then
			return true
		end
	end
	return false

end


function RegisterPath(modulePath)

	if IsPathRegistered(modulePath) then
		return
	end
	package.path = package.path .. ";" .. ASSET_DIR .. modulePath .. "?.lua"
	table.insert(modulePaths, modulePath)
	
end