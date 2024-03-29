--Use the bit + hex library
UseModule("bit", "Scripts/luabit-0.4/")
UseModule("hex", "Scripts/luabit-0.4/")

local currentColorName = nil
local customizeKart = nil


function SetCustomizeKart(kartName)

	customizeKart = GetObjectSystem():GetObjectByName(kartName, false)
	if customizeKart and customizeKart.__ok then
		customizeKart = ToOGREPlayerKart(customizeKart)
	end

end


function GetCustomizeKart()

	return customizeKart

end


function RequestColorButtonsUpdate(guiArgs)

	local naviValue = GetNaviMultiValue(guiArgs, "Callback")
	local jsCallback = naviValue:str()

	naviValue = GetNaviMultiValue(guiArgs, "Type")
	local itemType = naviValue:str()

	naviValue = GetNaviMultiValue(guiArgs, "Color1")
	local color1 = naviValue:str()

	naviValue = GetNaviMultiValue(guiArgs, "Color2")
	local color2 = naviValue:str()

	naviValue = GetNaviMultiValue(guiArgs, "Color3")
	local color3 = naviValue:str()

	naviValue = GetNaviMultiValue(guiArgs, "Color4")
	local color4 = naviValue:str()

	if string.len(jsCallback) == 0 then
		return
	end

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in system in Lua: RequestColorButtonsUpdate")
		return
	end

	local retColor1 = "null"
	local retColor2 = "null"
	local retColor3 = "null"
	local retColor4 = "null"
	if itemType == "karts" then
		if color1 ~= "null" then
			retColor1 = kart:GetKartColor(color1)
		end
		if color2 ~= "null" then
			retColor2 = kart:GetKartColor(color2)
		end
		if color3 ~= "null" then
			retColor3 = kart:GetKartColor(color3)
		end
		if color4 ~= "null" then
			retColor4 = kart:GetKartColor(color4)
		end
	elseif itemType == "wheels" then
		if color1 ~= "null" then
			retColor1 = kart:GetWheelsColor(color1)
		end
		if color2 ~= "null" then
			retColor2 = kart:GetWheelsColor(color2)
		end
		if color3 ~= "null" then
			retColor3 = kart:GetWheelsColor(color3)
		end
		if color4 ~= "null" then
			retColor4 = kart:GetWheelsColor(color4)
		end
	elseif itemType == "hats" then
		if color1 ~= "null" then
			retColor1 = kart:GetHatColor(color1)
		end
		if color2 ~= "null" then
			retColor2 = kart:GetHatColor(color2)
		end
		if color3 ~= "null" then
			retColor3 = kart:GetHatColor(color3)
		end
		if color4 ~= "null" then
			retColor4 = kart:GetHatColor(color4)
		end
	elseif itemType == "accessories" then
		if color1 ~= "null" then
			retColor1 = kart:GetAccessoryColor(color1)
		end
		if color2 ~= "null" then
			retColor2 = kart:GetAccessoryColor(color2)
		end
		if color3 ~= "null" then
			retColor3 = kart:GetAccessoryColor(color3)
		end
		if color4 ~= "null" then
			retColor4 = kart:GetAccessoryColor(color4)
		end
	end

	if retColor1 ~= "null" then
		retColor1 = bit.brshift(retColor1, 8)
	end
	if retColor2 ~= "null" then
		retColor2 = bit.brshift(retColor2, 8)
	end
	if retColor3 ~= "null" then
		retColor3 = bit.brshift(retColor3, 8)
	end
	if retColor4 ~= "null" then
		retColor4 = bit.brshift(retColor4, 8)
	end

	local jsCode = jsCallback .. "(" .. retColor1 .. ", " .. retColor2 .. ", " .. retColor3 .. ", " .. retColor4 .. ");"
	GetNaviGUISystem():GetPage("Customizer", true):EvaluateJS(jsCode)

end


function OpenColorPickerKart(guiArgs)

	local colorNameValue = GetNaviMultiValue(guiArgs, "ColorName")
	currentColorName = colorNameValue:str()

	if not GetNaviGUISystem():IsPageActive("ColorPicker") then
		local pageCreator = GUIPageCreator()
		pageCreator:SetPageName("ColorPicker");
		pageCreator:SetPageURL("local://customize/picker.html");
		pageCreator:SetAbsoluteWidth(256);
		pageCreator:SetAbsoluteHeight(256);
		pageCreator:SetMovable(true);
		pageCreator:SetForceUpdates(true);
		GetNaviGUISystem():AddPage(pageCreator)
	end

	SetColorPickerCallback(SetKartColor)

end


function CloseColorPickerKart(guiArgs)

	GetNaviGUISystem():RemovePage("ColorPicker")

end


function OpenColorPickerWheels(guiArgs)

	local colorNameValue = GetNaviMultiValue(guiArgs, "ColorName")
	currentColorName = colorNameValue:str()

	if not GetNaviGUISystem():IsPageActive("ColorPicker") then
		local pageCreator = GUIPageCreator()
		pageCreator:SetPageName("ColorPicker");
		pageCreator:SetPageURL("local://customize/picker.html");
		pageCreator:SetAbsoluteWidth(256);
		pageCreator:SetAbsoluteHeight(256);
		pageCreator:SetMovable(true);
		pageCreator:SetForceUpdates(true);
		GetNaviGUISystem():AddPage(pageCreator)
	end

	SetColorPickerCallback(SetWheelsColor)

end


function OpenColorPickerHat(guiArgs)

	local colorNameValue = GetNaviMultiValue(guiArgs, "ColorName")
	currentColorName = colorNameValue:str()

	if not GetNaviGUISystem():IsPageActive("ColorPicker") then
		local pageCreator = GUIPageCreator()
		pageCreator:SetPageName("ColorPicker");
		pageCreator:SetPageURL("local://customize/picker.html");
		pageCreator:SetAbsoluteWidth(256);
		pageCreator:SetAbsoluteHeight(256);
		pageCreator:SetMovable(true);
		pageCreator:SetForceUpdates(true);
		GetNaviGUISystem():AddPage(pageCreator)
	end

	SetColorPickerCallback(SetHatColor)

end


function OpenColorPickerAccessory(guiArgs)

	local colorNameValue = GetNaviMultiValue(guiArgs, "ColorName")
	currentColorName = colorNameValue:str()

	if not GetNaviGUISystem():IsPageActive("ColorPicker") then
		local pageCreator = GUIPageCreator()
		pageCreator:SetPageName("ColorPicker");
		pageCreator:SetPageURL("local://customize/picker.html");
		pageCreator:SetAbsoluteWidth(256);
		pageCreator:SetAbsoluteHeight(256);
		pageCreator:SetMovable(true);
		pageCreator:SetForceUpdates(true);
		GetNaviGUISystem():AddPage(pageCreator)
	end

	SetColorPickerCallback(SetAccessoryColor)

end

function SetKartColor(red, green, blue, alpha)

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in system in Lua: SetKartColor")
		return
	end

	kart:SetKartColor(currentColorName, red, green, blue, alpha)

	GetNaviGUISystem():GetPage("Customizer", true):EvaluateJS("JS_RequestColorButtonsUpdate();")

end


function SetWheelsColor(red, green, blue, alpha)

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in system in Lua: SetColor")
		return
	end

	kart:SetWheelsColor(currentColorName, red, green, blue, alpha)

	GetNaviGUISystem():GetPage("Customizer", true):EvaluateJS("JS_RequestColorButtonsUpdate();")

end


function SetHatColor(red, green, blue, alpha)

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in system in Lua: SetColor")
		return
	end

	kart:SetHatColor(currentColorName, red, green, blue, alpha)

	GetNaviGUISystem():GetPage("Customizer", true):EvaluateJS("JS_RequestColorButtonsUpdate();")

end


function SetAccessoryColor(red, green, blue, alpha)

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in system in Lua: SetColor")
		return
	end

	kart:SetAccessoryColor(currentColorName, red, green, blue, alpha)

	GetNaviGUISystem():GetPage("Customizer", true):EvaluateJS("JS_RequestColorButtonsUpdate();")

end

function SetPlayerHat(hatName)

	local hatNameValue = GetNaviMultiValue(hatName, "Name")
	local name = hatNameValue:str()

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in the system in Lua: SetPlayerHat")
		return
	end

	kart:SetHat(name .. ".mesh")

end


function SetPlayerAccessory(accName)

	local accNameValue = GetNaviMultiValue(accName, "Name")
	local name = accNameValue:str()

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in the system in Lua: SetPlayerAccessory")
		return
	end

	kart:SetAccessory(name .. ".mesh")

end

function SetPlayerWheel(wheelName)

	local wheelNameValue = GetNaviMultiValue(wheelName, "Name")
	local name = wheelNameValue:str()

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in the system in Lua: SetPlayerWheel")
		return
	end

	kart:SetWheel(name .. ".mesh")

end


function SetPlayerKart(kartName)

	local kartNameValue = GetNaviMultiValue(kartName, "Name")
	local name = kartNameValue:str()

	local kart = GetCustomizeKart()

	if kart == nil then
		GetConsole():Print("No Kart in the system in Lua: SetPlayerKart")
		return
	end

	kart:SetKart(name .. ".mesh")

end