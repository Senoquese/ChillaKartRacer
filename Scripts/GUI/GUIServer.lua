--GUISERVER CLASS START
UseModule("ServerSettingsManager", "Scripts/")
class 'GUIServer' (IBase)

function GUIServer:__init() super()

	print("Starting Init in GUIServer:__init()")

	--Needed for the bug that causes a mouse up event to trigger off after
    --the X is pressed in the window that then takes input away from the game
    self.mouseReleasedSlot = self:CreateSlot("MouseReleased", "MouseReleased")
	GetInputSystem():GetSignal("MouseReleased", true):Connect(self.mouseReleasedSlot)

	--These params will be used for multiple signals that do not emit any parameters
	self.params = Parameters()
    self.clickParams = Parameters()

    --How often should the player tab update when the GUI is visible?
    self.updatePlayersTabTimer = WTimer(1)

    --SeverSettingsManager
    self.serverSettings = ServerSettingsManager()

    --Signals
    self.selectExitSignal = self:CreateSignal("ExitServer")
    self.startServerSignal = self:CreateSignal("StartServer")

    --Slots
    self.windowButtonSlot = self:CreateSlot("WindowButtonPress", "WindowButtonPress")
    self.serverKilledSlot = self:CreateSlot("ServerKilledSlot", "ServerKilledSlot")
    GetClientSystem():GetSignal("ServerKilled", true):Connect(self.serverKilledSlot)
    
    self.listChangePosSlot = self:CreateSlot("ListChangePosition","ListChangePosition") 

    --Load layout
    self.serverPrefix = "Server_"
	self.serverGUILayout = GetMyGUISystem():LoadLayout("server.layout", self.serverPrefix)
	self.serverCont = self.serverGUILayout:GetWidget(self.serverPrefix .. "server")

	--Setup Tabs
	self.tabCont = ToTab(self.serverCont:FindWidget(self.serverPrefix .. "servertabs"))
	self:SetupTabSetup()
	self:SetupTabPlayers()
	self:SetupTabLevels()
	self.tabClickSlot = self:CreateSlot("TabClicked", "TabClicked")
	GetMyGUISystem():RegisterEvent(self.tabCont, "eventTabChangeSelect", self.tabClickSlot)

    --Listen for escape key
    self.keyEventSlot = self:CreateSlot("KeyEvent","KeyEvent")
    GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)
    
    --Listen for close button
    GetMyGUISystem():RegisterEvent(self.serverCont, "eventWindowButtonPressed", self.windowButtonSlot)

end


function GUIServer:InitIBase()

end


function GUIServer:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.serverGUILayout)
	self.serverGUILayout = nil

end


function GUIServer:BuildInterfaceDefIBase()

	self:AddClassDef("GUIServer", "IBase", "The Server GUI manager")

end


function GUIServer:SetVisible(visible)

    --print("GUIServer:SetVisible:"..tostring(visible).." start")

    self.serverGUILayout:SetVisible(visible)
    if not visible then
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
        if IsValid(self.processSlot) then
            GetScriptSystem():GetSignal("ProcessEnd", true):Disconnect(self.processSlot)
            self.processSlot = nil
        end
    else
        local defaultTab = 0
        if GetClientSystem():GetServerProcessRunning() then
            defaultTab = 1
        else
            --self.tabCont:RemoveItemAt(2)
            --self.tabCont:InsertItem(self.playersTab, StringToUTFString("Players"), MyGUIAny())
        end
        self.tabCont:SetIndexSelected(defaultTab)

        self.loadMapButton:SetEnabled(GetClientSystem():GetServerProcessRunning())
        self.nextLevelButton:SetEnabled(GetClientSystem():GetServerProcessRunning())
        
        self:ShowInfoPanel(GetClientSystem():GetServerProcessRunning())
        self.processSlot = self:CreateSlot("Process", "Process")
        GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)
    end
    --print("GUIServer:SetVisible:"..tostring(visible).." end")
end


function GUIServer:GetVisible()

    return self.serverGUILayout:GetVisible()
    
end


function GUIServer:SaveServerSettings()

    self.serverSettings.serverName = self.serverName:GetOnlyText():AsUTF8()
    self.serverSettings.serverPass = self.serverPass:GetOnlyText():AsUTF8()
    self.serverSettings.minPlayers = self.minPlayers:GetItemNameAt(self.minPlayers:GetIndexSelected()):AsUTF8()
    self.serverSettings.maxPlayers = self.maxPlayers:GetItemNameAt(self.maxPlayers:GetIndexSelected()):AsUTF8()
    self.serverSettings.mapTime = self.mapTime:GetCaption():AsUTF8()
    self.serverSettings.kartCC = 150
    self.serverSettings.mapCycle = {}
    for j=0,self.mapCycleList:GetItemCount()-1 do
        local map = self.mapCycleList:GetItemNameAt(j):AsUTF8()
        table.insert(self.serverSettings.mapCycle, map)
    end

    self.serverSettings:WriteFile()

end


function GUIServer:SetupTabSetup()

    self.serverName = ToEdit(self.serverCont:FindWidget(self.serverPrefix .. "servername"))
	--self.serverPort = ToEdit(self.serverCont:FindWidget(self.serverPrefix .. "serverport"))
	self.serverPass = ToEdit(self.serverCont:FindWidget(self.serverPrefix .. "serverpassword"))
    self.maxPlayers = ToComboBox(self.serverCont:FindWidget(self.serverPrefix .. "servermaxplayers"))
    GetMyGUISystem():RegisterEvent(self.maxPlayers, "eventComboChangePosition", self.listChangePosSlot)
    self.minPlayers = ToComboBox(self.serverCont:FindWidget(self.serverPrefix .. "minplayers"))
    GetMyGUISystem():RegisterEvent(self.minPlayers, "eventComboChangePosition", self.listChangePosSlot)
    self.serverAnnounce = ToComboBox(self.serverCont:FindWidget(self.serverPrefix .. "announce"))

    self.serverStart = self.serverCont:FindWidget(self.serverPrefix .. "serverpower")
    GetMyGUISystem():RegisterEvent(self.serverStart, "eventMouseButtonClick", self.windowButtonSlot)

	self.maxPlayersComboBox = ToComboBox(self.serverCont:FindWidget(self.serverPrefix .. "servermaxplayers"))

    -- Info Panel
    self.infoCaption = self.serverCont:FindWidget(self.serverPrefix .. "infocaption")
    self.infoPanel = self.serverCont:FindWidget(self.serverPrefix .. "infopanel")
    self.infoSync = self.infoPanel:FindWidget(self.serverPrefix .. "syncrate")
    self.infoSFPS = self.infoPanel:FindWidget(self.serverPrefix .. "serverfps")
    self.infoPlayerCount = self.infoPanel:FindWidget(self.serverPrefix .. "serverplayers")
    self.infoDataIn = self.infoPanel:FindWidget(self.serverPrefix .. "datain")
    self.infoPPSIn = self.infoPanel:FindWidget(self.serverPrefix .. "ppsin")
    self.infoDataOut = self.infoPanel:FindWidget(self.serverPrefix .. "dataout")
    self.infoPPSOut = self.infoPanel:FindWidget(self.serverPrefix .. "ppsout")
    
    --get player name from settings table
    local paramPlayerName = GetSettingTable():GetSetting("PlayerName", "Shared", false)
    --if valid name found in settings, use it, otherwise add the default name to settings table
    if IsValid(paramPlayerName) then
        self.playerName = paramPlayerName:GetStringData()
    else
        -- initilize playerName to steam name if availible
        if IsValid(GetSteamClientSystem) then
            self.playerName = GetSteamClientSystem():GetLocalPlayerName()
            if string.len(self.playerName) == 0 then
                self.playerName = "Player" .. tostring(GenerateID())
            end
        end
    end 

    -- Default Values
    -- if GetDemoMode() then
    --     self.serverName:SetOnlyText(StringToUTFString("Demo"))
    --     self.serverName:SetEnabled(false)
    -- else
        self.serverName:SetOnlyText(StringToUTFString(tostring(self.serverSettings.serverName)))
    -- end
    self.serverPass:SetOnlyText(StringToUTFString(tostring(self.serverSettings.serverPass)))
    --self.serverPort:SetOnlyText( StringToUTFString("54322") )
    if self.serverSettings.maxPlayers > 12 or self.serverSettings.maxPlayers < 1 then
        self.serverSettings.maxPlayers = 12
    end
    self.maxPlayers:SetIndexSelected(self.serverSettings.maxPlayers-1)
    local tempMinPlayers = tonumber(self.serverSettings.minPlayers)
    --Min players must be one minus max players
    if tempMinPlayers >= self.serverSettings.maxPlayers then
        tempMinPlayers = self.serverSettings.maxPlayers-1
    elseif tempMinPlayers < 0 then
        tempMinPlayers = 0
    end
    self.minPlayers:SetIndexSelected(tempMinPlayers)
    -- if GetDemoMode() then
        --Demo mode only supports private servers
        -- self.serverAnnounce:SetIndexSelected(2)
    -- else
        self.serverAnnounce:SetIndexSelected(0)
    -- end

    self:ShowInfoPanel(false)

end


function GUIServer:RefreshSetupTab()

    self.serverSettings:ReadFile()
    self.maxPlayers:SetIndexSelected(self.serverSettings.maxPlayers-1)
    self.minPlayers:SetIndexSelected(self.serverSettings.minPlayers*1)
    self.serverAnnounce:SetIndexSelected(0)

end


function GUIServer:SetupTabPlayers()

    self.playersTab = ToTabItem(self.serverCont:FindWidget(self.serverPrefix .. "playerstab"))

    self.playerList = ToList(self.serverCont:FindWidget(self.serverPrefix .. "adminplayerlist"))
    self.playerTable = {}
    self.kickButton = self.serverCont:FindWidget(self.serverPrefix .. "kick")
    GetMyGUISystem():RegisterEvent(self.kickButton, "eventMouseButtonClick", self.windowButtonSlot)
    
    self.updatePlayersSlot = self:CreateSlot("UpdatePlayersTab", "UpdatePlayersTab")
    --These two signals will notify us when a client connects or disconnects from the server
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.updatePlayersSlot)
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.updatePlayersSlot)

end


function GUIServer:SetupTabLevels()

    self.mapCycleList = ToList(self.serverCont:FindWidget(self.serverPrefix .. "mapcycle"))
    self.mapList = ToList(self.serverCont:FindWidget(self.serverPrefix .. "maplist"))
    
    self.mapCycleDoubleClickSlot = self:CreateSlot("MapCycleDoubleClick","MapCycleDoubleClick")
    self.mapListDoubleClickSlot = self:CreateSlot("MapListDoubleClick","MapListDoubleClick")
    -- Only MultiLists send "eventListSelectAccept" events currently
    --GetMyGUISystem():RegisterEvent(self.mapCycleList, "eventListSelectAccept", self.mapCycleDoubleClickSlot)
    --GetMyGUISystem():RegisterEvent(self.mapList, "eventListSelectAccept", self.mapListDoubleClickSlot)
    
    self.addMapButton = self.serverCont:FindWidget(self.serverPrefix .. "addmap")
    self.removeMapButton = self.serverCont:FindWidget(self.serverPrefix .. "removemap")
    self.loadMapButton = self.serverCont:FindWidget(self.serverPrefix .. "loadmap")
    self.nextLevelButton = self.serverCont:FindWidget(self.serverPrefix .. "nextmap")
    
    GetMyGUISystem():RegisterEvent(self.addMapButton, "eventMouseButtonClick", self.windowButtonSlot)
    GetMyGUISystem():RegisterEvent(self.removeMapButton, "eventMouseButtonClick", self.windowButtonSlot)
    GetMyGUISystem():RegisterEvent(self.loadMapButton, "eventMouseButtonClick", self.windowButtonSlot)
    GetMyGUISystem():RegisterEvent(self.nextLevelButton, "eventMouseButtonClick", self.windowButtonSlot)

    self.mapTime = self.serverCont:FindWidget(self.serverPrefix .. "maptime")

    self:RefreshMapList()

end


function GUIServer:RefreshMapList()

    self.mapList:RemoveAllItems()
    self.mapCycleList:RemoveAllItems()

    --Add maps to GUI
    local mapListParams = ScanMaps(ASSET_DIR .. "\\Maps")
    local i = 0
    while i < mapListParams:GetNumberOfParameters() do
        local mapName = mapListParams:GetParameter(i, true):GetStringData()
        if mapName ~= "Garage" and mapName ~= "SpaceJump" then
            self.mapList:AddItem(StringToUTFString(mapName), MyGUIAny())
        end
        i = i + 1
    end

    self.serverSettings:ReadFile()
    local settingsMapCycle = self.serverSettings.mapCycle
    -- if GetDemoMode() then
        -- settingsMapCycle = { "ChampionCircuit", "KickIt" }
    -- end
    for i=1,#settingsMapCycle do
        local map = settingsMapCycle[i]

        --Remove from mapList
        for j=0,self.mapList:GetItemCount()-1 do
            local unmap = self.mapList:GetItemNameAt(j):AsUTF8()
            if unmap == map then
                self.mapList:RemoveItemAt(j)
                break
            end
        end

        self.mapCycleList:AddItem( StringToUTFString(map), MyGUIAny())
    end

    self.mapTime:SetCaption( StringToUTFString(tostring(self.serverSettings.mapTime)) )

end


function GUIServer:ShowInfoPanel(visible)

    self.infoCaption:SetVisible(visible)
    self.infoPanel:SetVisible(visible)

end


function GUIServer:KeyEvent(keyParams)

    local key = keyParams:GetParameter("Key", true):GetIntData()
    if self:GetVisible() and GetClientInputManager():GetKeyCodeMatches(key, "Escape") then
        self.selectExitSignal:Emit(self.params)
    end

end


function GUIServer:Process(processParams)
    
    -- Update server info pane
    if GetClientSystem():GetServerProcessRunning() and GetClientSystem():IsConnected() and
       IsValid(GetClientSystem():GetServerPeer()) then
        self.maxPlayers:SetEnabled(false)
        self.serverName:SetEnabled(false)
        self.serverAnnounce:SetEnabled(false)
        self.serverStart:SetEnabled(false)
        self.infoSync:SetCaption(StringToUTFString(tostring( 1 / GetClientWorld():GetServerSyncMaxRate() ).."/s"))
        self.infoSFPS:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetFramerate() )))
        self.infoPlayerCount:SetCaption(StringToUTFString(tostring( #self.playerTable + 1 )))
        self.infoDataIn:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetIncomingBandwidthPerSecond() / 1024 ).."/kbps"))
        self.infoPPSIn:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetNumberOfPacketsReceivedPerSecond() ).."/s"))
        self.infoDataOut:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetOutgoingBandwidthPerSecond() / 1024 ).."/kbps"))
        self.infoPPSOut:SetCaption(StringToUTFString(tostring( GetClientSystem():GetServerPeer():GetNumberOfPacketsSentPerSecond() ).."/s"))
    else
        self.maxPlayers:SetEnabled(true)
        self.serverName:SetEnabled(true)
        self.serverAnnounce:SetEnabled(true)
        self.serverStart:SetEnabled(true)
    end

    -- if GetDemoMode() then
    --     self.maxPlayers:SetEnabled(false)
    --     self.serverName:SetEnabled(false)
    --     self.serverAnnounce:SetEnabled(false)
    -- end

    if self:GetVisible() then
        if self.updatePlayersTabTimer:IsTimerUp() then
            self.updatePlayersTabTimer:Reset()
            self:UpdatePlayersTab()
        end
    end

end


function GUIServer:MapCycleDoubleClick(presParams)

    self.clickParams:GetOrCreateParameter("WidgetName"):SetStringData(self.loadMapButton:GetName())
    self:WindowButtonPress(clickParams)

end


function GUIServer:MapListDoubleClick(presParams)
    
    --self.clickParams

end


function GUIServer:WindowButtonPress(pressParams)

	local wname = pressParams:GetParameter("WidgetName", true):GetStringData()

	if wname == self.serverCont:GetName() then
		self.selectExitSignal:Emit(self.params)
		self.exitClicked = true
	elseif wname == self.serverStart:GetName() and self.serverStart:IsEnabled() then
	    self:SaveServerSettings()
		self.serverStart:SetEnabled(false)
		local numPlayersStr = self.maxPlayersComboBox:GetItemNameAt(self.maxPlayersComboBox:GetIndexSelected()):AsUTF8()
		local numPlayersSelected = tonumber(numPlayersStr)
		local serverName = self.serverName:GetOnlyText():AsUTF8()
		GetClientManager():SetCurrentServerName(serverName)
		self.params:GetOrCreateParameter("MaxNumClients"):SetIntData(numPlayersSelected)
		self.params:GetOrCreateParameter("ServerName"):SetStringData(serverName)
		self.params:GetOrCreateParameter("ServerType"):SetStringData(self.serverAnnounce:GetItemNameAt(self.serverAnnounce:GetIndexSelected()):AsUTF8())
		self.startServerSignal:Emit(self.params)
		--The server is starting now, put up the loading screen so the user isn't confused
		GetMenuManager():SetLoadingBackgroundVisible(true)
	elseif wname == self.nextLevelButton:GetName() then
	    if GetClientSystem():GetServerProcessRunning() then
	         CMD("GetServerManager():LoadNextMapInRotation()")
	    end
    elseif wname == self.kickButton:GetName() then
        local selIndex = self.playerList:GetIndexSelected()
        if selIndex > -1 and selIndex < #self.playerTable then
            local kickPlayer = self.playerTable[selIndex+1]
            print("Kicking playerIndex:"..kickPlayer:GetName())
            CMD("KICKID("..kickPlayer:GetUniqueID()..")")
        end
    elseif wname == self.addMapButton:GetName() then
        -- if GetDemoMode() then
            -- GetMenuManager():ShowDialogGeneral("Not available in the demo")
        -- else
            local listIndex = self.mapList:GetIndexSelected()
            if listIndex > -1 and listIndex < self.mapList:GetItemCount() then
                local addMap = self.mapList:GetItemNameAt(listIndex):AsUTF8()
                self.mapCycleList:AddItem( self.mapList:GetItemNameAt(listIndex), MyGUIAny())
                self.mapList:RemoveItemAt(listIndex)
                CMD("GetServerManager():AddMapToCycle(\""..addMap.."\")")
            end
        -- end
    elseif wname == self.removeMapButton:GetName() then
        -- if GetDemoMode() then
        --     GetMenuManager():ShowDialogGeneral("Not available in the demo")
        -- else
            local cycleIndex = self.mapCycleList:GetIndexSelected()
            if cycleIndex > -1 and cycleIndex < self.mapCycleList:GetItemCount() and self.mapCycleList:GetItemCount() > 1 then
                local delMap = self.mapCycleList:GetItemNameAt(cycleIndex):AsUTF8()
                self.mapList:AddItem( self.mapCycleList:GetItemNameAt(cycleIndex), MyGUIAny())
                self.mapCycleList:RemoveItemAt(cycleIndex)
                CMD("GetServerManager():RemoveMapFromCycle(\""..delMap.."\")")
            end
        -- end
    elseif wname == self.loadMapButton:GetName() then
        local cycleIndex = self.mapCycleList:GetIndexSelected()
        if cycleIndex > -1 and cycleIndex < self.mapCycleList:GetItemCount() then
            local selMap = self.mapCycleList:GetItemNameAt(cycleIndex):AsUTF8()
            print("GUI Server: Load map:"..selMap)
            CMD("GetServerManager():LoadMap(\""..selMap.."\")")
        end
    end

end


function GUIServer:MouseReleased(params)

    if self.exitClicked == true then
        self.exitClicked = false
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    end

end


function GUIServer:TabClicked(buttonParams)

	local newSelectedTab = buttonParams:GetParameter("Index", true):GetIntData()
	print("Tab clicked:"..newSelectedTab)

	if newSelectedTab == 0 then

	elseif newSelectedTab == 1 then

	elseif newSelectedTab == 2 then
	    -- Players
        self:UpdatePlayersTab()
    end

end


function GUIServer:ListChangePosition(params)
    local wname = params:GetParameter("WidgetName", true):GetStringData()
    print("list change postiion: "..wname)

    if wname == self.maxPlayers:GetName() then
        local newMax = self.maxPlayers:GetItemNameAt(self.maxPlayers:GetIndexSelected()):AsUTF8()
        local min = self.minPlayers:GetItemNameAt(self.minPlayers:GetIndexSelected()):AsUTF8()
        print("max: "..newMax.." min:"..min)
        if newMax <= min then
            self.minPlayers:SetIndexSelected(newMax - 1)
            print("GetServerManager():SetMinPlayers("..(newMax)..")")
            CMD("GetServerManager():SetMinPlayers("..(newMax)..")")
        end
        print("GetServerManager():SetMaxPlayers("..newMax..")")
        CMD("GetServerManager():SetMaxPlayers("..newMax..")")
    elseif wname == self.minPlayers:GetName() then
        local newMin = self.minPlayers:GetItemNameAt(self.minPlayers:GetIndexSelected()):AsUTF8()
        local max = self.maxPlayers:GetItemNameAt(self.maxPlayers:GetIndexSelected()):AsUTF8()
        if newMin >= max then
            newMin = max - 1
            self.minPlayers:SetIndexSelected(newMin)
        end
        --BRIAN TODO: Disabled until the issues related to changing min players are fixed
	    CMD("GetServerManager():SetMinPlayers("..newMin..")")
	    print("GetServerManager():SetMinPlayers("..newMin..")")
    end

end


function GUIServer:UpdatePlayersTab()

    local currentlySelectedPlayerIndex = self.playerList:GetIndexSelected()
    local currentlySelectedPlayer = ""
    if currentlySelectedPlayerIndex ~= GetMyGUISystem().ITEM_NONE then
        currentlySelectedPlayer = self.playerList:GetItemNameAt(currentlySelectedPlayerIndex):AsUTF8()
    end

    self.playerList:RemoveAllItems()
    self.playerTable = {}
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	local currListIndex = 0
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		if not player:IsLocalPlayer() then
		    self.playerList:AddItem(StringToUTFString(player:GetName()), MyGUIAny())
		    if player:GetName() == currentlySelectedPlayer then
		        self.playerList:SetIndexSelected(currListIndex)
		    end
		    table.insert(self.playerTable, player)
		    currListIndex = currListIndex + 1
		end
		i = i + 1
	end

end


function GUIServer:ServerKilledSlot(params)

	--The server has died, we can allow the user to start a new server
	self.serverStart:SetEnabled(true)

end

--GUISERVER CLASS END