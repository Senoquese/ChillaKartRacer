UseModule("IBase", "Scripts/")
--Files for the different GUIs
UseModule("GUIMainMenu", "Scripts/GUI/")
UseModule("GUISettings", "Scripts/GUI/")
UseModule("GUIHelp", "Scripts/GUI/")
UseModule("GUIServerBrowser", "Scripts/GUI/")
UseModule("GUIServer", "Scripts/GUI/")
UseModule("GUIEscapeMenu", "Scripts/GUI/")
UseModule("GUIDialogRequireRestart", "Scripts/GUI/")
UseModule("GUIDialogGeneral", "Scripts/GUI/")
UseModule("GUIMainMenuBackground", "Scripts/GUI/")
UseModule("GUILoadingBackground", "Scripts/GUI/")
UseModule("GUIChat", "Scripts/GUI/")
UseModule("GUIRoster", "Scripts/GUI/")
UseModule("GUINameTagManager", "Scripts/GUI/")
UseModule("GUIServerMessage", "Scripts/GUI/")
UseModule("GUIServerTimeout", "Scripts/GUI/")
UseModule("GUIServerConnecting", "Scripts/GUI/")
UseModule("GUINetworkDisplay", "Scripts/GUI/")
UseModule("GUICredits", "Scripts/GUI/")
UseModule("GarageManager", "Maps/Garage/Scripts/")
UseModule("ServerSettingsManager", "Scripts/")


function SetMouseVisible(setVis)

    GetMyGUISystem():GetPointerManager():SetVisible(setVis)

end

function GetMouseVisible()

    return GetMyGUISystem():GetPointerManager():IsVisible()
    
end


--MENUMANAGER CLASS START

class 'MenuManager' (IBase)

function MenuManager:__init() super()

	self:InitGUI()
	self:InitSounds()
	self:InitInput()
	self:InitSignalsSlots()

	self.STATE_MAINMENU = 0
	self.STATE_GARAGE = 1
	self.STATE_CONNECT = 2
	self.STATE_IN_GAME = 3
	self.STATE_IN_GAME_DISCONNECT = 4
	self.STATE_SETTINGS = 5
	self.STATE_HELP = 6
	self.STATE_SERVER = 7
	self.STATE_CREDITS = 8
	self.STATE_QUICKPLAY = 9

	self.pingLow = "#8EFF00"
    self.pingMed = "#BFF079"
    self.pingHigh = "#F9C220"
    self.pingTooHigh = "#FF3A2A"
    self.highPingValue = 200

	--Keeps track of if the garage map is loaded
	self.garageLoaded = false

	--This is when the roster is visible and showing players in the server
	self.showPlayers = false

    --There are some cases where you need to force the connecting to server GUI visible
	self.forceConnGUIVis = false

	self:SetState(self.STATE_MAINMENU)
	self:GoToMainMenu()

end


function MenuManager:BuildInterfaceDefIBase()

	self:AddClassDef("MenuManager", "IBase", "Manages all the menus")

end


function MenuManager:InitIBase()

end


function MenuManager:SetState(newState)

    self.lastState = self.state
    self.state = newState

end


function MenuManager:GetState()

    return self.state

end


function MenuManager:InitGUI()

	print("Starting creation of GUIMainMenu in MenuManager:InitGUI()")
	self.guiMainMenu = GUIMainMenu()
	print("Starting creation of GUIMainMenuBackground in MenuManager:InitGUI()")
	self.guiMainMenuBackground = GUIMainMenuBackground()
	print("Starting creation of GUILoadingBackground in MenuManager:InitGUI()")
	self.guiLoadingBackground = GUILoadingBackground()
	self.guiLoadingBackground:Init()
	self.guiLoadingBackground:SetVisible(false)
	print("Starting creation of GUISettings in MenuManager:InitGUI()")
	self.guiSettings = GUISettings()
	print("Starting creation of GUIHelp in MenuManager:InitGUI()")
	self.guiHelp = GUIHelp()
	print("Starting creation of GUIServerBrowser in MenuManager:InitGUI()")
	self.guiServerBrowser = GUIServerBrowser()
	print("Starting creation of GUIServer in MenuManager:InitGUI()")
	self.guiServer = GUIServer()
	print("Starting creation of GUIEscapeMenu in MenuManager:InitGUI()")
	self.guiEscapeMenu = GUIEscapeMenu()

	print("Starting creation of GUIDialogRequireRestart in MenuManager:InitGUI()")
	self.guiDialogRequireRestart = GUIDialogRequireRestart()
	self.guiDialogRequireRestart:SetVisible(false)

	print("Starting creation of GUIDialogGeneral in MenuManager:InitGUI()")
	self.guiDialogGeneral = GUIDialogGeneral()
	self.guiDialogGeneral:SetVisible(false)

	print("Starting creation of GUIServerMessage in MenuManager:InitGUI()")
	self.guiServerMessage = GUIServerMessage()

	print("Starting creation of GUIServerTimeout in MenuManager:InitGUI()")
	self.guiServerTimeout = GUIServerTimeout()

	print("Starting creation of GUIServerConnecting in MenuManager:InitGUI()")
	self.guiServerConnecting = GUIServerConnecting()

	print("Starting creation of GUINetworkDisplay in MenuManager:InitGUI()")
	self.guiNetworkDisplay = GUINetworkDisplay()
	self.guiNetworkDisplay:SetVisible(false)

    self.guiCredits = GUICredits()
    self.guiCredits:SetVisible(false)

	self.connectToServerSlot = self:CreateSlot("ConnectToServer", "GoToConnect")
	self.connectToServerSlot:Connect(self.guiMainMenu:GetSignal("ConnectToServer"))
	
	self.goToServerSlot = self:CreateSlot("GoToServer", "GoToServer")
	self.goToServerSlot:Connect(self.guiMainMenu:GetSignal("GoToServer"))
	self.goToServerSlot:Connect(self.guiEscapeMenu:GetSignal("GoToServer"))
	
	self.goToGarageSlot = self:CreateSlot("GoToGarage", "GoToGarage")
	self.goToGarageSlot:Connect(self.guiMainMenu:GetSignal("GoToGarage"))
	
	self.goToSettingsSlot = self:CreateSlot("GoToSettings", "GoToSettings")
	self.goToSettingsSlot:Connect(self.guiMainMenu:GetSignal("GoToSettings"))
	self.goToSettingsSlot:Connect(self.guiEscapeMenu:GetSignal("GoToSettings"))

	self.goToHelpSlot = self:CreateSlot("GoToHelp", "GoToHelp")
	self.goToHelpSlot:Connect(self.guiMainMenu:GetSignal("GoToHelp"))
	
	self.goToCreditsSlot = self:CreateSlot("GoToCredits", "GoToCredits")
	self.goToCreditsSlot:Connect(self.guiMainMenu:GetSignal("GoToCredits"))
	
	self.goToServerBrowserSlot = self:CreateSlot("GoToServerBrowser", "GoToServerBrowser")
	self.goToServerBrowserSlot:Connect(self.guiMainMenu:GetSignal("GoToServerBrowser"))
	self.goToServerBrowserSlot:Connect(self.guiEscapeMenu:GetSignal("GoToServerBrowser"))
	
	self.quickPlaySlot = self:CreateSlot("QuickPlay", "QuickPlay")
	self.quickPlaySlot:Connect(self.guiMainMenu:GetSignal("QuickPlay"))
	
	self.mainMenuSoundsStoppedSlot = self:CreateSlot("MainMenuSoundsStopped", "MainMenuSoundsStopped")
	self.mainMenuSoundsStoppedSlot:Connect(self.guiMainMenuBackground:GetSignal("SoundsStopped"))

	print("Starting creation of GUIChat in MenuManager:InitGUI()")
	self.guiChat = GUIChat()

	print("Starting creation of GUIRoster in MenuManager:InitGUI()")
	self.guiRoster = GUIRoster()
	self.guiRoster:SetVisible(false)

	print("Starting creation of GUINameTagManager in MenuManager:InitGUI()")
	self.guiNameTagManager = GUINameTagManager()

end


function MenuManager:InitSounds()

	self.musicSound = SoundSource()
	self.musicSound:SetName("menuMusic")
	self.musicSound:Init(Parameters())
	self.musicSound:SetSoundType(SoundSource.MUSIC)
	self.musicSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "GUI\\Menu\\sound\\Music_loop.wav"))
	self.musicSound:SetLooping(true)
	self.musicSound:SetSpatialMode(SoundSource.LOCAL)
	self.musicSound:SetVolume(0.3)
	--self.musicSound:Play()

end


function MenuManager:InitInput()

	self.escapePressed = self:CreateSlot("EscapePressed", "EscapePressed")
	GetClientManager():GetInputSignal("Escape"):Connect(self.escapePressed)

	self.allChatPressed = self:CreateSlot("AllChatPressed", "AllChatPressed")
	GetClientManager():GetInputSignal("AllChat"):Connect(self.allChatPressed)

	self.showPlayersPressed = self:CreateSlot("ShowPlayers", "ShowPlayers")
	GetClientManager():GetInputSignal("ShowPlayers"):Connect(self.showPlayersPressed)

end


function MenuManager:InitSignalsSlots()

	--Local client connect
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--Local client disconnected
	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")

	GetClientSystem():GetSignal("ClientConnected", true):Connect(self.clientConnectedSlot)
	GetClientSystem():GetSignal("ClientDisconnected", true):Connect(self.clientDisconnectedSlot)

	self.exitGarageSlot = self:CreateSlot("ExitGarage", "ExitGarage")
	
	self.exitSettingsSlot = self:CreateSlot("ExitSettings", "ExitSettings")
	self.exitSettingsSlot:Connect(self.guiSettings:GetSignal("ExitSettings"))

	self.exitHelpSlot = self:CreateSlot("ExitHelp", "ExitHelp")
	self.exitHelpSlot:Connect(self.guiHelp:GetSignal("ExitHelp"))
	
	self.exitCreditsSlot = self:CreateSlot("ExitCredits", "ExitCredits")
	self.exitCreditsSlot:Connect(self.guiCredits:GetSignal("ExitCredits"))
	
	self.exitServerBrowserSlot = self:CreateSlot("ExitServerBrowser", "ExitServerBrowser")
	self.exitServerBrowserSlot:Connect(self.guiServerBrowser:GetSignal("ExitServerBrowser"))

	self.exitServerSlot = self:CreateSlot("ExitServer", "ExitServer")
	self.exitServerSlot:Connect(self.guiServer:GetSignal("ExitServer"))

	self.startServerSlot = self:CreateSlot("StartServer", "StartServer")
	self.startServerSlot:Connect(self.guiServer:GetSignal("StartServer"))
	
	self.exitDialogDisconnectSlot = self:CreateSlot("ExitDialogDisconnect", "ExitDialogDisconnect")
	self.exitDialogDisconnectSlot:Connect(self.guiEscapeMenu:GetSignal("ExitDialogDisconnect"))
	
	self.showDialogRequireRestartSlot = self:CreateSlot("ShowDialogRequireRestart", "ShowDialogRequireRestart")
	self.showDialogRequireRestartSlot:Connect(self.guiSettings:GetSignal("ShowDialogRequireRestart"))
	
	self.followObjectSlot = self:CreateSlot("FollowObjectChange", "FollowObjectChange")
    self.followObjectSlot:Connect(GetCameraManager():GetSignal("FollowObjectChanged"))

end


function MenuManager:UnInitIBase()

	self:UnInitGUI()
	self:UnInitSounds()

end


function MenuManager:UnInitGUI()

	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:UnInit()
		self.guiMainMenu = nil
	end

	if IsValid(self.guiMainMenuBackground) then
		self.guiMainMenuBackground:UnInit()
		self.guiMainMenuBackground = nil
	end

	if IsValid(self.guiLoadingBackground) then
	    self.guiLoadingBackground:UnInit()
	    self.guiLoadingBackground = nil
	end

	if IsValid(self.guiNameTagManager) then
		self.guiNameTagManager:UnInit()
		self.guiNameTagManager = nil
	end
	
	if IsValid(self.guiSettings) then
		self.guiSettings:UnInit()
		self.guiSettings = nil
	end

	if IsValid(self.guiHelp) then
		self.guiHelp:UnInit()
		self.guiHelp = nil
	end
	
	if IsValid(self.guiCredits) then
		self.guiCredits:UnInit()
		self.guiCredits = nil
	end

	if IsValid(self.guiServerBrowser) then
		self.guiServerBrowser:UnInit()
		self.guiServerBrowser = nil
	end

    if IsValid(self.guiServer) then
		self.guiServer:UnInit()
		self.guiServer = nil
	end

	if IsValid(self.guiServerMessage) then
		self.guiServerMessage:UnInit()
		self.guiServerMessage = nil
	end

	if IsValid(self.guiServerTimeout) then
		self.guiServerTimeout:UnInit()
		self.guiServerTimeout = nil
	end

	if IsValid(self.guiServerConnecting) then
		self.guiServerConnecting:UnInit()
		self.guiServerConnecting = nil
	end

	if IsValid(self.guiNetworkDisplay) then
		self.guiNetworkDisplay:UnInit()
		self.guiNetworkDisplay = nil
	end

	if IsValid(self.guiChat) then
	    self.guiChat:UnInit()
	    self.guiChat = nil
	end

end


function MenuManager:UnInitSounds()

	if IsValid(self.musicSound) then
		self.musicSound:UnInit()
		self.musicSound = nil
	end

end


function MenuManager:SetForceConnGUIVis(setForceVis)

    self.forceConnGUIVis = setForceVis

end


function MenuManager:Process(frameTime)

	if self.state ~= self.STATE_IN_GAME then
		--Mouse is always visible when not playing
		SetMouseVisible(true)

		self.musicSound:Process(frameTime)

		if IsValid(self.guiMainMenuBackground) then
			self.guiMainMenuBackground:Process(frameTime)
		end
		if IsValid(self.guiMainMenu) then
		    self.guiMainMenu:Process(frameTime)
		end
	--When in the game, mouse is always invisible
	else
		SetMouseVisible(false)
	end
	--Mouse is visible when a dialog is visible
	if self:GetDialogVisible() then
		SetMouseVisible(true)
	end
	--Mouse is invisible when the loading screen is visible
	if self:GetLoadingBackgroundVisible() then
		SetMouseVisible(false)
	end
	--Mouse is visible when showing players in the roster
	if self.showPlayers then
	    --Not anymore
		--SetMouseVisible(true)
	end

    self:ProcessShowConnectingGUI()

    --Just a small delay to hide some sync nastyness
    if self.hideLoadingBackgroundTimer ~= nil and self.hideLoadingBackgroundTimer:IsTimerUp() then
        self.hideLoadingBackgroundTimer = nil
        self:SetLoadingBackgroundVisible(false)
    end

    if self.state == self.STATE_QUICKPLAY then
        self:ProcessQuickPlay()
    end

end


function MenuManager:ProcessShowConnectingGUI()

	--Only allow the server connecting GUI to be visible when the client is actually connecting and
	--it isn't running a server as we don't want it to display when the user is in the process of starting
	--a server when they should only be seeing the loading background image
	local connGUIVis = self.state ~= self.STATE_QUICKPLAY
	connGUIVis = connGUIVis and (GetClientSystem():GetState() == NetworkSystem.CONNECTING)
	connGUIVis = connGUIVis and (not GetClientSystem():GetServerProcessRunning())
	--Do not show the connecting GUI if we are just requesting a ping
	connGUIVis = connGUIVis and (not GetClientSystem():GetInRequestPingMode())
	--Do not show the connecting GUI if the loading background is visible
	connGUIVis = connGUIVis and (not self:GetLoadingBackgroundVisible())
	connGUIVis = connGUIVis or self.forceConnGUIVis
	self.guiServerConnecting:SetVisible(connGUIVis)

end


function MenuManager:ProcessQuickPlay()

    --BRIAN TODO: "Quick Play" has turned into "Quick Create" until some issues are fixed
    --if self.guiServerBrowser:CheckRefreshDone() then
        self:QuickPlayListUpdated()
    --end

end


function MenuManager:FollowObjectChange(changeParams)

    --Only start the hide timer if it is visible and
    --the client has already been initially synced otherwise
    --ClientManager:InitialSyncDone() will handle it
    if self:GetLoadingBackgroundVisible() and GetClientManager().initiallySynced then
        self.hideLoadingBackgroundTimer = WTimer(1)
    end

end

function MenuManager:EscapePressed(escapeParams)

	--If any dialog is visible then escape should be disabled
	if self:GetDialogVisible() then
		return
	end

	--If the loading background is visible, escape should also be ignored
	if self:GetLoadingBackgroundVisible() then
		return
	end

	if self.state == self.STATE_MAINMENU then
		--BRIAN TODO: It would be best to ask the user if they want to quit before just exiting like this
		--GetOGRESystem():Exit()
	elseif self.state == self.STATE_GARAGE then
		self:ExitGarage()
	elseif self.state == self.STATE_CONNECT then
		self:ExitServerBrowser()
	elseif self.state == self.STATE_SERVER then
		self:ExitServer()
	elseif self.state == self.STATE_SETTINGS then
		self:ExitSettings()
	elseif self.state == self.STATE_HELP then
		self:GoToMainMenu()
	elseif self.state == self.STATE_CREDITS then
		self:GoToMainMenu()	
	elseif self.state == self.STATE_IN_GAME then
		if not self:GetLoadingBackgroundVisible() then
            self:GoToDialogDisconnect()
        end
	elseif self.state == self.STATE_IN_GAME_DISCONNECT then
        self:GoToGame()
        self:SetLoadingBackgroundVisible(false)
	end

end


function MenuManager:GetDialogVisible()

	return self.guiServerTimeout:GetVisible() or self.guiServerConnecting:GetVisible() or
		   self.guiServerMessage:GetVisible() or self.guiDialogGeneral:GetVisible()
end


function MenuManager:AllChatPressed(chatParams)

	self.guiChat:StartChat()

end


function MenuManager:ShowPlayers(showParams)

	if self.state == self.STATE_IN_GAME then
		self.showPlayers = showParams:GetParameter("Pressed", true):GetBoolData()
		if self.showPlayers then
			self.guiRoster:SetVisible(true)
		else
			self.guiRoster:SetVisible(false)
			GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
			GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
		end
	end

end


function MenuManager:ClientConnected(clientParams)

    --Connection is a trigger to stop forcing
	self:SetForceConnGUIVis(false)

	self:GoToGame()

end


function MenuManager:ClientDisconnected(clientParams)

	--Only go back to the main menu if the loading screen is visible or
    --we aren't at the server browser as we may have failed to connect
    --to a server and want to find another one
	if GetMenuManager():GetLoadingBackgroundVisible() or self.state ~= self.STATE_CONNECT and 
       self.state ~= self.STATE_GARAGE then
		self:GoToMainMenu()
	end

    --Only hide the loading screen if we aren't waiting to connect to another server
	if string.len(GetClientSystem():GetQueuedConnectAddress()) == 0 then
	    GetMenuManager():SetLoadingBackgroundVisible(false)
	end

    --Disconnection is a trigger to stop forcing
	self:SetForceConnGUIVis(false)

end


function MenuManager:StartIntro()

	self.musicSound:Play()

end


function MenuManager:GoToMainMenu()

    if self.musicSound:GetState() ~= SoundSource.PLAYING then
        self.musicSound:Play()
    end

	--Reset the camera to the default position/orientation
	self.camera = GetCamera()
	self.camera:SetPosition(WVector3())
	self.camera:SetOrientation(WQuaternion())

	self:SetState(self.STATE_MAINMENU)

    if IsValid(self.guiSettings) then
		self.guiSettings:SetVisible(false)
	end

	if IsValid(self.guiHelp) then
		self.guiHelp:SetVisible(false)
	end
	if IsValid(self.guiCredits) then
		self.guiCredits:SetVisible(false)
	end
	
	if IsValid(self.guiServerBrowser) then
		self.guiServerBrowser:SetVisible(false)
	end

    if IsValid(self.guiServer) then
		self.guiServer:SetVisible(false)
	end

    if IsValid(self.guiLoadingBackground) then
        self.guiLoadingBackground:SetVisible(false)
    end

	if IsValid(self.guiRoster) then
		self.guiRoster:SetVisible(false)
	end

	if self.garageLoaded == true then
		self.garageLoaded = false
	end

	GetClientManager():UnLoadMap()

	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(true)
	end

	if IsValid(self.guiMainMenuBackground) and not self.guiMainMenuBackground:GetVisible() then
		self.guiMainMenuBackground:SetVisible(true)
	end
	
	if IsValid(self.guiEscapeMenu) then
		self.guiEscapeMenu:SetVisible(false)
	end

end


function MenuManager:GoToDialogDisconnect(params)

    if IsValid(self.guiEscapeMenu) then
        self:SetState(self.STATE_IN_GAME_DISCONNECT)
		self.guiEscapeMenu:SetVisible(true)
	end
	
	if IsValid(self.guiLoadingBackground) then
        self.guiLoadingBackground:SetVisible(false)
    end
    
end

--Emitted from the MainMenu when the user clicks on the Connect To Server button
function MenuManager:GoToConnect(connectParams)

	self:SetState(self.STATE_CONNECT)

	--self:DisableMainMenuSounds()

	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end

	if IsValid(self.guiMainMenuBackground) then
		self.guiMainMenuBackground:SetVisible(false)
	end

    if IsValid(self.guiServerBrowser) then
		self.guiServerBrowser:SetVisible(true)
	end
    
end


--Emitted from the MainMenu when the user clicks on the Go To Garage button
function MenuManager:GoToGarage(garageParams)

	self:SetState(self.STATE_GARAGE)

	self:DisableMainMenuSounds()

	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end

	if IsValid(self.guiMainMenuBackground) then
		self.guiMainMenuBackground:SetVisible(false)
	end

	--Load the garage map
	self.garageMap = GetClientManager():LoadMap("Garage", true)
	self.garageLoaded = true

	if IsValid(self.garageManager) then
		self.garageManager:UnInit()
		self.garageManager = nil
	end
	self.garageManager = GarageManager(self.garageMap)
	self.garageManager:GetSignal("Exit"):Connect(self.exitGarageSlot)

end


--Emitted from the MainMenu when the user clicks on the quick play button
function MenuManager:QuickPlay(quickPlayParams)

    self:SetState(self.STATE_QUICKPLAY)

    self:SetLoadingBackgroundVisible(true)

	print("QUICKPLAY: Requesting server list")
	if IsValid(GetSteamClientSystem) then
	    -- if GetDemoMode() then
	    --     --Only local server supported in demo mode
	    --     self:QuickPlayListUpdated()
	    -- else
	        self.guiServerBrowser:RefreshServerList(true)
	    -- end
    else
        print("QuickPlay: No SteamClientSystem")
        self:GoToMainMenu()
    end

end


function MenuManager:QuickPlayLobbyValid(lobby)
    
    local thisCountry = GetSteamClientSystem():GetLocalPlayerCountry()
    return thisCountry == lobby:GetCountry() and lobby:GetNumPlayers() ~= lobby:GetTotalPlayerSlots()
    
end


function MenuManager:QuickPlayListUpdated()

    print("QuickPlay: Server list updated, state = " .. self.state)
    if self.state ~= self.STATE_QUICKPLAY or GetClientSystem():GetServerProcessRunning() or
       GetClientSystem():GetState() ~= NetworkSystem.DISCONNECTED then
        return
    end

    --BRIAN TODO: "Quick Play" has turned into "Quick Create" until some issues are fixed
    self:QuickPlayStartLocal()

    --[[
    print("QuickPlay: Number of LAN servers: " .. GetSteamClientSystem():GetNumberLANServers())
    print("QuickPlay: Number of internet servers: " .. GetSteamClientSystem():GetNumberInternetServers())
    print("QuickPlay: Number of lobbies: " .. GetSteamClientSystem():GetNumberLobbies())

    local serverAddress = nil
    local serverName = nil
    local serverPing = nil

    local i = 0
    while i < GetSteamClientSystem():GetNumberLANServers() do
        local gameServer = GetSteamClientSystem():GetLANServer(i)
        --Check if this is a better server
        if not IsValid(serverPing) or gameServer:GetPing() < serverPing then
            serverAddress = gameServer:GetAddress()
            serverName = gameServer:GetName()
            serverPing = gameServer:GetPing()
        end
        i = i + 1
    end

    --A LAN server is ideal so only check other servers if there are no LAN servers
    if not IsValid(serverAddress) then
        i = 0
        while i < GetSteamClientSystem():GetNumberInternetServers() do
            local gameServer = GetSteamClientSystem():GetInternetServer(i)
            --Check if this is a better server (not full and smaller ping)
            if not IsValid(serverPing) or (gameServer:GetNumHumanPlayers() < gameServer:GetTotalPlayerSlots()) and (gameServer:GetPing() < 0.200) and (gameServer:GetPing() < serverPing) then
                serverAddress = gameServer:GetAddress()
                serverName = gameServer:GetName()
                serverPing = gameServer:GetPing()
            end
            i = i + 1
        end

        --Only bother checking the lobbies if another server hasn't been selected
        --As we don't know the lobbies ping at this point
        i = 0
        while serverPing == nil and i < GetSteamClientSystem():GetNumberLobbies() and i < 3 do
            local lobby = GetSteamClientSystem():GetLobby(i)
            --Check if it is valid
            if self:QuickPlayLobbyValid(lobby) then
                serverAddress = lobby:GetAddress()
                serverName = lobby:GetName()
                break
            end
            i = i + 1
        end
    end

    if IsValid(serverAddress) and IsValid(serverName) then
        --Join this server
        print("QuickPlay Joining: " .. serverName)
        GetClientManager():SetCurrentServerName(serverName)
        GetClientManager():InitPlayerName()
        GetClientSystem():RequestConnect(serverAddress, SavedItemsSerializer():GetSettingsAsParameters())
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
    else
        --Start a local server
        print("QuickPlay: No good lobbies found, Starting local server")
        self:QuickPlayStartLocal()
    end
    --]]

end

function MenuManager:QuickPlayStartLocal()

    local serverSettings = ServerSettingsManager()
    serverSettings:QuickPlay()
    
    self.guiServer:RefreshMapList()
    self.guiServer:RefreshSetupTab()
    
	GetClientManager():SetCurrentServerName(serverSettings.serverName)
	local params = Parameters()
    params:GetOrCreateParameter("MaxNumClients"):SetIntData(serverSettings.maxPlayers)
	params:GetOrCreateParameter("ServerName"):SetStringData(serverSettings.serverName)
	params:GetOrCreateParameter("ServerType"):SetStringData("0")
	self:StartServer(params)
	
end


--Emitted from the MainMenu when the user clicks on the Join button
function MenuManager:GoToServerBrowser(serverBrowserParams)

    self:SetState(self.STATE_CONNECT)
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end

	if IsValid(self.guiServerBrowser) then
		self.guiServerBrowser:SetVisible(true)
	end

end


--Emitted from the MainMenu when the user clicks on the Host button
function MenuManager:GoToServer(serverParams)

    self:SetState(self.STATE_SERVER)
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end
	
	if IsValid(self.guiServer) then
		self.guiServer:SetVisible(true)
	end

end

--Emitted from the MainMenu when the user clicks on the Settings button
function MenuManager:GoToSettings(settingsParams)

	self:SetState(self.STATE_SETTINGS)
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end
	
	if IsValid(self.guiSettings) then
		self.guiSettings:SetVisible(true)
	end

end


function MenuManager:GoToHelp(helpParams)

	self:SetState(self.STATE_HELP)
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end
	
	if IsValid(self.guiHelp) then
		self.guiHelp:SetVisible(true)
	end

end

function MenuManager:GoToCredits(helpParams)

	self:SetState(self.STATE_CREDITS)
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end
	
	if IsValid(self.guiCredits) then
		self.guiCredits:SetVisible(true)
	end

end


function MenuManager:GoToGame()

    self:SetLoadingBackgroundVisible(true)

	self:SetState(self.STATE_IN_GAME)

	self:DisableMainMenuSounds()

    if IsValid(self.guiServerBrowser) then
		self.guiServerBrowser:SetVisible(false)
	end

	if IsValid(self.guiServer) then
		self.guiServer:SetVisible(false)
	end
	
	if IsValid(self.guiMainMenu) then
		self.guiMainMenu:SetVisible(false)
	end

	if IsValid(self.guiMainMenuBackground) then
		self.guiMainMenuBackground:SetVisible(false)
	end

	if self.garageLoaded == true then
		GetClientManager():UnLoadMap()
		self.garageLoaded = false
	end
	
	if IsValid(self.guiEscapeMenu) then
		self.guiEscapeMenu:SetVisible(false)
	end

end


function MenuManager:SetLoadingBackgroundVisible(setVis)

    if IsValid(self.guiLoadingBackground) then
        self.guiLoadingBackground:SetVisible(setVis)
        if setVis then
            self.guiMainMenu:SetVisible(false)
	        self.guiMainMenuBackground:SetVisible(false)
        end
    end

end


function MenuManager:GetLoadingBackgroundVisible()

    if IsValid(self.guiLoadingBackground) then
        return self.guiLoadingBackground:GetVisible()
    end
    return false

end


function MenuManager:GetChat()

	return self.guiChat

end


function MenuManager:GetRoster()

	return self.guiRoster

end


function MenuManager:GetNameTagManager()

	return self.guiNameTagManager

end


function MenuManager:GetNetworkDisplay()

	return self.guiNetworkDisplay

end


--This is called when the garage should be exited, the main menu should be active at this point
function MenuManager:ExitGarage()

    if not self:GetLoadingBackgroundVisible() then
        --First uninit the garage
        if IsValid(self.garageManager) then
            self.garageManager:UnInit()
            self.garageManager = nil
        end

        self:GoToMainMenu()
    end

end


--Called when exiting settings menu
function MenuManager:ExitSettings()

    if not self:GetLoadingBackgroundVisible() then
        self.guiSettings:SetVisible(false)

        print("MenuManager:ExitSettings, lastState:"..self.lastState)
        if self.lastState == self.STATE_IN_GAME_DISCONNECT then
            self:GoToGame()
            self:SetLoadingBackgroundVisible(false)
        else
            self:GoToMainMenu()
        end
    end

end


--Called when exiting the help menu
function MenuManager:ExitHelp()

    if not self:GetLoadingBackgroundVisible() then
	    self:GoToMainMenu()
	end

end


--Called when exiting the credits menu
function MenuManager:ExitCredits()

    if not self:GetLoadingBackgroundVisible() then
	    self:GoToMainMenu()
	end

end


--Called when exiting ServerBrowser menu
function MenuManager:ExitServerBrowser()

    if not self:GetLoadingBackgroundVisible() then
        self.guiServerBrowser:SetVisible(false)

        if self.lastState == self.STATE_IN_GAME_DISCONNECT then
            self:GoToGame()
            self:SetLoadingBackgroundVisible(false)
        else
            self:GoToMainMenu()
        end
    end

end

--Called when exiting Server menu
function MenuManager:ExitServer()

    if not self:GetLoadingBackgroundVisible() then
        self.guiServer:SetVisible(false)

        if self.lastState == self.STATE_IN_GAME_DISCONNECT then
            self:GoToGame()
            self:SetLoadingBackgroundVisible(false)
        else
            self:GoToMainMenu()
        end
    end

end


function MenuManager:StartServer(params)

	local maxNumClients = params:GetParameter("MaxNumClients", true):GetIntData()
	local serverName = params:GetParameter("ServerName", true):GetStringData()
	local serverType = params:GetParameter("ServerType", true):GetStringData()
	local friendsOnlyServer = serverType == "Friends Only"
	local privateServer = serverType == "Private"
	local generatedPassword = tostring(math.random())
	GetClientSystem():StartServer(maxNumClients, serverName, generatedPassword, not privateServer,
                                  friendsOnlyServer, SavedItemsSerializer():GetSettingsAsParameters())

end


function MenuManager:ExitDialogDisconnect()

    self:GoToGame()
    self:SetLoadingBackgroundVisible(false)

end


function MenuManager:DisableMainMenuSounds()

	self.musicSound:Stop()

end


function MenuManager:MainMenuSoundsStopped(stoppedParams)

	if self.state == self.STATE_MAINMENU then
--		self:StartIntro()
	end

end


function MenuManager:ShowDialogRequireRestart()

    if IsValid(self.guiDialogRequireRestart) then
        self.guiDialogRequireRestart:SetVisible(true)
    end
    
end


function MenuManager:ShowDialogGeneral(message)

    if IsValid(self.guiDialogGeneral) then
        self.guiDialogGeneral:SetStrings(message)
        self.guiDialogGeneral:SetVisible(true)
    end

end


function MenuManager:ColorPing(pingFloat)

    if pingFloat <= 100 then
        return self.pingLow .. pingFloat
    elseif pingFloat <= 150 then
        return self.pingMed .. pingFloat
    elseif pingFloat <= self.highPingValue then
        return self.pingHigh .. pingFloat
    else    
        return self.pingTooHigh .. pingFloat
    end

end

--MENUMANAGER CLASS END