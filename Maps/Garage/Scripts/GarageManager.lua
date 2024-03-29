UseModule("IBase", "Scripts/")
UseModule("CamControllerRotator", "Scripts/Modifiers/CameraControllers/")
UseModule("GUIGarageManager", "Scripts/GUI/")
UseModule("CustomItemManager", "Scripts/")
UseModule("SavedItemsSerializer", "Scripts/")

--GARAGEMANAGER CLASS START

class 'GarageManager' (IBase)

function GarageManager:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GarageManager in init")
	end

	self.camera = GetCamera()
	self.camera:SetPosition(WVector3(-1.41207, 0.739875, 3.11587))
	self.camera:SetOrientation(WQuaternion(0.971916, -0.103902, -0.209952, -0.02244448))

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	self.exitSignal = self:CreateSignal("Exit")

	self.worldModel = ToOGREModel(self.map:GetMapObject("SingleWorldMesh", true):Get())
	self.garageRotator = CamControllerRotator(self.worldModel, GetCamera(), 1.5, 3.5, 0.348, 1.7)
	--Only enabled when the user presses a button
	if IsValid(self.garageRotator) then
		self.garageRotator:SetEnabled(false)
		--But allow the zoom to be enabled always
		self.garageRotator:SetZoomEnabled(true)
		GetCameraManager():AddController(self.garageRotator, 2)
	end

	self.mousePressedSlot = self:CreateSlot("MousePressed", "MousePressed")
	--GetClientInputManager():GetSignal("MousePressed", true):Connect(self.mousePressedSlot)
	GetClientInputManager():GetSignal("KeyPressedIgnoreFocus", true):Connect(self.mousePressedSlot)
	self.mouseReleasedSlot = self:CreateSlot("MouseReleased", "MouseReleased")
	--GetClientInputManager():GetSignal("MouseReleased", true):Connect(self.mouseReleasedSlot)
	GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.mouseReleasedSlot)

	self.keyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	GetClientInputManager():GetSignal("KeyPressed", true):Connect(self.keyPressedSlot)
	self.keyReleasedSlot = self:CreateSlot("KeyReleased", "KeyReleased")
	GetClientInputManager():GetSignal("KeyReleased", true):Connect(self.keyReleasedSlot)

	self:InitSettings()
	self:InitCustomGraphics()

	--Rescan for items
	--GetCustomItemManager():ScanItems()

	self:InitGUI()

end


function GarageManager:BuildInterfaceDefIBase()

	self:AddClassDef("GarageManager", "IBase", "Manages everything in the garage scene")

end


function GarageManager:InitIBase()

end


function GarageManager:InitSettings()

	self.settingsSerializer = SavedItemsSerializer()

end


--Init the kart, character, and whatever else to display in the garage
function GarageManager:InitCustomGraphics()

	local spawnParams = self.settingsSerializer:GetSettingsAsParameters()

	--Extra params
	spawnParams:AddParameter(Parameter("Scale", WVector3(1.5, 1.5, 1.5)))
	spawnParams:AddParameter(Parameter("WheelConnectionX", 0.354*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionY", 0.12*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZFront", 0.282*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZBack", -0.3*1.5))
	spawnParams:AddParameter(Parameter("CastShadows", true))
	spawnParams:AddParameter(Parameter("ReceiveShadows", false))

	self.kart = OGREPlayerKart()
	--Don't flatten the colors in the garage
	self.kart:SetFlattenColors(false)
	--Don't spin the wheels in the garage
	self.kart:SetProcessWheelSpin(false)
	self.kart:SetName("GarageKart")
	self.kart:Init(spawnParams)
	self.kart:SetSpeedPercent(1.0)

	--Set the colors for the items
	self.settingsSerializer:ApplyColors(self.kart)

end


function GarageManager:UnInitCustomGraphics()

	if IsValid(self.kart) then
		self.kart:UnInit()
		self.kart = nil
	end

end


function GarageManager:InitGUI()

	self.garageManager = GUIGarageManager(self.kart, self.settingsSerializer)
	self.garageManager:SetEnabled(true)

    self.randomizeSlot = self:CreateSlot("RandomizeItems", "RandomizeItems")
    self.garageManager:GetSignal("RandomizeItems"):Connect(self.randomizeSlot)

    self.itemSelectedSlot = self:CreateSlot("ItemSelected","ItemSelected")
	self.garageManager:GetSignal("ItemSelected"):Connect(self.itemSelectedSlot)

	self.colorPickSlot = self:CreateSlot("ColorPick", "ColorPick")
	self.garageManager:GetSignal("ColorPick"):Connect(self.colorPickSlot)

	self.exitSlot = self:CreateSlot("Exit", "Exit")
	self.garageManager:GetSignal("Exit"):Connect(self.exitSlot)

end


function GarageManager:UnInitIBase()

	if IsValid(self.garageRotator) then
		self.garageRotator:SetEnabled(false)
		if IsValid(GetCameraManager()) then
			GetCameraManager():RemoveController(self.garageRotator)
		end
		self.garageRotator:UnInit()
		self.garageRotator = nil
	end

	self:UnInitGUI()

	self:UnInitCustomGraphics()

end


function GarageManager:UnInitGUI()

	if IsValid(self.garageManager) then
		self.garageManager:UnInit()
		self.garageManager = nil
	end

end

function GarageManager:ItemSelected(itemSelectParams)

	local category = itemSelectParams:GetParameter("Category", true):GetStringData()
	local name = itemSelectParams:GetParameter("Name", true):GetStringData()
	

    --Equip if not already equipped
    if category == "Karts" then
        self.kart:SetKart(name)
        self.settingsSerializer:GetSettings().Kart.Name = name
    elseif category == "Characters" then
        print("Setting character in GarageManager")
        self.kart:SetCharacter(name)
        self.settingsSerializer:GetSettings().Character.Name = name
    elseif category == "Wheels" then
        self.kart:SetWheel(name)
        self.settingsSerializer:GetSettings().Wheel.Name = name
    elseif category == "Accessories" then
        self.kart:SetAccessory(name)
        self.settingsSerializer:GetSettings().Accessory.Name = name
    elseif category == "Hats" then
        self.kart:SetHat(name)
        self.settingsSerializer:GetSettings().Hat.Name = name
    end

end

function GarageManager:RandomizeItems()
    
    local kartCenter = self.kart:GetPosition()-WVector3(0,0.5,0)
    local camToKart = self.camera:GetPosition()-kartCenter
    camToKart:Normalise()
    GetParticleSystem():AddEffect("poof", camToKart*1.5)
    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poof.wav", self.kart:GetPosition(), 1, 10, true, SoundSystem.LOWEST)
    
    -- Karts
    local itemList = GetCustomItemSystem():GetItemTypeGroup("Karts", true)
    local item = itemList:QueryItems( math.modf((Random() * itemList:GetNumItems()) + 0), 1 ):GetIterator():Get()
    self.kart:SetKart(item:GetName())
    self.settingsSerializer:GetSettings().Kart.Name = item:GetName()
    local cc = 1
    while cc <= item:GetNumColors() do
        self.settingsSerializer:GetSettings().Kart.Colors[cc] = item:GetColor("Color"..cc, CustomItem.RED).." "..item:GetColor("Color"..cc, CustomItem.GREEN).." "..item:GetColor("Color"..cc, CustomItem.BLUE)
        cc = cc+1
    end
    
    -- Characters
    itemList = GetCustomItemSystem():GetItemTypeGroup("Characters", true)
    item = itemList:QueryItems( math.modf((Random() * itemList:GetNumItems()) + 0), 1 ):GetIterator():Get()
    self.kart:SetCharacter(item:GetName())
    self.settingsSerializer:GetSettings().Character.Name = item:GetName()
    cc = 1
    while cc <= item:GetNumColors() do
        self.settingsSerializer:GetSettings().Character.Colors[cc] = item:GetColor("Color"..cc, CustomItem.RED).." "..item:GetColor("Color"..cc, CustomItem.GREEN).." "..item:GetColor("Color"..cc, CustomItem.BLUE)
        cc = cc+1
    end
    
    -- Wheels
    itemList = GetCustomItemSystem():GetItemTypeGroup("Wheels", true)
    item = itemList:QueryItems( math.modf((Random() * itemList:GetNumItems()) + 0), 1 ):GetIterator():Get()
    self.kart:SetWheel(item:GetName())
    self.settingsSerializer:GetSettings().Wheel.Name = item:GetName()
    cc = 1
    while cc <= item:GetNumColors() do
        self.settingsSerializer:GetSettings().Wheel.Colors[cc] = item:GetColor("Color"..cc, CustomItem.RED).." "..item:GetColor("Color"..cc, CustomItem.GREEN).." "..item:GetColor("Color"..cc, CustomItem.BLUE)
        cc = cc+1
    end
    
    -- Accessories
    itemList = GetCustomItemSystem():GetItemTypeGroup("Accessories", true)
    item = itemList:QueryItems( math.modf((Random() * itemList:GetNumItems()) + 0), 1 ):GetIterator():Get()
    self.kart:SetAccessory(item:GetName())
    self.settingsSerializer:GetSettings().Accessory.Name = item:GetName()
    cc = 1
    while cc <= item:GetNumColors() do
        self.settingsSerializer:GetSettings().Accessory.Colors[cc] = item:GetColor("Color"..cc, CustomItem.RED).." "..item:GetColor("Color"..cc, CustomItem.GREEN).." "..item:GetColor("Color"..cc, CustomItem.BLUE)
        cc = cc+1
    end
    
    -- Hats
    itemList = GetCustomItemSystem():GetItemTypeGroup("Hats", true)
    item = itemList:QueryItems( math.modf((Random() * itemList:GetNumItems()) + 0), 1 ):GetIterator():Get()
    self.kart:SetHat(item:GetName())
    self.settingsSerializer:GetSettings().Hat.Name = item:GetName()
    cc = 1
    while cc <= item:GetNumColors() do
        self.settingsSerializer:GetSettings().Hat.Colors[cc] = item:GetColor("Color"..cc, CustomItem.RED).." "..item:GetColor("Color"..cc, CustomItem.GREEN).." "..item:GetColor("Color"..cc, CustomItem.BLUE)
        cc = cc+1
    end

    

end

function GarageManager:Process()

	if IsValid(self.kart) then
		self.kart:Process(GetFrameTime())
	end

end


function GarageManager:ColorPick(colorParams)

	local red = colorParams:GetParameter(0, true):GetFloatData()
	local green = colorParams:GetParameter(1, true):GetFloatData()
	local blue = colorParams:GetParameter(2, true):GetFloatData()
	local currentCategory = colorParams:GetParameter(3, true):GetStringData()
	local currentColorIndex = colorParams:GetParameter(4, true):GetIntData()

    print("GarageManager:ColorPick: "..currentCategory..", "..currentColorIndex..", "..red..","..green..","..blue)

	if currentCategory == "Karts" then
		self.settingsSerializer:GetSettings().Kart.Colors[currentColorIndex] = tostring(red) .. " " .. tostring(green) .. " " .. tostring(blue)
		if IsValid(self.kart) then
			self.kart:SetKartColor("Color" .. tostring(currentColorIndex), red, green, blue, 1)
		end
	elseif currentCategory == "Characters" then
		self.settingsSerializer:GetSettings().Character.Colors[currentColorIndex] = tostring(red) .. " " .. tostring(green) .. " " .. tostring(blue)
		if IsValid(self.kart) then
			self.kart:SetCharacterColor("Color" .. tostring(currentColorIndex), red, green, blue, 1)
		end
	elseif currentCategory == "Wheels" then
		self.settingsSerializer:GetSettings().Wheel.Colors[currentColorIndex] = tostring(red) .. " " .. tostring(green) .. " " .. tostring(blue)
		if IsValid(self.kart) then
			self.kart:SetWheelColor("Color" .. tostring(currentColorIndex), red, green, blue, 1)
		end
	elseif currentCategory == "Hats" then
		self.settingsSerializer:GetSettings().Hat.Colors[currentColorIndex] = tostring(red) .. " " .. tostring(green) .. " " .. tostring(blue)
		if IsValid(self.kart) then
			self.kart:SetHatColor("Color" .. tostring(currentColorIndex), red, green, blue, 1)
		end
	elseif currentCategory == "Accessories" then
		self.settingsSerializer:GetSettings().Accessory.Colors[currentColorIndex] = tostring(red) .. " " .. tostring(green) .. " " .. tostring(blue)
		if IsValid(self.kart) then
			self.kart:SetAccessoryColor("Color" .. tostring(currentColorIndex), red, green, blue, 1)
		end
	end

end


function GarageManager:Exit(exitParams)

	local save = exitParams:GetParameter("Save", true):GetBoolData()
	if save then
		self:SaveSettings()
	end

	self.exitSignal:Emit(exitParams)

end


function GarageManager:MousePressed(mouseParams)

	local button = mouseParams:GetParameter("Key", true):GetIntData()
	if button == StringToKeyCode("MB_LEFT") then
		if IsValid(self.garageRotator) then
			self.garageRotator:SetEnabled(true)
		end
	end

end


function GarageManager:MouseReleased(mouseParams)

	local button = mouseParams:GetParameter("Key", true):GetIntData()
	if button == StringToKeyCode("MB_LEFT") then
		if IsValid(self.garageRotator) then
			self.garageRotator:SetEnabled(false)
		end
	end

end


function GarageManager:SaveSettings()

	self.settingsSerializer:SaveSettings()
	--Force the settings to save to disk here
	GetSettingTable():ForceSave("Shared")

end


function GarageManager:KeyPressed(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()

	if GetClientInputManager():GetKeyCodeMatches(key, "ControlLeft") then
		if IsValid(self.kart) then
			self.kart:ControlLeft(true)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlRight") then
		if IsValid(self.kart) then
			self.kart:ControlRight(true)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlReverse") then
		if IsValid(self.kart) then
			self.kart:ControlLookBack(true)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlAccel") then
		if IsValid(self.kart) then
			self.kart:SetWipeoutEnabled(true)
		end
	end

end


function GarageManager:KeyReleased(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()

	if GetClientInputManager():GetKeyCodeMatches(key, "ControlLeft") then
		if IsValid(self.kart) then
			self.kart:ControlLeft(false)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlRight") then
		if IsValid(self.kart) then
			self.kart:ControlRight(false)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlReverse") then
		if IsValid(self.kart) then
			self.kart:ControlLookBack(false)
		end
	elseif GetClientInputManager():GetKeyCodeMatches(key, "ControlAccel") then
		if IsValid(self.kart) then
			self.kart:SetWipeoutEnabled(false)
		end
	end

end

--GARAGEMANAGER CLASS END