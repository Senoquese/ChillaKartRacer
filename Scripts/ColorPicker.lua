--Use the bit + hex library
UseModule("bit", "Scripts/luabit-0.4/")
UseModule("hex", "Scripts/luabit-0.4/")

local colorCallBack = nil
local red = nil
local green = nil
local blue = nil

function SetColorPickerCallback(callBack)

	colorCallBack = callBack;

end


function SendPickerColor(guiArgs)

	local colorValue = GetNaviMultiValue(guiArgs, "Color")
	local color = colorValue:str()
	local colorNum = hex.to_dec("0x" .. color)

	local red = bit.brshift(colorNum, 16) / 255
	local green = bit.brshift(colorNum, 8)
	green = bit.band(green, 255) / 255
	local blue = bit.band(colorNum, 255) / 255
	local alpha = 1

	if colorCallBack then
		colorCallBack(red, green, blue, alpha)
	end

end


function SetPickerColor(guiArgs)

	local colorValue = GetNaviMultiValue(guiArgs, "Color")
	local color = colorValue:str()

	local firstComma = string.find(color, ",", 0)
	local secondComma = string.find(color, ",", firstComma + 1)
	local endParen = string.find(color, ")", secondComma + 1)
	red = string.sub(color, 5, firstComma - 1)
	green = string.sub(color, firstComma + 1, secondComma - 1)
	blue = string.sub(color, secondComma + 1, endParen - 1)
	local jsCode = "manualSetColorBitch(" .. red .. "," .. green .. "," .. blue .. ");"
	if GetNaviGUISystem():IsPageActive("ColorPicker") then
		GetNaviGUISystem():GetPage("ColorPicker", true):EvaluateJS(jsCode)
	else
		if not GetScriptSystem():DoesAutoCallExist("InitColorPicker") then
			GetScriptSystem():AddAutoCall("InitColorPicker")
		end
	end

end


function InitColorPicker()

	local jsCode = "manualSetColorBitch(" .. red .. "," .. green .. "," .. blue .. ");"
	if GetNaviGUISystem():IsPageActive("ColorPicker") then
		GetNaviGUISystem():GetPage("ColorPicker", true):EvaluateJS(jsCode)
		GetScriptSystem():RemoveAutoCall("InitColorPicker")
	end

end