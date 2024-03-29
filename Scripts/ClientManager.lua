UseModule("IBase", "Scripts/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("PlayerClient", "Scripts/")
UseModule("KartClient", "Scripts/")
UseModule("CustomItemManager", "Scripts/")
--Load the ClientMapLoader module
UseModule("ClientMapLoader", "Scripts/")
--Load the input module
UseModule("ClientInputManager", "Scripts/")
--Load the menu manager
UseModule("MenuManager", "Scripts/")
--Load the debug draw manager
UseModule("DebugDrawManager", "Scripts/")
--Camera Manager
UseModule("CameraManager", "Scripts/")
--Camera Controllers
UseModule("CamControllerKartCombiner", "Scripts/Modifiers/CameraControllers/")
UseModule("CamControllerRotator", "Scripts/Modifiers/CameraControllers/")
UseModule("CamControllerFreeMove", "Scripts/Modifiers/CameraControllers/")
UseModule("CamControllerFreeMoveVel", "Scripts/Modifiers/CameraControllers/")
UseModule("AchievementManager", "Scripts/")

--CLIENTMANAGER CLASS START
class 'ClientManager' (IBase)

function ClientManager:__init() super()

	--profiler:start("LuaProfilerData.out")

    self.achievements = AchievementManager()

	--These slots will be emitted when we connect or disconnect to the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")

	--This slot is connected to the network system to be notifed when a server signal wants to connect to us
	self.connectToNetworkSignal = self:CreateSlot("ConnectToNetworkSignal", "ConnectToNetworkSignal")
	--This slot is connected to the network system to be notifed when a server signal wants to disconnect from us
	self.disconnectFromNetworkSignal = self:CreateSlot("DisconnectFromNetworkSignal", "DisconnectFromNetworkSignal")

	--These slots are the slots that the server will request to be connected
	--This slot is called from the server to tell the client to load a map
	self.loadMap = self:CreateSlot("LoadMap", "LoadMap")
	--This slot is called from the server to tell the client a new map is going to be loaded soon
	self.loadMapNotification = self:CreateSlot("LoadMapNotification", "LoadMapNotification")
	--This slot is called from the server to tell the client that a new client has connected
	self.newClientConnected = self:CreateSlot("NewClientConnected", "NewClientConnected")
	--This slot is called from the server to tell the client that a client has disconnected
	self.clientOnServerDisconnected = self:CreateSlot("ClientOnServerDisconnected", "ClientOnServerDisconnected")
    --This slot is called from the server to tell the client that they are all synced up initially
    self.initialSyncDone = self:CreateSlot("InitialSyncDone", "InitialSyncDone")

    --Called when the ClientSystem is told to send a connection request
    self.requestConnectSlot = self:CreateSlot("RequestConnect", "RequestConnect")
    GetClientSystem():GetSignal("RequestConnect", true):Connect(self.requestConnectSlot)

	--This is so we can receive info when a player is respawned from the server
	self.playerRespawnedSlot = self:CreateSlot("PlayerRespawned", "PlayerRespawned", GetClientSystem())

	--This is so we can broadcast info locally when a player is respawned
	self.playerRespawnedSignal = self:CreateSignal("PlayerRespawned")

	--Collision Handling
	self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")
	self.collisionEndSlot = self:CreateSlot("BulletCollisionEnd", "BulletCollisionEnd")
	--GetBulletPhysicsSystem():GetSignal("StartCollision", true):Connect(self.collisionStartSlot)
	--GetBulletPhysicsSystem():GetSignal("EndCollision", true):Connect(self.collisionEndSlot)

	--This is the Kart that this client currently owns
	self.ownedKartMapObject = nil
	self.ownedKart = nil
	--This is the player that we enable the camera for
	self.cameraFollowPlayer = nil

	--The network info GUI
	self.networkInfoPage = nil
	self.networkUpdatedSlot = self:CreateSlot("NetworkUpdated", "NetworkUpdated")
	self.setNetworkInfo = self:CreateSignal("SetNetworkInfo")
	self.networkGUIClock = WTimer()
	self.networkGUIUpdateTimer = 0.3

	self.reportScriptMem = WTimer()
	self.reportScriptMemTimer = 10

	self.debugKeysEnabled = false

	self.currentMapName = ""
	self.currentServerName = ""

	--Camera
	self.playerCam = nil

	--The local client state is sent to the server constantly
	self.localClientState = ClientState()

	self.menuManager = nil

	self.fakeClients = { }

	self.loadingAllowed = true
	self.loadingAllowedSignal = self:CreateSignal("LoadingAllowed")
	self.loadingAllowedParams = Parameters()

    self.initiallySynced = false
    
    self.indieSlider = false

    --Default to off
    self.screenBlurAllowed = false

end


function ClientManager:BuildInterfaceDefIBase()

	self:AddClassDef("ClientManager", "IBase", "The root for all client management")

end


function ClientManager:__finalize()

	--profiler:stop()

end


function ClientManager:InitIBase()

	--Grab some processing time
	self.processSlot = self:CreateSlot("Process", "Process")
	--We will process right before the rendering begins
	GetOGRESystem():GetSignal("ProcessBegin", true):Connect(self.processSlot)

	print("Starting creation of ClientInputManager in ClientManager:Init()")
	self.clientInputManager = ClientInputManager()
	print("Finished creation of ClientInputManager in ClientManager:Init()")

	self.debugDrawManager = DebugDrawManager()

	print("Starting self:InitCameraManager() in ClientManager:Init()")
	self:InitCameraManager()

	--This object will manage loading and unloading maps
	print("Starting creation of ClientMapLoader in ClientManager:Init()")
	self.mapLoader = ClientMapLoader()
	self.mapLoader:Init()
	print("Finished creation of ClientMapLoader in ClientManager:Init()")
	self.playerCam = GetCamera()

	self.clientKeyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	GetClientInputManager():GetSignal("KeyPressed", true):Connect(self.clientKeyPressedSlot)
	self.clientKeyReleasedSlot = self:CreateSlot("KeyReleased", "KeyReleased")
	GetClientInputManager():GetSignal("KeyReleased", true):Connect(self.clientKeyReleasedSlot)

	self.clientKeyPressedIgnoreFocusSlot = self:CreateSlot("KeyPressedIgnoreFocus", "KeyPressedIgnoreFocus")
	GetClientInputManager():GetSignal("KeyPressedIgnoreFocus", true):Connect(self.clientKeyPressedIgnoreFocusSlot)
	self.clientKeyReleasedIgnoreFocusSlot = self:CreateSlot("KeyReleasedIgnoreFocus", "KeyReleasedIgnoreFocus")
	GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.clientKeyReleasedIgnoreFocusSlot)

	GetClientInputManager():GetSignal("KeyPressed", true):Connect(GetClientWorld():GetSlot("KeyPressed", true))
	GetClientInputManager():GetSignal("KeyReleased", true):Connect(GetClientWorld():GetSlot("KeyReleased", true))
	GetClientInputManager():GetSignal("AxisMoved", true):Connect(GetClientWorld():GetSlot("AxisMoved", true))

	self.worldSetObjectOwner = self:CreateSlot("WorldSetObjectOwner", "WorldSetObjectOwner")
	GetClientWorld():GetSignal("OwnerChange", true):Connect(self.worldSetObjectOwner)

	print("Starting self:InitSounds() in ClientManager:Init()")
	self:InitSounds()
	print("Starting self:InitInputSignals() in ClientManager:Init()")
	self:InitInputSignals()

	--Initial scan for items
	print("Starting GetCustomItemManager():ScanItems() in ClientManager:Init()")
	GetCustomItemManager():ScanItems()

	print("Starting creation of MenuManager in ClientManager:Init()")
	self.menuManager = MenuManager()

	self:InitPlayerName()

end


function ClientManager:InitCameraManager()

	--Init the camera manager, this controls all cameras
	self.cameraManager = CameraManager()

end


function ClientManager:UnInitCameraManager()

	if IsValid(self.cameraManager) then
		self.cameraManager:UnInit()
		self.cameraManager = nil
	end

end


function ClientManager:InitSounds()

	self.playerListener = SoundListener()
	self.playerCam:GetSignal("SetTransform", true):Connect(self.playerListener:GetSlot("SetTransform", true))

end


--Init the signals that are used for input
function ClientManager:InitInputSignals()

	self.inputSignals = { }
	self.inputParams = Parameters()

	self.inputSignals["ShowPlayers"] = self:CreateSignal("ShowPlayers")
	self.inputSignals["AllChat"] = self:CreateSignal("AllChat")
	self.inputSignals["Escape"] = self:CreateSignal("Escape")
	self.inputSignals["UseItemUp"] = self:CreateSignal("UseItemUp")
	self.inputSignals["UseItemDown"] = self:CreateSignal("UseItemDown")
	self.inputSignals["ControlAccel"] = self:CreateSignal("ControlAccel")
	self.inputSignals["ControlMouseLook"] = self:CreateSignal("ControlMouseLook")
	self.inputSignals["ControlReverse"] = self:CreateSignal("ControlReverse")
	self.inputSignals["ControlRight"] = self:CreateSignal("ControlRight")
	self.inputSignals["ControlLeft"] = self:CreateSignal("ControlLeft")
	self.inputSignals["ControlReset"] = self:CreateSignal("ControlReset")
	self.inputSignals["Hop"] = self:CreateSignal("Hop")
	self.inputSignals["ControlBoost"] = self:CreateSignal("ControlBoost")

end


function ClientManager:UnInitIBase()

    print("Starting ClientManager:UnInitIBase()")

	if IsValid(self.mapLoader) then
		self.mapLoader:UnInit()
		self.mapLoader = nil
	end

	if IsValid(self.menuManager) then
		self.menuManager:UnInit()
		self.menuManager = nil
	end

	self:UnInitCameraManager()

	print("Finished ClientManager:UnInitIBase()")

end


function ClientManager:Process()

    local frameTime = GetFrameTime()

	self.cameraManager:Process(frameTime)
	self.menuManager:Process(frameTime)

	self:ProcessFakeClients(frameTime)

	self.playerListener:Process(frameTime)

    self:ProcessQueuedConnect()

	if GetClientSystem():IsConnected() then
		--Update the local client state
		self.localClientState:SetCameraState(GetCamera():GetPosition(), GetNetworkSystem():GetTime())
		local followObjID = 0
		local followObj = GetCameraManager():GetFollowObject()
		if IsValid(followObj) then
		    --The server doesn't know about local client object IDs
		    followObjID = GetClientWorld():GetServerObjectID(followObj:GetID())
		end
		self.localClientState:SetCameraFollowObjectID(followObjID)
		self.localClientState:SetPing(GetClientSystem():GetServerPing())
		GetClientSystem():UpdateLocalClientState(self.localClientState)
	end

	--if self.reportScriptMem:GetTimeSeconds() > self.reportScriptMemTimer then
	--	self.reportScriptMem:Reset()
	--	print("Number of KB used by script: " .. tostring(GetScriptSystem():GetNumberKBUsed()))
	--end

    self:ProcessMapLoad()

end


--Checks if the ClientSystem has a queued address to connect to and if so
--handles the state to connect to that address
function ClientManager:ProcessQueuedConnect()

    local serverAddress = GetClientSystem():GetQueuedConnectAddress()
    if string.len(serverAddress) > 0 then
        --Always connect from the main menu
        if GetMenuManager():GetState() ~= GetMenuManager().STATE_MAINMENU then
            if GetMenuManager():GetState() == GetMenuManager().STATE_GARAGE then
                GetMenuManager():ExitGarage()
            elseif GetMenuManager():GetState() == GetMenuManager().STATE_CONNECT then
                --If already in game and joining another server, we need to display the loading screen
                if GetClientSystem():GetState() == NetworkSystem.CONNECTED and not GetClientSystem():GetInRequestPingMode() then
                    GetMenuManager():SetLoadingBackgroundVisible(true)
                end
            elseif GetMenuManager():GetState() == GetMenuManager().STATE_SERVER then
                GetMenuManager():ExitServer()
            elseif GetMenuManager():GetState() == GetMenuManager().STATE_SETTINGS then
                GetMenuManager():ExitSettings()
            else
                GetMenuManager():GoToMainMenu()
            end
        end

        if GetClientSystem():GetState() == NetworkSystem.DISCONNECTED then
            if self.processQueuedConnectWaitOnce == 1 then
                self.processQueuedConnectWaitOnce = 0
                GetClientSystem():SetQueuedConnectAddress("")
                GetClientManager():InitPlayerName()
                print("Starting GetClientSystem():RequestConnect() in ClientManager:ProcessQueuedConnect()")
                --Only show the loading screen if the connection doesn't fail right off the bat
                if GetClientSystem():RequestConnect(serverAddress, SavedItemsSerializer():GetSettingsAsParameters()) then
                    GetMenuManager():SetLoadingBackgroundVisible(true)
                end
            else
                self.processQueuedConnectWaitOnce = 1
            end
        elseif GetClientSystem():GetState() == NetworkSystem.CONNECTED then
            --Still connected, must disconnect first
            GetClientSystem():RequestDisconnect()
        end
    end

end


function ClientManager:ProcessMapLoad()

    if IsValid(self.mapLoadName) then
        if self.loadMapCount == 1 then
            GetClientSystem():SetIgnorePing(true)

            local loadClock = WTimer()
            print("Loading map: " .. self.mapLoadName)

            --Returns the Map
            local loadedMap = self.mapLoader:Load(self.mapLoadName)

            --Make sure the user has the map
            if not IsValid(loadedMap) then
                GetMenuManager():ShowDialogGeneral("Map named " .. self.mapLoadName .. " not found")
                GetClientSystem():RequestDisconnect()
            end

            print("Finished loading map: " .. self.mapLoadName .. " time: " .. tostring(loadClock:GetTimeSeconds()))

            GetClientSystem():SetIgnorePing(false)
            if IsValid(GetPlayerManager():GetLocalPlayer()) then
                GetPlayerManager():GetLocalPlayer():SetGUIVisible(self.mapLoadPlayerGUIVis)
            end

            local mapName = self.mapLoadName
            self.mapLoadName = nil

			print("Processing buffered ClientWorld commands")

			--Now that the map is loaded we can allow the ClientWorld to process
			--any commands it has buffered
			--NOTE: Try to do it globally instead
			--GetClientWorld():BufferWorldCommands(false)
			--GetClientSystem():BufferTableCommands(false)
			GetClientSystem():SetBufferNetEvents(false)

            print("Total map load time: " .. tostring(loadClock:GetTimeSeconds()))
            return loadedMap
        else
            self.loadMapCount = self.loadMapCount + 1
        end
    end

end


function ClientManager:GetClientInputManager()

	return self.clientInputManager

end


function ClientManager:GetMenuManager()

	return self.menuManager

end


--Getters for all the input signals
function ClientManager:GetInputSignal(signalName)

	return self.inputSignals[signalName]

end


--Helper functions to emit the input signals
function ClientManager:EmitInput(signalName, buttonPressed)

	self.inputParams:GetOrCreateParameter("Pressed"):SetBoolData(buttonPressed)
	self.inputSignals[signalName]:Emit(self.inputParams)

end


function ClientManager:GetKeyCodeMatches(keyCode, keyName)

	return self.clientInputManager:GetKeyCodeMatches(keyCode, keyName)

end


function ClientManager:KeyPressed(keyParams)

	local keyCode = keyParams:GetParameter("Key", true):GetIntData()

	--print("Key pressed: " .. tostring(keyCode))

	--Are Debug Keys Enabled?
	if DKE() then
		--Debug draw toggle
		if keyCode == StringToKeyCode("H") then
			self.debugDrawManager:SetEnabled(not self.debugDrawManager:GetEnabled())
		--Camera Control
		elseif keyCode == StringToKeyCode("M") then
			CC(true)
		--Toggle physics drawing
		elseif keyCode == StringToKeyCode("C") then
			GetBulletPhysicsSystem():SetDebugDraw(not GetBulletPhysicsSystem():GetDebugDraw())
		--Toggle filtering mode
		elseif keyCode == StringToKeyCode("T") then
			if GetTextureFiltering() == OGREUtil.BILINEAR then
				SetTextureFiltering(OGREUtil.TRILINEAR, 1)
			elseif GetTextureFiltering() == OGREUtil.TRILINEAR then
				SetTextureFiltering(OGREUtil.ANISOTROPIC, 8)
			elseif GetTextureFiltering() == OGREUtil.ANISOTROPIC then
				SetTextureFiltering(OGREUtil.BILINEAR, 1)
			end
		--Toggle render mode
		elseif keyCode == StringToKeyCode("R") then
			if self.playerCam:GetRenderMode() == WCamera.SOLID then
				self.playerCam:SetRenderMode(WCamera.WIREFRAME)
			elseif self.playerCam:GetRenderMode() == WCamera.WIREFRAME then
				self.playerCam:SetRenderMode(WCamera.POINTS)
			elseif self.playerCam:GetRenderMode() == WCamera.POINTS then
				self.playerCam:SetRenderMode(WCamera.SOLID)
			end
		--Toggle the octree display
		elseif keyCode == StringToKeyCode("O") then
			local isVisible = GetOGRESystem():GetShowOctree()
			GetOGRESystem():SetShowOctree(not isVisible)
		--Toggle the network display
		elseif keyCode == StringToKeyCode("/") then
			GetMenuManager():GetNetworkDisplay():SetVisible(not GetMenuManager():GetNetworkDisplay():GetVisible())
		--Add a fake client
		elseif keyCode == StringToKeyCode("+") then
			AFC()
		--Remove a fake client
		elseif keyCode == StringToKeyCode("-") then
			RFC()
		--Toggle the GUI's visible
		elseif keyCode == StringToKeyCode("[") then
			SetOGREScreenOverlaySystemVisible(not GetOGREScreenOverlaySystemVisible())
			GetMyGUISystem():SetVisible(not GetMyGUISystem():GetVisible())
		--Toggle the kart animations
		elseif keyCode == StringToKeyCode("]") then
			SetEnableKartAnimations(not GetEnableKartAnimations())
		--Toggle shadows on and off
		elseif keyCode == StringToKeyCode(".") then
			GetOGRESystem():SetShadowsEnabled(not GetOGRESystem():GetShadowsEnabled())
		--Toggle FPS display
		elseif keyCode == StringToKeyCode("F") then
			local isVisible = GetOGRESystem():GetDebugOverlayVisible()
			GetOGRESystem():SetDebugOverlayVisible(not isVisible)
		elseif keyCode == StringToKeyCode("P") then
			local isVisible = GetOGRESystem():GetCameraDetailsVisible()
			GetOGRESystem():SetCameraDetailsVisible(not isVisible)
		end
	end
	--Save a screenshot
	if keyCode == StringToKeyCode("PRINT_SCREEN") then
		GetOGRESystem():SaveRenderToFile("Screenshot" .. tostring(GenerateID()) .. ".png")
	--Escape
	elseif self:GetKeyCodeMatches(keyCode, "Escape") then
		self:EmitInput("Escape", true)
	--Enable chat to all
	elseif self:GetKeyCodeMatches(keyCode, "AllChat") then
		self:EmitInput("AllChat", true)
	--Item use
	elseif self:GetKeyCodeMatches(keyCode, "UseItemUp") then
		self:EmitInput("UseItemUp", true)
	elseif self:GetKeyCodeMatches(keyCode, "UseItemDown") then
		self:EmitInput("UseItemDown", true)
	--Kart Controls
	elseif self:GetKeyCodeMatches(keyCode, "ControlAccel") then
		self:EmitInput("ControlAccel", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlMouseLook") then
		self:EmitInput("ControlMouseLook", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlReverse") then
		self:EmitInput("ControlReverse", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlRight") then
		self:EmitInput("ControlRight", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlLeft") then
		self:EmitInput("ControlLeft", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlReset") then
		self:EmitInput("ControlReset", true)
	elseif self:GetKeyCodeMatches(keyCode, "Hop") then
		self:EmitInput("Hop", true)
	elseif self:GetKeyCodeMatches(keyCode, "ControlBoost") then
		self:EmitInput("ControlBoost", true)
	end

end


function ClientManager:KeyReleased(keyParams)

	local keyCode = keyParams:GetParameter("Key", true):GetIntData()

	if self:GetKeyCodeMatches(keyCode, "AllChat") then
		self:EmitInput("AllChat", false)
	--Item use
	elseif self:GetKeyCodeMatches(keyCode, "UseItemUp") then
		self:EmitInput("UseItemUp", false)
	elseif self:GetKeyCodeMatches(keyCode, "UseItemDown") then
		self:EmitInput("UseItemDown", false)
	--Kart Controls
	elseif self:GetKeyCodeMatches(keyCode, "ControlAccel") then
		self:EmitInput("ControlAccel", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlMouseLook") then
		self:EmitInput("ControlMouseLook", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlReverse") then
		self:EmitInput("ControlReverse", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlRight") then
		self:EmitInput("ControlRight", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlLeft") then
		self:EmitInput("ControlLeft", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlReset") then
		self:EmitInput("ControlReset", false)
	elseif self:GetKeyCodeMatches(keyCode, "Hop") then
		self:EmitInput("Hop", false)
	elseif self:GetKeyCodeMatches(keyCode, "ControlBoost") then
		self:EmitInput("ControlBoost", false)
	end

end


function ClientManager:KeyPressedIgnoreFocus(keyParams)

	local keyCode = keyParams:GetParameter("Key", true):GetIntData()

	--Show player/scores
	if self:GetKeyCodeMatches(keyCode, "ShowPlayers") then
		self:EmitInput("ShowPlayers", true)
	end

end


function ClientManager:KeyReleasedIgnoreFocus(keyParams)

	local keyCode = keyParams:GetParameter("Key", true):GetIntData()

	if self:GetKeyCodeMatches(keyCode, "ShowPlayers") then
		self:EmitInput("ShowPlayers", false)
	end

end


--InitNetwork is provided to init the network system at the right time
function ClientManager:InitNetwork()

	GetClientSystem():GetSignal("ClientConnected", true):Connect(self.clientConnectedSlot)
	GetClientSystem():GetSignal("ClientDisconnected", true):Connect(self.clientDisconnectedSlot)
	GetClientSystem():GetSignal("RequestRemoteSignalConnect", true):Connect(self.connectToNetworkSignal)
	GetClientSystem():GetSignal("RequestRemoteSignalDisconnect", true):Connect(self.disconnectFromNetworkSignal)
	GetClientSystem():GetSignal("ProcessEnd", true):Connect(self.networkUpdatedSlot)
	GetClientSystem():SetConnectionPort(27015)

end


function ClientManager:NetworkUpdated(params)

	if self.networkInfoPage and self.networkInfoPage:GetVisible() and
	   self.networkGUIClock:GetTimeSeconds() > self.networkGUIUpdateTimer then
		self.networkGUIClock:Reset()
		--Emit the network data after the NetworkSystem is done processing
		local infoParams = GetClientSystem():GetConnectionInfo()
		self.setNetworkInfo:Emit(infoParams)
	end

end


function ClientManager:InitPlayerName()

	--Default to "Player"
	local playerName = "Player"
	--Default to Steam name if we can
	if IsValid(GetSteamClientSystem) then
		playerName = GetSteamClientSystem():GetLocalPlayerName()
	end
	--Finally, check if they have a saved name and use that
	local paramPlayerName = GetSettingTable():GetSetting("PlayerName", "Shared", false)
	if IsValid(paramPlayerName) then
		playerName = paramPlayerName:GetStringData()
	end
	GetClientSystem():SetClientName(playerName)

end


function ClientManager:ClientConnected(connectedParams)

	local uniqueID = connectedParams:GetParameter("UniqueID", true):GetIntData()
	if uniqueID == 0 then
		error("ID 0 in ClientManager:ClientConnected()")
	end
	--3rd param true for local player
	local localPlayer = PlayerClient(GetClientSystem():GetClientName(), uniqueID, true)
	localPlayer:Init()
	GetConsole():Print("Local client " .. localPlayer:GetName() .. " connected to server with ID " .. tostring(uniqueID))
	GetPlayerManager():SetLocalPlayer(localPlayer)
	GetPlayerManager():AddPlayer(localPlayer)

end


function ClientManager:ClientDisconnected(disconnectedParams)

    --Ignore any disconnect message when in the garage
    if GetMenuManager():GetState() ~= GetMenuManager().STATE_GARAGE then
        GetPlayerManager():RemoveAllPlayers()

        print("Client disconnected from server! message from script")
        print("Starting ClientManager self:UnloadMap()")

        self:UnLoadMap()

        print("Finished ClientManager self:UnloadMap()")

        self.ownedKartMapObject = nil
        self.ownedKart = nil
        self.cameraFollowPlayer = nil

        self.currentServerName = ""
    end

end


--The server will let us know ahead of time it is going to load a new map
function ClientManager:LoadMapNotification(loadMapParams)

	local mapName = loadMapParams:GetParameterAtIndex(0, true):GetStringData()
	GetMenuManager():GetChat():AddMessage("#00FFDA", "Loading map: " .. mapName)

end


function ClientManager:LoadMap(mapNameParams, forceLoadNow)

    if not forceLoadNow then
        GetMenuManager():SetLoadingBackgroundVisible(true)

        self.mapLoadPlayerGUIVis = false
        if IsValid(GetPlayerManager():GetLocalPlayer()) then
            self.mapLoadPlayerGUIVis = GetPlayerManager():GetLocalPlayer():GetGUIVisible()
            GetPlayerManager():GetLocalPlayer():SetGUIVisible(false)
        end
    end

    self.loadMapCount = 0

    if type(mapNameParams) == "string" then
        self.mapLoadName = mapNameParams
    else
        self.mapLoadName = mapNameParams:GetParameterAtIndex(0, true):GetStringData()
    end

    self.currentMapName = self.mapLoadName

    --Update the ClientSystem with the map name
    local tempParams = Parameters()
    tempParams:AddParameter(Parameter("MapName", self.mapLoadName))
    GetClientSystem():SetGameInfo(tempParams)

    if forceLoadNow then
        local loadedMap = nil
        while not IsValid(loadedMap) do
            loadedMap = self:ProcessMapLoad()
        end
        return loadedMap
	else
		--The map is going to be loaded soon, prevent the ClientWorld from processing any
		--ServerWorld commands until this load is done
		--NOTE: Try to do it globally instead
		--GetClientWorld():BufferWorldCommands(true)
		--GetClientSystem():BufferTableCommands(true)
		GetClientSystem():SetBufferNetEvents(true)
    end

end


function ClientManager:UnLoadMap()

    print("Starting ClientManager:UnLoadMap() for map named: " .. self.currentMapName)

	--If the client loaded a map then unload that map now
	if IsValid(self.mapLoader) then
		self.mapLoader:Unload()
	end
	self.currentMapName = ""

	print("Finished ClientManager:UnLoadMap()")

end


function ClientManager:GetCurrentMapName()

    return self.currentMapName

end


function ClientManager:SetCurrentServerName(setName)

    self.currentServerName = setName

end


function ClientManager:GetCurrentServerName()

    return self.currentServerName

end


function ClientManager:NewClientConnected(clientConnectedParams)

	local clientName = clientConnectedParams:GetParameterAtIndex(0, true):GetStringData()
	local clientUniqueID = clientConnectedParams:GetParameterAtIndex(1, true):GetIntData()

	print("New client connected to server named " .. clientName .. " with ID " .. tostring(clientUniqueID))

	--Add the player to the PlayerManager, 3rd param false for not local player
	--Next 2 lines take very little time
	local newPlayerClient = PlayerClient(clientName, clientUniqueID, false)
	newPlayerClient:Init()

	GetPlayerManager():AddPlayer(newPlayerClient)

    self:UpdatePlayerCount()

end


function ClientManager:ClientOnServerDisconnected(clientDisconnectedParams)

	local playerID = clientDisconnectedParams:GetParameterAtIndex(0, true):GetIntData()

	--Play the poof sound and particle effect at the old position when a client leaves the server
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	if IsValid(player) then
		local oldPosition = player:GetPosition()
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poof.wav", oldPosition, 1, 10, true, SoundSystem.LOWEST)
		GetParticleSystem():AddEffect("poof", oldPosition)
	end

	GetConsole():Print("Client disconnected from server named: " .. player:GetName())

	GetPlayerManager():RemovePlayer(player)

	self:UpdatePlayerCount()

end


function ClientManager:UpdatePlayerCount()

    local tempParams = Parameters()
    tempParams:AddParameter(Parameter("NumPlayers", tostring(GetPlayerManager():GetNumberOfPlayers())))
    tempParams:AddParameter(Parameter("NumHumanPlayers", tostring(GetPlayerManager():GetNumberOfHumanPlayers())))
    GetClientSystem():SetGameInfo(tempParams)

end


function ClientManager:InitialSyncDone(syncParams)

    --BRIAN TODO: This will prevent MenuManager:FollowObjectChange() from setting vis
    --self.initiallySynced = true
    GetMenuManager():SetLoadingBackgroundVisible(false)

end


function ClientManager:RequestConnect(connParams)

end


function ClientManager:PlayerRespawned(playerParams)

	local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
	local respawnPos = playerParams:GetParameterAtIndex(1, true):GetWVector3Data()
	local respawnOrien = playerParams:GetParameterAtIndex(2, true):GetWQuaternionData()
	local reason = playerParams:GetParameterAtIndex(3, true):GetStringData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)

	if not IsValid(player) then
	    --Not sure why this happens but it is happening
		print("Player not found that matches ID " .. playerID .. " in ClientManager:PlayerRespawned()")
		return
	end

    --Only respawns caused by hitting a respawn plane count for the lemming achievement
    if reason == "Plane" and player == GetPlayerManager():GetLocalPlayer() then
        if not IsValid(player.userData.mapRespawns) then
            player.userData.mapRespawns = 0
        end
        player.userData.mapRespawns = player.userData.mapRespawns + 1
        print("mapRespawns = "..player.userData.mapRespawns)
        if player.userData.mapRespawns >= 5 then
            self.achievements:Unlock(self.achievements.AVMT_LEMMING)
        end
    end

	print("Player: " .. player:GetName() .. " respawned!")

	local oldPosition = player:GetPosition()
	--Play the poof sound and particle effect at the old position
	GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poof.wav", oldPosition, 1, 10, true, SoundSystem.LOWEST)
	GetParticleSystem():AddEffect("poof", oldPosition)

	if not IsValid(player:GetController()) then
		error("Player " .. player:GetName() .. " has no IController in ClientManager:PlayerRespawned()")
	end

	--Notify the player controller it has respawned, it might need to do something special
	player:GetController():NotifyRespawned(respawnPos, respawnOrien)

	--Play the respawned sound at the new position
	GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Respawn.wav", respawnPos, 1, 10, true, SoundSystem.LOW)

	--Forward along to whatever cares
	self.playerRespawnedSignal:Emit(playerParams)

end


function ClientManager:WorldSetObjectOwner(ownerParams)

	local serverObjectID = ownerParams:GetParameter("ObjectID", true):GetIntData()
	local ownerID = ownerParams:GetParameter("OwnerID", true):GetIntData()

	--Retrieve the object out of the world
	--local ownedObject = GetClientWorld():GetServerObject(serverObjectID)

end

function ClientManager:GetTireSquealSoundName()
    local collisionWavName = ASSET_DIR .. "sound/"
	local wavFiles = { "Screech_1.wav", "Screech_2.wav", "Screech_3.wav" }
	local wavChoice = math.random(1, #wavFiles)
	collisionWavName = collisionWavName .. wavFiles[wavChoice]
	return tostring(collisionWavName)
end

function ClientManager:GetCollisionSoundName()
    local collisionWavName = ASSET_DIR .. "sound/"
	local wavFiles = { "Kart_to_wall_1.wav", "Kart_to_wall_2.wav", "Kart_to_wall_3.wav" }
	local wavChoice = math.random(1, #wavFiles)
	collisionWavName = collisionWavName .. wavFiles[wavChoice]
	return tostring(collisionWavName)
end


function ClientManager:GetKartCollisionSoundName()
    local collisionWavName = ASSET_DIR .. "sound/"
	local wavFiles = {"Kart_to_kart_1.wav", "Kart_to_kart_2.wav", "Kart_to_kart_3.wav" }
	local wavChoice = math.random(1, #wavFiles)
	collisionWavName = collisionWavName .. wavFiles[wavChoice]
	return tostring(collisionWavName)
end


function ClientManager:BulletCollisionStart(collParams)

	--BRIAN TODO: Collision test code
	--print("ClientManager:BulletCollisionStart() called")

	local collidePosition = WVector3()
	local aID = collParams:GetParameter("ObjectAID", true):GetIntData()
	local bID = collParams:GetParameter("ObjectBID", true):GetIntData()

	collidePosition.x = collParams:GetParameter("ImpactX", true):GetFloatData()
	collidePosition.y = collParams:GetParameter("ImpactY", true):GetFloatData()
	collidePosition.z = collParams:GetParameter("ImpactZ", true):GetFloatData()
	local appliedImpulse = collParams:GetParameter("AppliedImpulse", true):GetFloatData()
	local aMatName = collParams:GetParameter("AMaterial", true):GetStringData()
	local bMatName = collParams:GetParameter("BMaterial", true):GetStringData()
	if appliedImpulse > 50 then

		--BRIAN TODO: Collision test code
		--print("ClientManager:BulletCollisionStart() called with an effect emitted!")

		
		--Play a sound depending on the collision conditions
		--print("Collision:"..aMatName..","..bMatName)
		--if aMatName == "BulletVehicleMat" or bMatName == "BulletVehicleMat" then
		    
		    local collisionWavName = self:GetKartCollisionSoundName()
		    local volume = appliedImpulse/500
		    if appliedImpulse > 200 then
		        GetParticleSystem():AddEffect("impact", collidePosition)
		    end
		--else
		   -- return
		    --local collisionWavName = self:GetCollisionSoundName()
		    
		--end
		--[[
        local volume = 1.0
		local fixedImpulse = appliedImpulse
		if fixedImpulse > 20000.0 then
			fixedImpulse = 20000.0
		elseif fixedImpulse < 3000.0 then
			fixedImpulse = 3000.0
		end
		--local volume = (fixedImpulse / 10000.0) * 3
		local volume = 10
		print("Impulse: " .. tostring(appliedImpulse) .. " Volume: " .. tostring(volume))
		--]]
		GetSoundSystem():EmitSound(collisionWavName, collidePosition, volume, 10, true, SoundSystem.LOW)
	end

end


function ClientManager:BulletCollisionEnd(collParams)

end


function ClientManager:GetFollowPlayer()

	return self.cameraFollowPlayer

end


function ClientManager:SetCharacter(charMeshName)

    print("In ClientManager:SetCharacter(" .. charMeshName .. ")")
	if IsValid(self.ownedKart) then
		self.ownedKart:SetCharacter(charMeshName)
	end

end


function ClientManager:SetHat(hatMeshName)

	if IsValid(self.ownedKart) then
		self.ownedKart:SetHat(hatMeshName)
	end

end


function ClientManager:SetAccessory(accMeshName)

	if IsValid(self.ownedKart) then
		self.ownedKart:SetAccessory(accMeshName)
	end

end

function ClientManager:SetKart(kartMeshName)

	if IsValid(self.ownedKart) then
		self.ownedKart:SetKart(kartMeshName)
	end

end


function ClientManager:SetWheel(wheelMeshName)

	if IsValid(self.ownedKart) then
		self.ownedKart:SetWheel(wheelMeshName)
	end

end


function ClientManager:AddFakeClient()

	local newFakeClient = OGREPlayerKart()
	--Don't flatten the colors in the main menu
	newFakeClient:SetFlattenColors(true)
	newFakeClient:SetName("FakeClient" .. tostring(#self.fakeClients))

	local spawnPos = WVector3()
	local spawnOrien = WQuaternion()

	if IsValid(self.ownedKart) then
		spawnPos:Set(self.ownedKart:GetPosition())
		spawnOrien = self.ownedKart:GetOrientation()
	end

	local spawnParams = Parameters()
	spawnParams:AddParameter(Parameter("PositionX", spawnPos.x))
	spawnParams:AddParameter(Parameter("PositionY", spawnPos.y))
	spawnParams:AddParameter(Parameter("PositionZ", spawnPos.z))
	spawnParams:AddParameter(Parameter("OrientationW", spawnOrien.w))
	spawnParams:AddParameter(Parameter("OrientationX", spawnOrien.x))
	spawnParams:AddParameter(Parameter("OrientationY", spawnOrien.y))
	spawnParams:AddParameter(Parameter("OrientationZ", spawnOrien.z))
	spawnParams:AddParameter(Parameter("Scale", WVector3(1.5, 1.5, 1.5)))
	spawnParams:AddParameter(Parameter("KartName", "somethingorwhatever"))
	spawnParams:AddParameter(Parameter("CharacterName", "somethingorwhatever"))
	spawnParams:AddParameter(Parameter("WheelName", "somethingorwhatever"))
	spawnParams:AddParameter(Parameter("HatName", "somethingorwhatever"))
	spawnParams:AddParameter(Parameter("AccessoryName", "somethingorwhatever"))
	spawnParams:AddParameter(Parameter("WheelConnectionX", 0.354))
	spawnParams:AddParameter(Parameter("WheelConnectionY", 0.12))
	spawnParams:AddParameter(Parameter("WheelConnectionZFront", 0.282))
	spawnParams:AddParameter(Parameter("WheelConnectionZBack", -0.3))
	spawnParams:AddParameter(Parameter("CastShadows", true))
	spawnParams:AddParameter(Parameter("ReceiveShadows", false))

	newFakeClient:Init(spawnParams)
	--newFakeClient:SetWipeoutEnabled(true)
	newFakeClient:FlattenColors()
	table.insert(self.fakeClients, newFakeClient)

end


function ClientManager:RemoveFakeClient()

	if #self.fakeClients > 0 then
		self.fakeClients[#self.fakeClients]:UnInit()
		table.remove(self.fakeClients, #self.fakeClients)
	end

end


function ClientManager:ProcessFakeClients(frameTime)

	for index, fakeClient in ipairs(self.fakeClients) do
		fakeClient:Process(frameTime)
	end

end


function ClientManager:SetDebugKeysEnabled(setEnabled)

	self.debugKeysEnabled = setEnabled

end


function ClientManager:GetDebugKeysEnabled()

	return self.debugKeysEnabled

end


function ClientManager:ConnectToNetworkSignal(connectParams)

	local remoteSignalName = connectParams:GetParameterAtIndex(0, true):GetStringData()
	local uniqueSignalID = connectParams:GetParameterAtIndex(1, true):GetFloatData()
	if remoteSignalName == "LoadMap" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:ConnectToLocalSlot(self.loadMap)
		end
	elseif remoteSignalName == "LoadMapNotification" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:ConnectToLocalSlot(self.loadMapNotification)
		end
	elseif remoteSignalName == "ClientConnected" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:ConnectToLocalSlot(self.newClientConnected)
		end
	elseif remoteSignalName == "ClientDisconnected" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:ConnectToLocalSlot(self.clientOnServerDisconnected)
		end
	elseif remoteSignalName == "InitialSyncDone" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:ConnectToLocalSlot(self.initialSyncDone)
		end
	end

end


function ClientManager:DisconnectFromNetworkSignal(disconnectParams)

	local remoteSignalName = disconnectParams:GetParameterAtIndex(0, true):GetStringData()
	local uniqueSignalID = disconnectParams:GetParameterAtIndex(1, true):GetFloatData()
	if remoteSignalName == "LoadMap" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:DisconnectFromLocalSlot(self.loadMap)
		end
	elseif remoteSignalName == "LoadMapNotification" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:DisconnectFromLocalSlot(self.loadMapNotification)
		end
	elseif remoteSignalName == "ClientConnected" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:DisconnectFromLocalSlot(self.newClientConnected)
		end
	elseif remoteSignalName == "ClientDisconnected" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:DisconnectFromLocalSlot(self.clientOnServerDisconnected)
		end
	elseif remoteSignalName == "InitialSyncDone" then
		local networkSlot = GetClientSystem():GetNetworkSlot(uniqueSignalID)
		if networkSlot then
			networkSlot:DisconnectFromLocalSlot(self.initialSyncDone)
		end
	end

end


function ClientManager:SetGameMode(setGameMode)

	self.gameMode = setGameMode

end


function ClientManager:GetGameMode()

	return self.gameMode

end


function ClientManager:SetLoadingAllowed(setAllowed)

	self.loadingAllowed = setAllowed
	self.loadingAllowedParams:GetOrCreateParameter("Allowed"):SetBoolData(self.loadingAllowed)
	self.loadingAllowedSignal:Emit(self.loadingAllowedParams)

end


function ClientManager:GetLoadingAllowed()

	return self.loadingAllowed

end


function ClientManager:SetScreenBlurAllowed(setAllowed)

    self.screenBlurAllowed = setAllowed

end


function ClientManager:GetScreenBlurAllowed()

    return self.screenBlurAllowed

end

--CLIENTMANAGER CLASS END


--Global Getters

function GetClientInputManager()

	return GetClientManager():GetClientInputManager()

end


function GetMenuManager()

	return GetClientManager():GetMenuManager()

end


function GetDebugDrawManager()

	return GetClientManager().debugDrawManager

end


function GetCameraManager()

	return GetClientManager().cameraManager

end


function GetMapLoader()

	return GetClientManager().mapLoader

end


function AFC()

	GetClientManager():AddFakeClient()

end


function RFC()

	GetClientManager():RemoveFakeClient()

end


--Toggle Debug Keys
function TDK()

	GetClientManager():SetDebugKeysEnabled(not GetClientManager():GetDebugKeysEnabled())

end


--Are Debug Keys Enabled?
function DKE()

	return GetClientManager():GetDebugKeysEnabled()

end