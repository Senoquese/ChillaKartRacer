--GUIROSTER CLASS START

class 'GUIRoster' (IBase)

function GUIRoster:__init() super()

	self.params = Parameters()
	self.playerList = { }
    self.manuallyControlled = false

    self.playerColIndex = 0
    self.scoreColIndex = 1
    self.pingColIndex = 2

    self.playerColName = StringToUTFString("InitText")
    self.scoreColName = StringToUTFString("InitText")
    self.pingColName = StringToUTFString("InitText")

    self.playerColWidth = 368
    self.scoreColWidth = 160
    self.pingColWidth = 64

    self.rosterPrefix = "Roster_"
	self.rosterGUILayout = GetMyGUISystem():LoadLayout("roster.layout", self.rosterPrefix)
	self.rosterCont = self.rosterGUILayout:GetWidget(self.rosterPrefix .. "roster")

    self.multiList = ToMultiList(self.rosterCont:FindWidget(self.rosterPrefix .. "playerlist"))
    self.kickCheck = ToButton(self.rosterCont:FindWidget(self.rosterPrefix .. "kickcheck"))
    self.muteCheck = ToButton(self.rosterCont:FindWidget(self.rosterPrefix .. "mutecheck"))
    self.hideCheck = ToButton(self.rosterCont:FindWidget(self.rosterPrefix .. "hidecheck"))

	self.mouseClickSlot = self:CreateSlot("MouseClick", "MouseClick")
	self.listSelectedSlot = self:CreateSlot("ListSelected", "ListSelected")
	self.listChangePosSlot = self:CreateSlot("ListChangePosition", "ListChangePosition")
	GetMyGUISystem():RegisterEvent(self.rosterCont:FindWidget(self.rosterPrefix .. "kickcheck"), "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.rosterCont:FindWidget(self.rosterPrefix .. "mutecheck"), "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.rosterCont:FindWidget(self.rosterPrefix .. "hidecheck"), "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.rosterCont:FindWidget(self.rosterPrefix .. "playerlist"), "eventListSelectAccept", self.listSelectedSlot)
	GetMyGUISystem():RegisterEvent(self.rosterCont:FindWidget(self.rosterPrefix .. "playerlist"), "eventListChangePosition", self.listChangePosSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Init the localized text
	self:InitText()
	
	--Create columns
	self.multiList:InsertColumnAt(self.playerColIndex, self.playerColName, self.playerColWidth, MyGUIAny());
	self.multiList:InsertColumnAt(self.scoreColIndex, self.scoreColName, self.scoreColWidth, MyGUIAny());
	self.multiList:InsertColumnAt(self.pingColIndex, self.pingColName, self.pingColWidth, MyGUIAny());
	
	--Hide buttons until a row is selected
	self:HideButtons()
	
	-- Listen for show players key
    self.keyEventSlot = self:CreateSlot("KeyEvent","KeyEvent")
    GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)
    
    self.rosterClock = WTimer()
    self.pingUpdateTimer = 1.0
    self.processSlot = self:CreateSlot("Process", "Process")
    GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)
    
    self:SetScoreSorting(true)    

end

function GUIRoster:SetScoreSorting(descending)

    print("GUIRoster:SetScoreSorting: "..tostring(descending))
    
	GetMyGUISystem():SetupMultiListNumberCompare(self.multiList, descending, self.scoreColIndex)
    self.multiList:SortByColumn(self.scoreColIndex, false)

end

function GUIRoster:HideButtons()
    self.kickCheck:SetVisible(false)
    self.muteCheck:SetVisible(false)
    self.hideCheck:SetVisible(false)
    
    self.kickCheck:SetStateCheck(false)
    self.muteCheck:SetStateCheck(false)
    self.hideCheck:SetStateCheck(false)
end

function GUIRoster:ShowButtons()

    local selIndex = self.multiList:GetIndexSelected()
    if selIndex > -1 and selIndex < #self.playerList then
        local selPlayerData = self.playerList[selIndex+1]
        --kick = 0, audioMute = 0, visualMute = 0
        self.kickCheck:SetStateCheck(selPlayerData.kick ~= 0)
        self.muteCheck:SetStateCheck(selPlayerData.audioMute ~= 0)
        self.hideCheck:SetStateCheck(selPlayerData.visualMute ~= 0)
    end

    --BRIAN TODO: Don't show until these are functional
    --self.kickCheck:SetVisible(true)
    --self.muteCheck:SetVisible(true)
    --self.hideCheck:SetVisible(true)

end


function GUIRoster:Process()

    if self:GetVisible() then
        if self.rosterClock:GetTimeSeconds() > self.pingUpdateTimer then
            self.rosterClock:Reset()
            for index, playerData in ipairs(self.playerList) do
                --print("Updating player ping:"..playerData.uniqueID)
                local player = GetPlayerManager():GetPlayerFromID(playerData.uniqueID)
                if IsValid(player) then
                    local playerPing = self:GetPlayerPing(player)
                    self.multiList:SetSubItemNameAt(self.pingColIndex, index-1, StringToUTFString(tostring(playerPing)))
                end
            end
        end
    end

end


function GUIRoster:MouseClick(pressedParams)

    --[[
    print("MOUSECLICK")
    local wname = pressedParams:GetParameter("WidgetName", true):GetStringData()
    print("Mouse pressed! wiget: " .. wname)

    local selIndex = self.multiList:GetIndexSelected()
    print("selIndex:"..selIndex)
    print("#self.playerList:"..#self.playerList)
    if selIndex > -1 and selIndex < #self.playerList then
        local selPlayerData = self.playerList[selIndex+1]
        print("wname:"..wname)
        if wname == self.rosterPrefix .. "kickcheck" then
            print("kickcheck pressed:"..tostring(self.kickCheck:GetButtonPressed()))
            if self.kickCheck:GetButtonPressed() then
                self.kickCheck:SetButtonPressed(false)
                selPlayerData.kick = 0
            else
                self.kickCheck:SetButtonPressed(true)
                selPlayerData.kick = 1
            end
        elseif wname == self.rosterPrefix .. "mutecheck" then
            if self.muteCheck:GetButtonPressed() then
                self.muteCheck:SetButtonPressed(false)
                selPlayerData.audioMute = 0
            else
                self.muteCheck:SetButtonPressed(true)
                selPlayerData.audioMute = 1
            end
        elseif wname == self.rosterPrefix .. "hidecheck" then
            if self.hideCheck:GetButtonPressed() then
                self.hideCheck:SetButtonPressed(false)
                selPlayerData.visualMute = 0
            else
                self.hideCheck:SetButtonPressed(true)
                selPlayerData.visualMute = 1
            end
        end
    end
    --]]

end


function GUIRoster:KeyEvent(keyParams)

end


function GUIRoster:ListSelected(selectedParams)

    local index = selectedParams:GetParameter("Index", true):GetIntData()
    print("List selected at index: " .. tostring(index))

end


function GUIRoster:ListChangePosition(selectedParams)

    local index = selectedParams:GetParameter("Index", true):GetIntData()
    print("List position change at index: " .. tostring(index))
    if index > -1 then
        --self:ShowButtons()
    else
        self:HideButtons()
    end

end


function GUIRoster:BuildInterfaceDefIBase()

	self:AddClassDef("GUIRoster", "IBase", "The player roster GUI manager")

end

function GUIRoster:InitIBase()

end


function GUIRoster:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.rosterGUILayout)
	self.rosterGUILayout = nil

end

function GUIRoster:SetVisible(visible)
    self.rosterGUILayout:SetVisible(visible)
end

function GUIRoster:GetVisible()
    return self.rosterGUILayout:GetVisible()
end

function GUIRoster:InitText()

	--[[
    local textParams = Parameters()

	textParams:GetOrCreateParameter("Text"):SetStringData("Player")
	self.flashPage:CallFunction("setPlayerTitle", textParams)

	textParams:GetOrCreateParameter("Text"):SetStringData("Score")
	self.flashPage:CallFunction("setScoreTitle", textParams)

	textParams:GetOrCreateParameter("Text"):SetStringData("Ping")
	self.flashPage:CallFunction("setPingTitle", textParams)
    ]]--
    
    self.playerColName = StringToUTFString("Player")
    self.scoreColName = StringToUTFString("Score")
    self.pingColName = StringToUTFString("Ping")
    
end


function GUIRoster:SetManuallyControlled(setControlled)

	self.manuallyControlled = setControlled
	--self.playerList = { }
	self:UpdateRoster()

end


function GUIRoster:GetManuallyControlled()

	return self.manuallyControlled

end


--{ uniqueID = player:GetUniqueID(), name = player:GetName(), color = "FFFFFF", 
--	score = 0, ping = 0, kick = "0", audioMute = "0", visualMute = "0" }
function GUIRoster:UpdateRoster(newlist)

    --Update title
    self.rosterCont:SetCaption(StringToUTFString(GetSteamClientSystem():GetCurrentServerName().." - "..GetClientManager():GetCurrentMapName()))

    if IsValid(newlist) then
        self.playerList = newlist
    end

	--[[First clear the roster
	self.params:Clear()
	self.flashPage:CallFunction("clearItems", self.params)

	for index, playerData in ipairs(playerList) do
		self.params:Clear()
		self.params:AddParameter(Parameter("", playerData.color))
		local kick = 0
		if playerData.kick then kick = "1" else kick = "0" end
		local audioMute = 0
		if playerData.audioMute then audioMute = "1" else audioMute = "0" end
		local visualMute = 0
		if playerData.visualMute then visualMute = "1" else visualMute = "0" end
		local combinedData = playerData.name .. "," .. tostring(playerData.score) .. "," ..
							 tostring(playerData.ping) .. "," .. kick .. "," .. audioMute .. ","
							 .. visualMute
		self.params:AddParameter(Parameter("", combinedData))
		self.flashPage:CallFunction("addItem", self.params)
	end --]]

    local prevSelectedIndex = self.multiList:GetIndexSelected()
    self.multiList:RemoveAllItems()

    for index, playerData in ipairs(self.playerList) do
        --playerData.listIndex = index-1
        self.multiList:AddItem(StringToUTFString("#"..playerData.color..playerData.name), MyGUIAny())
        self.multiList:SetSubItemNameAt(self.scoreColIndex, index-1, StringToUTFString(tostring(playerData.score)))
        local player = GetPlayerManager():GetPlayerFromID(playerData.uniqueID)
        local playerPing = self:GetPlayerPing(player)
        self.multiList:SetSubItemNameAt(self.pingColIndex, index-1, StringToUTFString(tostring(playerPing)))
    end

    if prevSelectedIndex >= 0 and prevSelectedIndex < self.multiList:GetItemCount() then
        self.multiList:SetIndexSelected(prevSelectedIndex)
    end

end


function GUIRoster:GetPlayerPing(forPlayer)

    local playerPing = nil
    --We don't need to show bot ping times
    if forPlayer:GetBot() then
        playerPing = "#8EFF00BOT"
    else
        playerPing = math.ceil(forPlayer:GetPing() * 1000)
        playerPing = GetMenuManager():ColorPing(playerPing)
    end
    return playerPing

end


function GUIRoster:ClientConnected(connectParams)

	--if not self.manuallyControlled then
	    
		local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
		local player = GetPlayerManager():GetPlayerFromID(playerID)
		local setColor = "B9FD01"
		if player:IsLocalPlayer() then
			setColor = "FFFFFF"
		end
		table.insert(self.playerList, { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor,
										score = 0, ping = 0, kick = 0, audioMute = 0, visualMute = 0 })
		self:UpdateRoster()
	--end

end


function GUIRoster:ClientDisconnected(disconnectParams)

	--if not self.manuallyControlled then
		local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
		for index, playerData in ipairs(self.playerList) do
			if playerID == playerData.uniqueID then
				table.remove(self.playerList, index)
				self:UpdateRoster()
				return
			end
		end
	--end

end


--GUIROSTER CLASS END