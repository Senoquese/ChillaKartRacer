--GUISERVERBROWSER CLASS START

class 'GUIServerBrowser' (IBase)

function GUIServerBrowser:__init() super()

	print("Starting Init in GUIServerBrowser:__init()")
	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	self.serverSelectedData = {}
	self.serverSelected = false
	self.CustomIP = ""

	self.lobbiesRefreshed = true
	self.forceRefresh = false

	--This table stores all pending ping requests
	self.pingRequests = { }
	self.numServersPinged = 0

	self.highPingServerDetailsColor = "#555555"

    self.nameColIndex = 0
    self.levelColIndex = 1
    self.playersColIndex = 2
    self.countryColIndex = 3
    self.pingColIndex = 4

    self.nameColName = StringToUTFString("Server Name")
    self.levelColName = StringToUTFString("Level")
    self.playersColName = StringToUTFString("Players")
    self.pingColName = StringToUTFString("Ping")
    self.countryColName = StringToUTFString("Country")

    self.nameColWidth = 280
    self.levelColWidth = 116 + 46
    self.playersColWidth = 64
    self.pingColWidth = 64
    self.countryColWidth = 64

    --Signals
    self.selectExitSignal = self:CreateSignal("ExitServerBrowser")    
    self.connectToServerSignal = self:CreateSignal("ConnectToServer")

	self.refreshCompleteSlot = self:CreateSlot("RefreshComplete", "RefreshComplete")
	self.listUpdatedSlot =  self:CreateSlot("ListUpdated", "ListUpdated")
	self.lobbyDataUpdatedSlot = self:CreateSlot("LobbyDataUpdated", "LobbyDataUpdated")
	self.serverRespondedSlot = self:CreateSlot("ServerResponded", "ServerResponded")
	self.refreshInternetServersCompleteSlot = self:CreateSlot("RefreshInternetServersComplete", "RefreshInternetServersComplete")
	self.refreshLANServersCompleteSlot = self:CreateSlot("RefreshLANServersComplete", "RefreshLANServersComplete")
	if IsValid(GetSteamClientSystem) then
		GetSteamClientSystem():GetSignal("RefreshComplete", true):Connect(self.refreshCompleteSlot)
		GetSteamClientSystem():GetSignal("ListUpdated", true):Connect(self.listUpdatedSlot)
		GetSteamClientSystem():GetSignal("LobbyDataUpdated", true):Connect(self.lobbyDataUpdatedSlot)
		GetSteamClientSystem():GetSignal("ServerResponded", true):Connect(self.serverRespondedSlot)
		GetSteamClientSystem():GetSignal("RefreshInternetServersComplete", true):Connect(self.refreshInternetServersCompleteSlot)
		GetSteamClientSystem():GetSignal("RefreshLANServersComplete", true):Connect(self.refreshLANServersCompleteSlot)
	end

    self.leftButtonClickSlot = self:CreateSlot("LeftButtonClicked", "LeftButtonClicked")
    self.rightButtonClickSlot = self:CreateSlot("RightButtonClicked", "RightButtonClicked")
    self.mouseMoveSlot = self:CreateSlot("MouseMove", "MouseMove")

    --Load layout
    self.serverPrefix = "ServerBrowser_"
	self.serverGUILayout = GetMyGUISystem():LoadLayout("serverbrowser.layout", self.serverPrefix)
	self.serverCont = self.serverGUILayout:GetWidget(self.serverPrefix .. "serverbrowser")
	self.serverCont:SetCaption(StringToUTFString("0 Servers Found"))
	self.buttonJoin = ToButton(self.serverCont:FindWidget(self.serverPrefix .. "joinserver"))
	GetMyGUISystem():RegisterEvent(self.buttonJoin, "eventMouseButtonClick", self.leftButtonClickSlot)
	self.buttonRefresh = ToButton(self.serverCont:FindWidget(self.serverPrefix .. "refreshservers"))
	GetMyGUISystem():RegisterEvent(self.buttonRefresh, "eventMouseButtonClick", self.rightButtonClickSlot)
	self.ipBox = ToEdit(self.serverCont:FindWidget(self.serverPrefix .. "serveraddress"))
    self.multiList = ToMultiList(self.serverCont:FindWidget(self.serverPrefix .. "serverlist"))
    --We want to know about mouse over events so we can display info for a server that has the mouse over it
	--GetMyGUISystem():RegisterEvent(self.multiList, "eventMouseMove", self.mouseMoveSlot)

    self.mouseClickSlot = self:CreateSlot("MouseClickSlot", "MouseClickSlot")
    GetMyGUISystem():RegisterEvent(self.multiList, "eventListChangePosition", self.mouseClickSlot)
    --Listen for double click on list
    self.doubleClickSlot = self:CreateSlot("DoubleClickSlot", "DoubleClickSlot")
    GetMyGUISystem():RegisterEvent(self.multiList, "eventListSelectAccept", self.doubleClickSlot)

    --Create columns
    self.multiList:InsertColumnAt(self.nameColIndex, self.nameColName, self.nameColWidth, MyGUIAny());
    self.multiList:InsertColumnAt(self.levelColIndex, self.levelColName, self.levelColWidth, MyGUIAny());
    self.multiList:InsertColumnAt(self.playersColIndex, self.playersColName, self.playersColWidth, MyGUIAny());
    self.multiList:InsertColumnAt(self.countryColIndex, self.countryColName, self.countryColWidth, MyGUIAny());
    self.multiList:InsertColumnAt(self.pingColIndex, self.pingColName, self.pingColWidth, MyGUIAny());

    --Listen for escape key
    self.keyEventSlot = self:CreateSlot("KeyEvent","KeyEvent")
    GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)

    --Listen for close button
    self.windowButtonSlot = self:CreateSlot("WindowButtonPress","WindowButtonPress")
    GetMyGUISystem():RegisterEvent(self.serverCont, "eventWindowButtonPressed", self.windowButtonSlot)

    self.lobbies = { }
    self.LANServers = { }
    self.internetServers = { }

    GetMyGUISystem():SetupMultiListNumberCompare(self.multiList, false, self.pingColIndex)
    self.multiList:SortByColumn(self.pingColIndex, false)

    --Called when a request to only ping a server happens, not a full connection to the server
    self.connectPingRequestCompleteSlot = self:CreateSlot("ConnectPingRequestComplete", "ConnectPingRequestComplete")
    GetClientSystem():GetSignal("ConnectPingRequestComplete", true):Connect(self.connectPingRequestCompleteSlot)

    --Called when a ping request is cancelled for some reason
    self.pingRequestCancelledSlot = self:CreateSlot("PingRequestCancelled", "PingRequestCancelled")
    GetClientSystem():GetSignal("PingRequestCancelled", true):Connect(self.pingRequestCancelledSlot)

    self.processSlot = self:CreateSlot("Process", "Process")
    GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

    self.isFirstUpdate = true

	print("Finished Init in GUIServerBrowser:__init()")

end


function GUIServerBrowser:InitIBase()

end


function GUIServerBrowser:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.serverGUILayout)
	self.serverGUILayout = nil

end


function GUIServerBrowser:BuildInterfaceDefIBase()

	self:AddClassDef("GUIServerBrowser", "IBase", "The Server Browser GUI manager")

end


function GUIServerBrowser:Process(frameTime)

    --Ping the next top server in the request list
    if #self.pingRequests > 0 and GetClientSystem():GetState() == NetworkSystem.DISCONNECTED and not GetClientSystem():GetInRequestPingMode() then
        for index, lobby in ipairs(self.lobbies) do
            if lobby:GetAddress() == self.pingRequests[1] then
                local currIndex = lobby:GetIndex()
                --self.multiList:SetSubItemNameAt(self.pingColIndex, currIndex, StringToUTFString("..."))
                break
            end
        end
        GetClientSystem():RequestConnectPing(self.pingRequests[1])
    end

    if #self.pingRequests <= 0 then
        self.serverCont:SetCaption(StringToUTFString(tostring(self:GetTotalNumServers()) .. " Servers Found"))
    else
        self.serverCont:SetCaption(StringToUTFString(tostring(self:GetNumServersProcessed()) .. " out of " .. tostring(self:GetTotalNumServers()) .. " servers processed"))
    end

end


function GUIServerBrowser:SetVisible(visible)

    self.serverGUILayout:SetVisible(visible)
    if not visible then
        self.isFirstUpdate = true
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
        --Remove any pending ping requests
        self.pingRequests = { }
	else
		--Refresh when it becomes visible again
		self:RefreshServerList(false)
    end
    
end


function GUIServerBrowser:GetVisible()

    return self.serverGUILayout:GetVisible()
    
end


function GUIServerBrowser:KeyEvent(keyParams)

    local key = keyParams:GetParameter("Key", true):GetIntData()
    if self:GetVisible() and GetClientInputManager():GetKeyCodeMatches(key, "Escape") then
        self.selectExitSignal:Emit(self.nullParams)
    end

end


function GUIServerBrowser:RefreshComplete()

	print("Finished refreshing lobby list")
	self.lobbiesRefreshed = true

    --Don't bother pinging if the list was forced to refresh and
    --don't ping if there is a queued connect address
    if not self.forceRefresh and
       string.len(GetClientSystem():GetQueuedConnectAddress()) == 0 then
        if self.isFirstUpdate then
            self.isFirstUpdate = false
            self:PingServers()
        else
            --Start pinging all servers
            self:PingServers()
        end
    end

    self:CheckRefreshDone()

end


function GUIServerBrowser:ServerResponded(params)

    local serverType = params:GetParameter("ServerType", true):GetStringData()
    local serverIndex = params:GetParameter("Index", true):GetIntData()
    print("Server responded of type: " .. serverType)
    if serverType == "InternetServer" then
        local addInternetServer = GetSteamClientSystem():GetInternetServer(serverIndex)
        --First make sure there isn't already a LAN server for this
        if not self:GetServerIDInList(addInternetServer:GetSteamIDStr(), self.LANServers) then
		    self:AddServerToList(addInternetServer, self.internetServers)
		end
    elseif serverType == "LANServer" then
        local addLANServer = GetSteamClientSystem():GetLANServer(serverIndex)
        --Remove from the internet list if this server already exists in it
        if self:GetServerIDInList(addLANServer:GetSteamIDStr(), self.internetServers) then
            self:RemoveServerFromList(addLANServer, self.internetServers)
            --Now we need to add it to the LAN server list but not to the GUI list
            self:AddServerToList(addLANServer, self.LANServers, false)
        else
		    self:AddServerToList(addLANServer, self.LANServers)
		end
    end

end


function GUIServerBrowser:RefreshInternetServersComplete()

    print("Finished refreshing Internet server list")

	self.internetServersRefreshed = true
	self:CheckRefreshDone()

end


function GUIServerBrowser:RefreshLANServersComplete()

    print("Finished refreshing LAN server list")

	self.LANServersRefreshed = true
	self:CheckRefreshDone()

end


function GUIServerBrowser:CheckRefreshDone()

    if self.lobbiesRefreshed == true and
       self.internetServersRefreshed == true and
       self.LANServersRefreshed == true then
        self.buttonRefresh:SetEnabled(true)
        return true
    end
    return false

end


function GUIServerBrowser:GetTotalNumServers()

    return #self.lobbies + #self.internetServers + #self.LANServers

end


function GUIServerBrowser:GetNumServersProcessed()

    return self.numServersPinged + #self.internetServers + #self.LANServers

end


function GUIServerBrowser:ListUpdated()

    local i = 0
    self.lobbies = { }
	while i < GetSteamClientSystem():GetNumberLobbies() do
		local addLobby = GetSteamClientSystem():GetLobby(i)
		table.insert(self.lobbies, addLobby)
		i = i + 1
	end

end


function GUIServerBrowser:LobbyDataUpdated(lobbyParams)

	local lobbyAddress = lobbyParams:GetParameter("LobbyAddress", true):GetStringData()
	for index, lobby in ipairs(self.lobbies) do
		if lobby:GetAddress() == lobbyAddress then
			lobby:SetName(lobbyParams:GetParameter("LobbyName", true):GetStringData())
			self.multiList:SetSubItemNameAt(self.levelColIndex, lobby:GetIndex(), StringToUTFString(lobby:GetMapName()))
			local numPlayersStr = tostring(lobby:GetNumPlayers()) .. " / " .. tostring(lobby:GetTotalPlayerSlots())
			self.multiList:SetSubItemNameAt(self.playersColIndex, lobby:GetIndex(), StringToUTFString(numPlayersStr))
			self.multiList:SetSubItemNameAt(self.playersColIndex, lobby:GetIndex(), StringToUTFString(numPlayersStr))
			break
		end
	end

end


function GUIServerBrowser:AddLobbyToList(steamLobby)

	local lobbyName = steamLobby:GetName()
	local ping = steamLobby:GetPing()
	--A ping of < 0 indicates that a ping time hasn't been determined yet
	if ping < 0 then
	    ping = "?"
	end

    local currIndex = self.multiList:GetItemCount()
    steamLobby:SetIndex(currIndex)
    self.multiList:AddItem(StringToUTFString(lobbyName), MyGUIAny())
    self.multiList:SetSubItemNameAt(self.levelColIndex, currIndex, StringToUTFString(steamLobby:GetMapName()))
    --Only list real humans in the player count
    local numPlayersStr = tostring(steamLobby:GetNumHumanPlayers()) .. " / " .. tostring(steamLobby:GetTotalPlayerSlots())
    self.multiList:SetSubItemNameAt(self.playersColIndex, currIndex, StringToUTFString(numPlayersStr))
    self.multiList:SetSubItemNameAt(self.pingColIndex, currIndex, StringToUTFString(tostring(ping)))
    local countryStr = tostring(steamLobby:GetCountry())
    if countryStr == GetSteamClientSystem():GetLocalPlayerCountry() then
        countryStr = "#8EFF00" .. countryStr
    end
    self.multiList:SetSubItemNameAt(self.countryColIndex, currIndex, StringToUTFString(countryStr))

end


function GUIServerBrowser:AddServerToList(steamGameServer, toList, addToGUI)

    if addToGUI ~= false then
        addToGUI = true
    end

    if addToGUI then
        local serverName = steamGameServer:GetName()
        local pingVal = math.floor(steamGameServer:GetPing() * 1000)
        local ping = GetMenuManager():ColorPing(pingVal)

        local currIndex = self.multiList:GetItemCount()
        steamGameServer:SetIndex(currIndex)
        self.multiList:AddItem(StringToUTFString(serverName), MyGUIAny())
        self.multiList:SetSubItemNameAt(self.levelColIndex, currIndex, StringToUTFString(steamGameServer:GetMapName()))
        --Only list real humans in the player count
        local numPlayersStr = tostring(steamGameServer:GetNumHumanPlayers()) .. " / " .. tostring(steamGameServer:GetTotalPlayerSlots())
        self.multiList:SetSubItemNameAt(self.playersColIndex, currIndex, StringToUTFString(numPlayersStr))
        self.multiList:SetSubItemNameAt(self.pingColIndex, currIndex, StringToUTFString(tostring(ping)))

        local countryStr = steamGameServer:GetCountry()
        if countryStr == GetSteamClientSystem():GetLocalPlayerCountry() then
            countryStr = "#8EFF00" .. countryStr
        end
        self.multiList:SetSubItemNameAt(self.countryColIndex, currIndex, StringToUTFString(countryStr))

        if pingVal > GetMenuManager().highPingValue then
            self:ColorGrey(steamGameServer)
        end
    end

    table.insert(toList, steamGameServer)

    print("Added server named: " .. steamGameServer:GetName() .. " with address: " .. steamGameServer:GetAddress())

end


function GUIServerBrowser:RemoveServerFromList(removeServer, fromList)

    for index, server in ipairs(fromList) do
        if server:GetSteamIDStr() == removeServer:GetSteamIDStr() then
            table.remove(fromList, index)
            break
        end
    end

end


function GUIServerBrowser:RefreshServerList(forceRefresh)

    GetClientSystem():CancelPingRequest()

    --Start fresh
    self.pingRequests = { }

    --Do not refresh if the client is about to connect to a server
    if string.len(GetClientSystem():GetQueuedConnectAddress()) == 0 then
        self.forceRefresh = forceRefresh
        if self.forceRefresh == true or self.buttonRefresh:IsEnabled() then
            print("Refreshing server list...")
            --Clear all items before the refresh starts
            self.multiList:RemoveAllItems()
            if IsValid(GetSteamClientSystem) then
                self.lobbies = { }
                GetSteamClientSystem():RefreshLobbyList()
                self.lobbiesRefreshed = false
                self.internetServers = { }
                GetSteamClientSystem():RefreshInternetServerList()
                self.internetServersRefreshed = false
                self.LANServers = { }
                GetSteamClientSystem():RefreshLANServerList()
                self.LANServersRefreshed = false
            end
            self.buttonRefresh:SetEnabled(false)
        end
    end

end


function GUIServerBrowser:ServerSelected(params)

    local data = params:GetParameter(0, true):GetStringData()
    
    self.serverSelected = true

    self.serverSelectedData = WUtil_StringSplit(",", data)

end


function GUIServerBrowser:MouseClickSlot(params)

    print("GUIServerBrowser:MouseClickSlot called")
    local selectedServerIndex = self.multiList:GetIndexSelected()
    if selectedServerIndex ~= GetMyGUISystem().ITEM_NONE then
        local selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.lobbies)
        if not IsValid(selectedServer) then
            selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.LANServers)
        end
        if not IsValid(selectedServer) then
            selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.internetServers)
        end
        --This shouldn't happen, but just in case it does, prevent it from crashing
        if not IsValid(selectedServer) then
            print("Failing to find selected server in GUIServerBrowser:LeftButtonClicked(), this shouldn't happen!")
            return
        end
        print("Selected server address: " .. selectedServer:GetAddress())
    end

end


function GUIServerBrowser:DoubleClickSlot(params)

    self:LeftButtonClicked(self.nullParams)

end


--Called when the left button is pushed, this will connect to custom ip or selected server.
function GUIServerBrowser:LeftButtonClicked(buttonParams)

    local serverAddress = ""
    --local ipBoxText = self.ipBox:GetOnlyText():AsUTF8()

	local selectedServerIndex = self.multiList:GetIndexSelected()
    if selectedServerIndex ~= GetMyGUISystem().ITEM_NONE then
        local selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.lobbies)
        if not IsValid(selectedServer) then
            selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.LANServers)
        end
        if not IsValid(selectedServer) then
            selectedServer = self:GetServerAtMultiListIndex(selectedServerIndex, self.internetServers)
        end
        --This shouldn't happen, but just in case it does, prevent it from crashing
        if not IsValid(selectedServer) then
            print("Failing to find selected server in GUIServerBrowser:LeftButtonClicked(), this shouldn't happen!")
            return
        end
        serverAddress = selectedServer:GetAddress()
        GetClientManager():SetCurrentServerName(selectedServer:GetName())

        if GetClientSystem():GetState() == NetworkSystem.DISCONNECTED then
            GetClientManager():InitPlayerName()
            GetClientSystem():RequestConnect(serverAddress, SavedItemsSerializer():GetSettingsAsParameters())
            GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        else
            --If currently requesting ping, RequestConnect will cancel the ping request
            --but it will take time to disconnect, the connecting to server GUI normally
            --wouldn't be visible when disconnecting so we need to force it
            if GetClientSystem():GetInRequestPingMode() then
                GetMenuManager():SetForceConnGUIVis(true)
            end

            --Already connected so queue up this server connection
            GetClientSystem():SetQueuedConnectAddress(serverAddress)
            --Make sure no ping request interrupts the connection
            self.pingRequests = { }
        end
    end

end


--Called when the right button is pushed, this will refresh the server list.
function GUIServerBrowser:RightButtonClicked(buttonParams)

	self:RefreshServerList(false)

end


function GUIServerBrowser:MouseMove(moveParams)

    local top = moveParams:GetParameter("Top", true):GetIntData()
    local left = moveParams:GetParameter("Left", true):GetIntData()

    print("Mouse Move - Top: " .. tostring(top) .. " Left: " .. tostring(left))

end


--Called when the right button is pushed, this will exit the settings menu.
function GUIServerBrowser:WindowButtonPress(name)

    self.selectExitSignal:Emit(self.nullParams)

end


--Will ping the top numToPing servers passed in
function GUIServerBrowser:PingServers()

    self.numServersPinged = 0
    --Disallow pinging a server if the client is already connected to a server
    if GetClientSystem():GetState() ~= NetworkSystem.CONNECTED then
        local numServers = #self.lobbies
        local currIndex = 0
        while currIndex < numServers do
            local serverAddress = self.lobbies[currIndex + 1]:GetAddress()
            self:AddPingRequest(serverAddress)
            currIndex = currIndex + 1
        end
    end

end


function GUIServerBrowser:AddPingRequest(serverAddress)

    print("Adding ping request for server: " .. serverAddress)

    table.insert(self.pingRequests, serverAddress)

end


function GUIServerBrowser:ConnectPingRequestComplete(params)

    local pingTime = params:GetParameter("PingTime", true):GetFloatData()
    local serverAddress = params:GetParameter("ServerAddress", true):GetStringData()
    print("Received ping time: " .. tostring(pingTime) .. " for server: " .. serverAddress)

    --Find this lobby in the list and update it's ping time
    for index, lobby in ipairs(self.lobbies) do
		if lobby:GetAddress() == serverAddress then
		    self.numServersPinged = self.numServersPinged + 1
		    lobby:SetPing(pingTime)
            --Now that we have a ping time we can safely display it
            self:AddLobbyToList(lobby)
            local currIndex = lobby:GetIndex()
            local pingVal = math.floor(pingTime * 1000)
            local pingStr = GetMenuManager():ColorPing(pingVal)
            self.multiList:SetSubItemNameAt(self.pingColIndex, currIndex, StringToUTFString(pingStr))
            if pingVal > GetMenuManager().highPingValue then
                self:ColorGrey(lobby)
            end
            break
        end
    end

    --Find the request in the ping request list and remove it
    for pIndex, pRequest in ipairs(self.pingRequests) do
        if pRequest == serverAddress then
            table.remove(self.pingRequests, pIndex)
            break
        end
    end

end


function GUIServerBrowser:PingRequestCancelled(params)

    print("GUIServerBrowser:PingRequestCancelled!!!!")

    local serverAddress = params:GetParameter("ServerAddress", true):GetStringData()

    --Mark it in the list as ":(" as we were unable to find out the ping
    for index, lobby in ipairs(self.lobbies) do
		if lobby:GetAddress() == serverAddress then
		    self.numServersPinged = self.numServersPinged + 1
            break
        end
    end

    --Remove the request from the list
    for pIndex, pRequest in ipairs(self.pingRequests) do
        if pRequest == serverAddress then
            table.remove(self.pingRequests, pIndex)
            break
        end
    end

end


function GUIServerBrowser:ColorGrey(server)

    local currIndex = server:GetIndex()
    self.multiList:SetSubItemNameAt(self.nameColIndex, currIndex, StringToUTFString(self.highPingServerDetailsColor .. server:GetName()))
    self.multiList:SetSubItemNameAt(self.levelColIndex, currIndex, StringToUTFString(self.highPingServerDetailsColor .. server:GetMapName()))
    local numPlayersStr = tostring(server:GetNumHumanPlayers()) .. " / " .. tostring(server:GetTotalPlayerSlots())
    self.multiList:SetSubItemNameAt(self.playersColIndex, currIndex, StringToUTFString(self.highPingServerDetailsColor .. numPlayersStr))
    self.multiList:SetSubItemNameAt(self.countryColIndex, currIndex, StringToUTFString(self.highPingServerDetailsColor .. server:GetCountry()))

end


function GUIServerBrowser:GetServerAtMultiListIndex(listIndex, inList)

    local serverName = self.multiList:GetSubItemNameAt(self.nameColIndex, listIndex):AsUTF8()
    for index, server in ipairs(inList) do
        --Strip out any color codes from the multiList server name
        if StringStrip(serverName, "#", 6) == server:GetName() then
            return server
        end
    end
end


function GUIServerBrowser:GetServerIDInList(steamIDStr, inList)

    for index, server in ipairs(inList) do
        if server:GetSteamIDStr() == steamIDStr then
            return true
        end
    end
    return false

end

--GUISERVERBROWSER CLASS END