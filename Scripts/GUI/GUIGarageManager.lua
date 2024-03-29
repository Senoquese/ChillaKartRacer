UseModule("IBase", "Scripts/")
UseModule("GUIGarageItemPicker", "Scripts/GUI/")
UseModule("GUIGarageColorPicker", "Scripts/GUI/")

--GUIGARAGEMANAGER CLASS START

class 'GUIGarageManager' (IBase)

function GUIGarageManager:__init(kart, kartSettings) super()

	self.kartSettings = kartSettings

	--Third param is max number of colors
	self.garageItemPicker = GUIGarageItemPicker(kart, self.kartSettings, CustomItem.MAX_NUM_COLORS)
	--Always start out invisible
	self.garageItemPicker:SetVisible(false)
	self.garageColorPicker = GUIGarageColorPicker()
	self.garageColorPicker:Init()
	print("GUIGarageManager.garageColorPicker = "..tostring(IsValid(self.garageColorPicker)))
	
	self.selectSaveAndExitSlot = self:CreateSlot("SelectSaveAndExit", "SelectSaveAndExit")
	self.garageItemPicker:GetSignal("SelectSaveAndExit"):Connect(self.selectSaveAndExitSlot)

	self.selectExitSlot = self:CreateSlot("SelectExit", "SelectExit")
	self.garageItemPicker:GetSignal("SelectExit"):Connect(self.selectExitSlot)

	self.itemSelectedSlot = self:CreateSlot("ItemSelected", "ItemSelected")
	self.garageItemPicker:GetSignal("ItemSelected"):Connect(self.itemSelectedSlot)
	self.itemSelectedSignal = self:CreateSignal("ItemSelected")
	
	self.randomizeItemsSlot = self:CreateSlot("RandomizeItems", "RandomizeItems")
	self.garageItemPicker:GetSignal("RandomizeItems"):Connect(self.randomizeItemsSlot)
	self.randomizeItemsSignal = self:CreateSignal("RandomizeItems")

	self.colorPickSlot = self:CreateSlot("ColorPick", "ColorPick")
	self.garageColorPicker:GetSignal("ColorPick"):Connect(self.colorPickSlot)

	self.closePickerSlot = self:CreateSlot("ClosePicker", "ClosePicker")
	self.garageColorPicker:GetSignal("ClosePicker"):Connect(self.closePickerSlot)

	self.exitSignal = self:CreateSignal("Exit")
	self.exitParams = Parameters()

	self.colorPickSignal = self:CreateSignal("ColorPick")
	self.colorPickParams = Parameters()

	self.garageItemPicker:SetVisible(true)
	self.garageItemPicker:Init()

end


function GUIGarageManager:BuildInterfaceDefIBase()

	self:AddClassDef("GUIGarageManager", "IBase", "Manages all the GUIs in the garage scene")

end


function GUIGarageManager:InitIBase()

end


function GUIGarageManager:UnInitIBase()

	if IsValid(self.garageItemPicker) then
		self.garageItemPicker:UnInit()
		self.garageItemPicker = nil
	end

	if IsValid(self.garageColorPicker) then
		self.garageColorPicker:UnInit()
		self.garageColorPicker = nil
	end

end


function GUIGarageManager:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function GUIGarageManager:GetEnabled()

	return self.enabled

end


function GUIGarageManager:SelectSaveAndExit()

	self.exitParams:GetOrCreateParameter("Save"):SetBoolData(true)
	self.exitSignal:Emit(self.exitParams)

end


function GUIGarageManager:SelectExit()

	self.exitParams:GetOrCreateParameter("Save"):SetBoolData(false)
	self.exitSignal:Emit(self.exitParams)

end

function GUIGarageManager:RandomizeItems(randParam)
	self.randomizeItemsSignal:Emit(randParam)
end

function GUIGarageManager:ItemSelected(selectedParam)

	--Pull out the category and item name
	local category = selectedParam:GetParameter("Category", true):GetStringData()
	local name = selectedParam:GetParameter("Name", true):GetStringData()
	
	--Save Category
	print("GUIGarageManager:ItemSelected BEGIN ============================")
	print("oldCategory: "..tostring(self.currentCategory))
	print("newCategory: "..category)
	self.currentCategory = category
	
	--Get item details from the CustomItemSystem
	local itemList = GetCustomItemSystem():GetItemTypeGroup(category, true)
	local item = itemList:GetItem(name, true)
	
	--Get the equipped item name for this category
	local equippedItemName = nil
	local equippedColors = nil
	if category == "Karts" then
		equippedItemName = self.kartSettings:GetSettings().Kart.Name
		equippedColors = self.kartSettings:GetSettings().Kart.Colors
	elseif category == "Characters" then
		equippedItemName = self.kartSettings:GetSettings().Character.Name
		equippedColors = self.kartSettings:GetSettings().Character.Colors
	elseif category == "Wheels" then
		equippedItemName = self.kartSettings:GetSettings().Wheel.Name
		equippedColors = self.kartSettings:GetSettings().Wheel.Colors
	elseif category == "Accessories" then
		equippedItemName = self.kartSettings:GetSettings().Accessory.Name
		equippedColors = self.kartSettings:GetSettings().Accessory.Colors
	elseif category == "Hats" then
		equippedItemName = self.kartSettings:GetSettings().Hat.Name
		equippedColors = self.kartSettings:GetSettings().Hat.Colors
	end

	print("equippedItemName: "..equippedItemName)
	print("selectedItemName: "..name)

	local numColors = item:GetNumColors()
	--Create and send color info to ColorPicker for this item
	local currentColor = 0
	while currentColor < CustomItem.MAX_NUM_COLORS and currentColor < numColors do
		local colorStr = nil
		print("** setting color: "..currentColor+1)
		if name == equippedItemName then
			colorStr = equippedColors[currentColor+1]
			print("using equipped color:"..colorStr)
		else
			colorStr = tostring(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.RED))
			colorStr = colorStr .. " " .. tostring(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.GREEN))
			colorStr = colorStr .. "  " .. tostring(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.BLUE))
			print("using item color:"..colorStr)
			--[[
			self.colorPickParams:GetOrCreateParameter(0):SetFloatData(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.RED))
			self.colorPickParams:GetOrCreateParameter(1):SetFloatData(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.GREEN))
			self.colorPickParams:GetOrCreateParameter(2):SetFloatData(item:GetColor("Color" .. tostring(currentColor + 1), CustomItem.BLUE))
			self.colorPickParams:GetOrCreateParameter(3):SetStringData(category)
			self.colorPickParams:GetOrCreateParameter(4):SetIntData(currentColor+1)
			self.colorPickSignal:Emit(self.colorPickParams)
			--]]
		end
				
		--Set bucket color
		print("** setting bucket "..currentColor+1)
		self.garageColorPicker:SetBucketColor(currentColor, colorStr)
		print("** done setting bucket "..currentColor+1)	    
	
		currentColor = currentColor + 1
	end

	--Get number of colors for this item and set ColorPicker bucket count
	--NOTE: We must set the bucket count AFTER setting all the bucket colors
	self.garageColorPicker:SetBucketCount(numColors)

	--Repeat this signal on to the GarageManager
	if name ~= equippedItemName then
		self.itemSelectedSignal:Emit(selectedParam)
	end
	
	print("GUIGarageManager:ItemSelected END ============================")
	
end


function GUIGarageManager:ColorPick(colorParams)

	local red = colorParams:GetParameter(0, true):GetFloatData()
	local green = colorParams:GetParameter(1, true):GetFloatData()
	local blue = colorParams:GetParameter(2, true):GetFloatData()
	local colorBucketIndex = colorParams:GetParameter(3, true):GetIntData()
	self.currentColorIndex = colorBucketIndex + 1

	--print("emitting GUIGarageManager color pick")

	if IsValid(self.currentColorIndex) and IsValid(self.currentCategory) then
		self.colorPickParams:GetOrCreateParameter(0):SetFloatData(red)
		self.colorPickParams:GetOrCreateParameter(1):SetFloatData(green)
		self.colorPickParams:GetOrCreateParameter(2):SetFloatData(blue)
		self.colorPickParams:GetOrCreateParameter(3):SetStringData(self.currentCategory)
		self.colorPickParams:GetOrCreateParameter(4):SetIntData(self.currentColorIndex)
		self.colorPickSignal:Emit(self.colorPickParams)

		--print("done emitting GUIGarageManager color pick")

	end

end


function GUIGarageManager:ClosePicker(closeParams)

	self.garageColorPicker:SetVisible(false)

end

--GUIGARAGEMANAGER CLASS END