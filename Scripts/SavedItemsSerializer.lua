UseModule("IBase", "Scripts/")

--SAVEDITEMSSERIALIZER CLASS START

--The SavedItemsSerializer is for managing the loading and saving
--the saved item settings and reading/writing to them
class 'SavedItemsSerializer' (IBase)

function SavedItemsSerializer:__init() super()

	--Initial default settings
	self.settings = {
						Kart =
						{
							Name = "Basic Kart",
							Colors =
							{
								"0.1 0.5 1",
								"1 1 1",
								"0 0.2 .7",
								""
							}
						},
						Character =
						{
							Name = "Chinchilla",
							Colors =
							{
								"1 1 1",
								"1 1 1",
								"1 1 1",
								"1 0 0"
							}
						},
						Wheel = 
						{
							Name = "Race Tire",
							Colors =
							{
								"1 1 1",
								".15 .15 .15",
								".9 .9 .9",
								""
							}
						},
						Hat =
						{
							Name = "Chinchilla Visor",
							Colors =
							{
								"0.22 0.54 1",
								"1 0.25 1",
								"",
								""
							}
						},
						Accessory =
						{
							Name = "000None",
							Colors =
							{
								"0.1 0.5 1",
								"0.1 0.5 1",
								"0.55 0.65 0.75",
								""
							}
						},
					}

	--First load the user's character/kart settings
	self:LoadSettings()

end


function SavedItemsSerializer:BuildInterfaceDefIBase()

	self:AddClassDef("SavedItemsSerializer", "IBase", "Loads and saves the player's character layouts")

end


function SavedItemsSerializer:InitIBase()

end


function SavedItemsSerializer:UnInitIBase()

end


function SavedItemsSerializer:GetSettings()

	return self.settings

end


function SavedItemsSerializer:GetSettingsAsParameters()

	local params = Parameters()
	for settingName, settingValue in pairs(self:GetSettings()) do
		params:AddParameter(Parameter(settingName .. "Name", settingValue.Name))
		for colorIndex, colorValue in ipairs(settingValue.Colors) do
			local colorName = settingName .. "Color" .. tostring(colorIndex)
			params:AddParameter(Parameter(colorName, colorValue))
		end
	end
	return params

end


function SavedItemsSerializer:ApplyColors(kart)

	for settingName, settingValue in pairs(self:GetSettings()) do
		for colorIndex, colorValue in ipairs(settingValue.Colors) do
			if string.len(colorValue) > 0 then
				local colorName = "Color" .. tostring(colorIndex)
				local red = CustomItemParseColor(colorValue, CustomItem.RED)
				local green = CustomItemParseColor(colorValue, CustomItem.GREEN)
				local blue = CustomItemParseColor(colorValue, CustomItem.BLUE)
				if settingName == "Kart" then
					kart:SetKartColor(colorName, red, green, blue, 1)
				elseif settingName == "Character" then
					kart:SetCharacterColor(colorName, red, green, blue, 1)
				elseif settingName == "Wheel" then
					kart:SetWheelColor(colorName, red, green, blue, 1)
				elseif settingName == "Hat" then
					kart:SetHatColor(colorName, red, green, blue, 1)
				elseif settingName == "Accessory" then
					kart:SetAccessoryColor(colorName, red, green, blue, 1)
				end
			else
				break
			end
		end
	end

end


--Load the character/kart settings from the settings table
function SavedItemsSerializer:LoadSettings()

	for settingName, settingValue in pairs(self.settings) do
		local itemColors = settingValue.Colors
		local currentSetting = GetSettingTable():GetSetting("Custom" .. settingName .. "Name", "Shared", false)
		if IsValid(currentSetting) and string.len(currentSetting:GetStringData()) > 0 then
			settingValue.Name = currentSetting:GetStringData()
		else
			currentSetting = Parameter("Custom" .. settingName .. "Name", settingValue.Name)
			GetSettingTable():AddSetting(currentSetting, "Shared")
		end
		--Loop through setting colors
		for colorIndex, colorValue in ipairs(itemColors) do
			local currentColorSetting = GetSettingTable():GetSetting("Custom" .. settingName .. "Color" .. tostring(colorIndex), "Shared", false)
			if IsValid(currentColorSetting) then
				itemColors[colorIndex] = currentColorSetting:GetStringData()
			else
				currentSetting = Parameter("Custom" .. settingName .. "Color" .. tostring(colorIndex), colorValue)
				GetSettingTable():AddSetting(currentSetting, "Shared")
			end
		end
	end

end


function SavedItemsSerializer:SaveSettings()

	for settingName, settingValue in pairs(self.settings) do
		local itemColors = settingValue.Colors
		local currentSetting = GetSettingTable():GetSetting("Custom" .. settingName .. "Name", "Shared", false)
		if IsValid(currentSetting) and string.len(currentSetting:GetStringData()) > 0 then
			currentSetting:SetStringData(settingValue.Name)
		else
			currentSetting = Parameter("Custom" .. settingName .. "Name", settingValue.Name)
			GetSettingTable():AddSetting(currentSetting, "Shared")
		end
		--Loop through setting colors
		for colorIndex, colorValue in ipairs(itemColors) do
			local currentColorSetting = GetSettingTable():GetSetting("Custom" .. settingName .. "Color" .. tostring(colorIndex), "Shared", false)
			if IsValid(currentColorSetting) then
				currentColorSetting:SetStringData(colorValue)
			else
				currentColorSetting = Parameter("Custom" .. settingName .. "Color" .. tostring(colorIndex), colorValue)
				GetSettingTable():AddSetting(currentSetting, "Shared")
			end
		end
	end

end

--SAVEDITEMSSERIALIZER CLASS END