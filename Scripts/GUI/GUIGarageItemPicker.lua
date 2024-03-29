--GUIGARAGEITEMPICKER CLASS START

class 'GUIGarageItemPicker' (IBase)

function GUIGarageItemPicker:__init(kart, kartSettings, maxNumColors) super()

	self.kart = kart
	self.kartSettings = kartSettings
	self.maxNumColors = maxNumColors

	self.switchCategory = Parameters()
	self.setCustomItemParams = Parameters()

    self.itemClickSlot = self:CreateSlot("ItemClicked", "ItemClicked")
    self.tabClickSlot = self:CreateSlot("TabClicked", "TabClicked")
	
	self.itemSelectParams = Parameters()
	self.itemSelectSignal = self:CreateSignal("ItemSelected")
	
	self.randParams = Parameters()
	self.randomizeItemsSignal = self:CreateSignal("RandomizeItems")
	
	self.selectSaveAndExitSignal = self:CreateSignal("SelectSaveAndExit")
	self.selectExitSignal = self:CreateSignal("SelectExit")
	
	self.selectionParams = Parameters()
	
	-- Load layout
	self.ipickerPrefix = "ItemPicker_"
	self.ipickerGUILayout = GetMyGUISystem():LoadLayout("garage.layout", self.ipickerPrefix)
    self.tabCont = ToTab(self.ipickerGUILayout:GetWidget(self.ipickerPrefix .. "itemtabs"))
    self.navCont = self.ipickerGUILayout:GetWidget(self.ipickerPrefix .. "nav")
    self.buttonRandom = self.ipickerGUILayout:GetWidget(self.ipickerPrefix .. "randomize")
    self.buttonSave = ToButton(self.navCont:FindWidget(self.ipickerPrefix .. "save"))
    self.buttonExit = ToButton(self.navCont:FindWidget(self.ipickerPrefix .. "exit"))
    self.navClickSlot = self:CreateSlot("NavButtonClick", "NavButtonClick")
	GetMyGUISystem():RegisterEvent(self.buttonSave, "eventMouseButtonClick", self.navClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonExit, "eventMouseButtonClick", self.navClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonRandom, "eventMouseButtonClick", self.navClickSlot)
	
	--tab panes
	GetMyGUISystem():RegisterEvent(self.tabCont, "eventTabChangeSelect", self.tabClickSlot)

    self.kartPane = ToScrollView(self.tabCont:FindWidget(self.ipickerPrefix .. "kartbox"))
	self.charPane = ToScrollView(self.tabCont:FindWidget(self.ipickerPrefix .. "charbox"))
	self.wheelPane = ToScrollView(self.tabCont:FindWidget(self.ipickerPrefix .. "wheelbox")) 
    self.hatPane = ToScrollView(self.tabCont:FindWidget(self.ipickerPrefix .. "hatbox"))
	self.accessPane = ToScrollView(self.tabCont:FindWidget(self.ipickerPrefix .. "accbox"))

    --item db
    self.kartNames = {}
    self.charNames = {}
    self.wheelNames = {}
    self.hatNames = {}
    self.accessNames = {}
	
	self.eKart = nil
	self.eChar = nil
	self.eWheel = nil
	self.eHat = nil
	self.eAccess = nil
	
	self.cKart = nil
	self.cChar = nil
	self.cWheel = nil
	self.cHat = nil
	self.cAccess = nil
	
	self.kartSelectBg = nil
	self.charSelectBg = nil
	self.wheelSelectBg = nil
	self.hatSelectBg = nil
	self.accessSelectBg = nil
	
	self:LoadCategory("Karts")
	self:LoadCategory("Characters")
	self:LoadCategory("Wheels")
	self:LoadCategory("Hats")
	self:LoadCategory("Accessories")
 
    self:InitGUISignalsAndSlots() 
   
end


function GUIGarageItemPicker:InitGUISignalsAndSlots()

end

function GUIGarageItemPicker:BuildInterfaceDefIBase()

	self:AddClassDef("GUIGarageItemPicker", "IBase", "The Garage Item Picker GUI manager")

end

function GUIGarageItemPicker:SetVisible(visible)

    self.ipickerGUILayout:SetVisible(visible)
    
end

function GUIGarageItemPicker:GetVisible()

    self.ipickerGUILayout:GetVisible()
    
end

function GUIGarageItemPicker:InitIBase()
    
    self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Karts")
    self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Kart.Name)
    self.itemSelectSignal:Emit(self.itemSelectParams)
    
end


function GUIGarageItemPicker:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.ipickerGUILayout)
	self.ipickerGUILayout = nil

end

function GUIGarageItemPicker:NavButtonClick(pressedParams)

    local wname = pressedParams:GetParameter("WidgetName", true):GetStringData()

    if wname == self.buttonSave:GetName() then
        
        print("GUIGarageItemPicker:NavButtonClick, SAVE");
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Exit.wav", WVector3(),0.5, 10, false, SoundSystem.MEDIUM)
        self.selectSaveAndExitSignal:Emit(self.selectionParams)
 
    elseif wname == self.buttonExit:GetName() then
    
        print("GUIGarageItemPicker:NavButtonClick, EXIT");
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Exit.wav", WVector3(),0.5, 10, false, SoundSystem.MEDIUM)  
        self.selectExitSignal:Emit(self.selectionParams)
    
    elseif wname == self.buttonRandom:GetName() then
    
           self.randomizeItemsSignal:Emit(self.randParams)
           self:UpdateTab(0)
           self:UpdateTab(1)
           self:UpdateTab(2)
           self:UpdateTab(3)
           self:UpdateTab(4)
           
    end

end

function GUIGarageItemPicker:LoadCategory(newCategory)

	--Pass the total number of items in this catagory
	local totalNum = GetCustomItemSystem():GetItemTypeGroup(newCategory, true):GetNumItems()
	
	print("GUIGarageItemPicker:LoadCategory:"..newCategory..", "..totalNum)
	
	local itemName = ""
	local colors = { }
	local tabPane = nil
	local selectBg = nil
	local nameArr = nil
    if newCategory == "Karts" then
		itemName = self.kartSettings:GetSettings().Kart.Name
		self.eKart = itemName
		self.cKart = itemName
		colors = self.kartSettings:GetSettings().Kart.Colors
		tabPane = self.kartPane
		nameArr = self.kartNames
		selectBg = self.kartSelectBg
	elseif newCategory == "Characters" then
		itemName = self.kartSettings:GetSettings().Character.Name
		self.eChar = itemName
		self.cChar = itemName
        colors = self.kartSettings:GetSettings().Character.Colors
		tabPane = self.charPane
		nameArr = self.charNames
		selectBg = self.charSelectBg
	elseif newCategory == "Wheels" then
		itemName = self.kartSettings:GetSettings().Wheel.Name
		self.eWheel = itemName
		self.cWheel = itemName
		colors = self.kartSettings:GetSettings().Wheel.Colors
		tabPane = self.wheelPane
		nameArr = self.wheelNames
		selectBg = self.wheelSelectBg
	elseif newCategory == "Hats" then
		itemName = self.kartSettings:GetSettings().Hat.Name
		self.eHat = itemName
		self.cHat = itemName
		colors = self.kartSettings:GetSettings().Hat.Colors
		tabPane = self.hatPane
		nameArr = self.hatNames
		selectBg = self.hatSelectBg
	elseif newCategory == "Accessories" then
		itemName = self.kartSettings:GetSettings().Accessory.Name
		self.eAccess = itemName
		self.cAccess = itemName
		colors = self.kartSettings:GetSettings().Accessory.Colors
		tabPane = self.accessPane
		nameArr = self.accessNames
		selectBg = self.accessSelectBg
	end

    -- Create select bg
    selectBg = ToStaticImage(tabPane:CreateWidget("StaticImage","StaticImage",MyGUIIntCoord(0,0,96,96),MyGUIAlign(MyGUIAlign.Default),newCategory.."_selectBg"))
    selectBg:SetImageTexture("equipped.png")

    if newCategory == "Karts" then
		self.kartSelectBg = selectBg
	elseif newCategory == "Characters" then
		self.charSelectBg = selectBg
	elseif newCategory == "Wheels" then
		self.wheelSelectBg = selectBg
	elseif newCategory == "Hats" then
		self.hatSelectBg = selectBg
	elseif newCategory == "Accessories" then
		self.accessSelectBg = selectBg
	end

	local itemList = GetCustomItemSystem():GetItemTypeGroup(newCategory, true)
	local iter = itemList:GetIterator()
	local equippedIndex = 0
	local currentIndex = 0
	local iconSize = 96
	local numCols = math.floor(tabPane:GetSize().width/iconSize)
	while not iter:IsEnd() do
		local currentItem = iter:Get()
		local name = currentItem:GetName()
		
		table.insert(nameArr, name)
		--print("currentItem:"..name)
		local equippedItem = false
        if name == itemName then
			equippedIndex = currentIndex
			local numColors = currentItem:GetNumColors()
			equippedItem = true
		end
		
		-- insert into item box
		print("valid tabPane:"..tostring(IsValid(tabPane)))
		if IsValid(tabPane) then
		    local itemImage = ToStaticImage(tabPane:CreateWidget("StaticImage","StaticImage",MyGUIIntCoord(0,0,96,96),MyGUIAlign(MyGUIAlign.Default),name))
		    GetMyGUISystem():RegisterEvent(itemImage, "eventMouseButtonClick", self.itemClickSlot)
		    local imagePath = currentItem:GetIconPath()
		    print("Setting item image:"..imagePath)
		    itemImage:SetImageTexture(imagePath)
		    local itemX = currentIndex%numCols*iconSize
		    local itemY = math.floor(currentIndex/numCols)*iconSize
		    itemImage:SetPosition(MyGUIIntPoint(itemX,itemY))
		    if equippedItem then
		        selectBg:SetPosition(itemImage:GetPosition())
		    end
		end
		
		currentIndex = currentIndex + 1
		iter:Next()
	end

    local canvasWidth = numCols*iconSize
    local canvasHeight = math.ceil(currentIndex/numCols)*iconSize
    tabPane:SetCanvasSize(MyGUIIntSize(canvasWidth,canvasHeight))

end

function GUIGarageItemPicker:TabClicked(buttonParams)

	local newSelectedTab = buttonParams:GetParameter("Index", true):GetIntData()

    local curTab = self.tabCont:GetIndexSelected()
    print("TabClicked:"..curTab..","..tostring(self.lastTab))
    if not IsValid(self.lastTab) or self.lastTab ~= curTab then
        self.lastTab = curTab
        local sound = nil
        if newSelectedTab == 0 then
            sound = "sound/Karts.wav"
			self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Karts")
			self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Kart.Name)
		elseif newSelectedTab == 1 then
		    sound = "sound/Wheels.wav"
			self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Wheels")
			self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Wheel.Name)
		elseif newSelectedTab == 2 then
			sound = "sound/Characters.wav"
            self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Characters")
			self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Character.Name)
		elseif newSelectedTab == 3 then
		    sound = "sound/Accessories.wav"
			self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Accessories")
			self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Accessory.Name)
		elseif newSelectedTab == 4 then
		    sound = "sound/Hats.wav"
			self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData("Hats")
			self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(self.kartSettings:GetSettings().Hat.Name)
		end
		
		-- Play sound
		if IsValid(sound) then
		    GetSoundSystem():EmitSound(ASSET_DIR .. sound, WVector3(),1.0, 10, false, SoundSystem.MEDIUM)
		end
		
		-- Send signal
        self.itemSelectSignal:Emit(self.itemSelectParams)
		
    end
    
end

function GUIGarageItemPicker:UpdateTab(tabIndex)

    local tabPane = nil
    if tabIndex == 0 then
        itemName = self.kartSettings:GetSettings().Kart.Name
        colors = self.kartSettings:GetSettings().Kart.Colors
		category = "Karts"    
        tabPane = self.kartPane
		selectBg = self.kartSelectBg
		
	elseif tabIndex == 2 then
	    itemName = self.kartSettings:GetSettings().Character.Name
        colors = self.kartSettings:GetSettings().Character.Colors
	    category = "Characters"
		tabPane = self.charPane
		selectBg = self.charSelectBg
		
	elseif tabIndex == 1 then
	    itemName = self.kartSettings:GetSettings().Wheel.Name
        colors = self.kartSettings:GetSettings().Wheel.Colors
	    category = "Wheels"
		tabPane = self.wheelPane
		selectBg = self.wheelSelectBg
		
	elseif tabIndex == 4 then
	    itemName = self.kartSettings:GetSettings().Hat.Name
        colors = self.kartSettings:GetSettings().Hat.Colors
	    category = "Hats"
		tabPane = self.hatPane
		selectBg = self.hatSelectBg
		
	elseif tabIndex == 3 then
	    itemName = self.kartSettings:GetSettings().Accessory.Name
        colors = self.kartSettings:GetSettings().Accessory.Colors
	    category = "Accessories"
		tabPane = self.accessPane
		selectBg = self.accessSelectBg
	end
	
	selectBg:SetPosition(tabPane:FindWidget(itemName):GetPosition())
	if tabIndex == self.tabCont:GetIndexSelected() then
         -- Send signal to the GUIGarageManager
        self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData(category)
        self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(itemName)
        self.itemSelectSignal:Emit(self.itemSelectParams)
	end

end

function GUIGarageItemPicker:ItemClicked(buttonParams)

	local wname = buttonParams:GetParameter("WidgetName", true):GetStringData()
	
    print("ItemCliked:"..wname)

    local tabPane = nil
	local selectBg = nil
	local newItem = nil
	local category = nil
	
    if self.tabCont:GetIndexSelected() == 0 then
		category = "Karts"    
        tabPane = self.kartPane
		selectBg = self.kartSelectBg
		
	elseif self.tabCont:GetIndexSelected() == 2 then
	    category = "Characters"
		tabPane = self.charPane
		selectBg = self.charSelectBg
		
	elseif self.tabCont:GetIndexSelected() == 1 then
	    category = "Wheels"
		tabPane = self.wheelPane
		selectBg = self.wheelSelectBg
		
	elseif self.tabCont:GetIndexSelected() == 4 then
	    category = "Hats"
		tabPane = self.hatPane
		selectBg = self.hatSelectBg
		
	elseif self.tabCont:GetIndexSelected() == 3 then
	    category = "Accessories"
		tabPane = self.accessPane
		selectBg = self.accessSelectBg
	end
	
	newItem = ToStaticImage(self.tabCont:FindWidget(wname))
    selectBg:SetPosition(newItem:GetPosition())
    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Item_Clicks.wav", WVector3(),1.0, 10, false, SoundSystem.MEDIUM)    
    
    -- Send signal to the GUIGarageManager
    self.itemSelectParams:GetOrCreateParameter("Category"):SetStringData(category)
    self.itemSelectParams:GetOrCreateParameter("Name"):SetStringData(wname)
    self.itemSelectSignal:Emit(self.itemSelectParams)

end

--GUIGARAGEITEMPICKER CLASS END