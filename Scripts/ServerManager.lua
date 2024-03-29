UseModule("IBase", "Scripts/")
UseModule("ServerSettingsManager", "Scripts/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("PlayerServer", "Scripts/")
UseModule("SpawnPointManager", "Scripts/")
UseModule("WeaponManagerServer", "Scripts/SyncedObjects/Weapons/")

--SERVERMANAGER CLASS START

class 'ServerManager' (IBase)

function ServerManager:__init() super()

	--profiler:start("LuaProfilerData.txt")

    --Server Settings Manager
    self.serverSettings = ServerSettingsManager()

	--This is how many bots are currently spawned due to min number of players enforcements
    self.minPlayersEnforcementBots = 0

    --Connections are only allowed when we have a map loaded
    GetServerSystem():SetAllowClientConnections(false)

	self.objFactory = ServerObjectFactory()
	--The intended profile is the Server, only spawn server objects
	self.mapSerializer = MapSerializer("Server", GetServerWorld())
	self.map = nil
	self.mapName = nil

	self.mapTimeLimitClock = WTimer()
	self.mapTimeLimit = 300

	--These are used to keep track of when a map should load
	self.deferredLoadMap = false
	self.deferredLoadMapName = ""
	self.deferredLoadMapClock = WTimer()
	self.deferredLoadMapTimer = 3

	self.reportScriptMem = WTimer()
	self.reportScriptMemTimer = 10

	--General params to be used for anything
	self.params = Parameters()

    --Nickname and prefix used for server messages
    self.serverMsgPrefix = "_SM_"
    
	--Grab some processing time
	self.processSlot = self:CreateSlot("Process", "Process")
	--We will process after the script system
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	GetServerSystem():GetSignal("ClientConnected", true):Connect(self.clientConnectedSlot)
	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	GetServerSystem():GetSignal("ClientDisconnected", true):Connect(self.clientDisconnectedSlot)

	--The persistent signals used to send messages to the clients
	self.playerRespawnedSignal = self:CreateSignal("PlayerRespawned", GetServerSystem(), true)
	self.playerRespawnedParams = Parameters()

	--Needed to forward chat messages between clients
	self.receiveMessageSignal = self:CreateSignal("ReceiveChatMessage", GetServerSystem(), true)
	self.sendMessageSlot = self:CreateSlot("SendChatMessage", "SendChatMessage", GetServerSystem())

	self.mapRotator = nil
	self:LoadMapRotation("DefaultMapRotation.lua")

end


function ServerManager:BuildInterfaceDefIBase()

	self:AddClassDef("ServerManager", "IBase", "Manages the server")

end


function ServerManager:InitIBase()

end


function ServerManager:UnInitIBase()

end


function ServerManager:__finalize()

	--profiler:stop()

end


function ServerManager:Process()

	if self.deferredLoadMap then
		if self.deferredLoadMapClock:GetTimeSeconds() > self.deferredLoadMapTimer then
			self:LoadMapNow(self.deferredLoadMapName)
			self.deferredLoadMap = false
		end
	end

	--Check if we should switch maps
	if not self.deferredLoadMap and IsValid(tonumber(self.serverSettings.mapTime)) then
		if self.mapTimeLimitClock:GetTimeSeconds() > tonumber(self.serverSettings.mapTime)*60 and not self:GetGameMode():GetGameRunning() then
			self:LoadNextMapInRotation()
		end
	end

	--if self.reportScriptMem:GetTimeSeconds() > self.reportScriptMemTimer then
	--	self.reportScriptMem:Reset()
	--	print("Number of KB used by script: " .. tostring(GetScriptSystem():GetNumberKBUsed()))
	--end

	--Make sure there are always minNumPlayers in the server
	--Make sure there is a map loaded first
	if IsValid(self.map) then
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		local numRealPlayers = numPlayers-self.minPlayersEnforcementBots
		if numPlayers < self.serverSettings.minPlayers then
			--Make sure we haven't already spawned enough bots to fill up the slots
			--This needs to happens as it takes time for bots to connect to the server
			--print(self.minPlayersEnforcementBots.." + "..numPlayers.." < "..self.serverSettings.minPlayers)
			if self.minPlayersEnforcementBots + numRealPlayers < self.serverSettings.minPlayers then
				--Spawn bots to take up these spots
				local numToSpawn = self.serverSettings.minPlayers - numPlayers
				print("Adding " .. numToSpawn .. " bots because min players is now " .. self.serverSettings.minPlayers)
				SB(numToSpawn)
				self.minPlayersEnforcementBots = self.minPlayersEnforcementBots + numToSpawn
			end
		end
		--Make sure there are only bots for the min number of players
		if numPlayers > self.serverSettings.minPlayers and self.minPlayersEnforcementBots > 0 then
			local numToDelete = numPlayers - self.serverSettings.minPlayers
			print("Deleting " .. numToDelete .. " bots because min players is now " .. self.serverSettings.minPlayers)
			DB(numToDelete)
			self.minPlayersEnforcementBots = self.minPlayersEnforcementBots - numToDelete
			if self.minPlayersEnforcementBots < 0 then
			   self.minPlayersEnforcementBots = 0
            end 
		end
	end

end


function ServerManager:LoadMapRotation(mapRotationFilename)

    --[[
	local mapRotationCreator = loadfile(mapRotationFilename)
	if IsValid(mapRotationCreator) then
		self.mapRotator = mapRotationCreator()
		self:LoadNextMapInRotation()
	else
		print("Map rotation file " .. mapRotationFilename .. " failed to load!")
	end
	--]]
	
	self:LoadNextMapInRotation()

end


function ServerManager:LoadNextMapInRotation()

    --[[
	if IsValid(self.mapRotator) then
		local loadMapName, loadMapTimeLimit = self.mapRotator:NextMap()
		self:LoadMap(loadMapName, loadMapTimeLimit)
	end
	--]]
	
	local nextMap = self:GetNextMap()
	self:LoadMap(nextMap, tonumber(self.serverSettings.mapTime))
end

function ServerManager:GetNextMap()
	if not IsValid(self.currentMap) then
	    return self.serverSettings.mapCycle[1]
	    --self:LoadMap(self.serverSettings.mapCycle[1], tonumber(self.serverSettings.mapTime))
	else
	    -- find next map
	    local curIndex = 0
	    for i=1,#self.serverSettings.mapCycle do
	        if self.currentMap == self.serverSettings.mapCycle[i] then
	            curIndex = i
	            break
	        end
	    end
	    local nextIndex = curIndex + 1
	    if nextIndex > #self.serverSettings.mapCycle then
	        nextIndex = 1
	    end
	    return self.serverSettings.mapCycle[nextIndex]
	    --self:LoadMap(self.serverSettings.mapCycle[nextIndex], tonumber(self.serverSettings.mapTime))
	end

end


--LoadMap doesn't load the map immediately, it notifies the clients first
function ServerManager:LoadMap(setMapName, setMapTimeLimit)
    
    print("ServerManager:LoadMap "..setMapName)

	--If there is no currentMap already, the server just started up
	if not IsValid(self.currentMap) then
		self.currentMap = setMapName
		--self.mapTimeLimit = setMapTimeLimit*60
		self.firstLoad = true
	else
		self.currentMap = setMapName
		--self.mapTimeLimit = setMapTimeLimit*60

		--First notify the clients we are loading a map
		self.params:GetOrCreateParameter(0):SetStringData(setMapName)
		GetServerSystem():EmitSignalToAllPeers("LoadMapNotification", self.params)
		--Setup the load that will happen soon
		self.deferredLoadMap = true
		self.deferredLoadMapName = setMapName
		self.deferredLoadMapClock:Reset()

		print("Notifying the clients of map load: " .. self.deferredLoadMapName ..
			  ". Loading in " .. tostring(self.deferredLoadMapTimer) .. " seconds...")
	end

end


function ServerManager:LoadMapNow(setMapName)

    GetServerSystem():SetIgnorePing(true)

	self.mapName = setMapName
	print("Loading Map: " .. self.mapName)

	--Remove all weapons
	GetWeaponManagerServer():RemoveWeapons(nil)

	if IsValid(self.map) then
		self.map:UnloadMap()
		self.map = nil
	end

	--Clear the world
	GetServerWorld():DestroyAllObjects()

	--Clear all collisions
	GetBulletPhysicsSystem():ClearCollisions()

	--Reset the gravity incase something changed it
	local anyTags = Tags(Tags.ANY)
	GetBulletPhysicsSystem():SetGravity(anyTags, GetBulletPhysicsSystem():GetDefaultGravity(anyTags))

	--Re-enable all the players controllers in case any are disabled
	self:ReEnableAllControllers()

	--Reset all the players before resetting the "Map" StateTable
	self:ResetAllPlayers()

	--Clear the "Map" StateTable on a map load
	GetServerSystem():GetSendStateTable("Map"):Reset()

	--Clear the spawn points before loading the next map
	GetSpawnPointManager():RemoveAllSpawnPoints()

	--Reset all the players user data upon a new map load
	GetPlayerManager():ResetUserData()

	--Reset the physics world
	GetBulletPhysicsSystem():Reset()

	local numBots = GetBotSystem():GetNumBots()
	--Remove all bots
	DB()
	--Default the bot type
    self:SetCurrentBotType("TestBot")

	--We must notify the clients to load this map before loading it ourselves,
	--otherwise the server will spawn objects and the client will destroy them
	--while loading the map
	self.params:GetOrCreateParameter(0):SetStringData(self.mapName)
	GetServerSystem():EmitSignalToAllPeers("LoadMap", self.params)

	self.map = self.mapSerializer:MapFromFile(ASSET_DIR, "Maps/" .. self.mapName .. "/" .. self.mapName .. ".xml")
	--Only spawn objects that match the profile "Server"
	self.map:LoadMap("Server")

	local numClients = GetServerSystem():GetNumberOfClients()

	--Make all the local map object connections (passed in nil client specifies this)
	self:HandleMapObjectConnections(nil)

	--Make the Server MapObject connections to all the connected clients
	local c = 0
	while c < numClients do
		local currentClient = GetServerSystem():GetPeerAtIndex(c)
		self:HandleMapObjectConnections(currentClient)
		--Notify this client they have finished syncing
		currentClient:GetPeerSignal("InitialSyncDone", "", "", true):Emit(Parameters())
		c = c + 1
	end

	--Respawn all the bots that were in the server before the map unload
	SB(numBots, nil, self:GetCurrentBotType())

	GetConsole():Print("Done Loading Map: " .. self.mapName)

	--Tell the ServerSystem the name of the currently loaded map
	GetServerSystem():SetCurrentMapName(self.mapName)

	--Reset the map time limit clock
	self.mapTimeLimitClock:Reset()

	GetServerSystem():SetIgnorePing(false)

	--We know we have a map loaded now, allow connections
	GetServerSystem():SetAllowClientConnections(true)

end


function ServerManager:ResetAllPlayers()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:Reset()
		i = i + 1
	end

end


function ServerManager:ReEnableAllControllers()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:SetControllerEnabled(true)
		i = i + 1
	end

end


function ServerManager:HandleMapObjectConnections(forClient)

	if self.map then

		local numObjs = self.map:GetNumberOfMapObjects()
		local i = 0
		while i < numObjs do

			local currentMapObj = self.map:GetMapObject(i, true)
			--Only do this if the map object belongs to us
			if currentMapObj:MatchProfileName("Server") then
				self:HandleMapObjectConnection(forClient, currentMapObj)
			end
			i = i + 1

		end

	else
		GetConsole():Print("No map loaded in call to ServerManager:HandleMapObjectConnections()")
	end

end


function ServerManager:HandleMapObjectConnection(forClient, currentMapObj)

	local numCons = currentMapObj:GetNumberOfConnections()
	local c = 0
	while c < numCons do

		local currentConnection = currentMapObj:GetConnection(c)

		--Send this over the network if it isnt for the Server
		--otherwise, connect it locally
		local connectionObj = nil
		--Try to get the object out of the map, if there is one specified
		if currentConnection:GetObjectName() ~= "" then
			connectionObj = self.map:GetMapObject(currentConnection:GetObjectName(), true)
		end
		if connectionObj ~= nil then
			--Only attempt to connect to the client if this object is intended for the client
			--and the client is valid
			if connectionObj:MatchProfileName("Client") and IsValid(forClient) then

				--Check if this connection should be reliable
				local reliable = true
				if currentConnection:GetTag() == "Unreliable" then
					reliable = false
				end

				--print("Connecting signal: " .. currentConnection:GetSignalName() .. " of object: " .. currentMapObj:GetName())
				--print("To slot: " .. currentConnection:GetObjectSlotName() .. " of object: " .. currentConnection:GetObjectName())
				--Send the request over the network
				--print("Over the network")
				--print("For Client named: " .. forClient:GetName())
				GetServerSystem():RequestConnectSignalToPeer(currentMapObj:Get():GetSignal(currentConnection:GetSignalName(), true), forClient, GetServerSystem():GenerateUniqueID(),
															 currentConnection:GetObjectName(), currentConnection:GetObjectSlotName(), reliable)
			--Only connect locally if no client was specified
			elseif not IsValid(forClient) then
				--Connect it locally, both objects are local to the server
				--print("Connecting signal: " .. currentConnection:GetSignalName() .. " of object: " .. currentMapObj:GetName())
				--print("To slot: " .. currentConnection:GetObjectSlotName() .. " of object: " .. currentConnection:GetObjectName())
				--print("Locally")
				currentMapObj:Get():GetSignal(currentConnection:GetSignalName(), true):Connect(connectionObj:Get():GetSlot(currentConnection:GetObjectSlotName(), true))
			end
		else
		    error("No map object found with name " .. currentConnection:GetObjectName() .. " while trying to make a map object connection")
		end

		c = c + 1

	end
end


function ServerManager:AddKartCustomSettingsToStateTable(addPlayer, customItemParams)

	local p = 0
	while p < customItemParams:GetNumberOfParameters() do
		local currentCustomParam = customItemParams:GetParameterAtIndex(p, true)
		GetServerSystem():GetSendStateTable("General"):NewState(tostring(addPlayer:GetUniqueID()) .. currentCustomParam:GetName())
		GetServerSystem():GetSendStateTable("General"):SetState(tostring(addPlayer:GetUniqueID()) .. currentCustomParam:GetName(), currentCustomParam)
		p = p + 1
	end
	--Save the custom item params in the player so the state table can be cleaned when the player leaves
	addPlayer.customItemParams = customItemParams

end


function ServerManager:RemoveKartCustomSettingsToStateTable(removedPlayer)

	local p = 0
	while p < removedPlayer.customItemParams:GetNumberOfParameters() do
		local currentCustomParam = removedPlayer.customItemParams:GetParameterAtIndex(p, true)
		GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(removedPlayer:GetUniqueID()) .. currentCustomParam:GetName())
		p = p + 1
	end

end


function ServerManager:RespawnPlayer(playerUniqueID, spawnPos, spawnOrien, tag, reason)

	local player = GetPlayerManager():GetPlayerFromID(playerUniqueID)
	--Tell the player it is in the process of respawning
	if IsValid(player) then
	    player:SetRespawning(true)
	end

	if spawnPos == nil or spawnOrien == nil then
		spawnPos, spawnOrien = GetSpawnPointManager():GetFreeSpawnPoint(tag)
		if spawnPos == nil or spawnOrien == nil then
			spawnPos = WVector3()
			spawnOrien = WQuaternion()
		end
	end

	if IsValid(player) and IsValid(player:GetController()) then
		--Respawn
		player:GetController():SetPosition(spawnPos)
		player:GetController():SetOrientation(spawnOrien)
		player:GetController():Reset()

		--Notify the player controller it has respawned, it might need to do something special
		player:GetController():NotifyRespawned(spawnPos, spawnOrien)

		print("Respawned player: " .. player:GetName())

		--Let all the clients know
		self.playerRespawnedParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())
		--Respawn position
		self.playerRespawnedParams:GetOrCreateParameter(1):SetWVector3Data(spawnPos)
		self.playerRespawnedParams:GetOrCreateParameter(2):SetWQuaternionData(spawnOrien)
		if not IsValid(reason) then
		    reason = ""
		end
		self.playerRespawnedParams:GetOrCreateParameter(3):SetStringData(reason)
		self.playerRespawnedSignal:Emit(self.playerRespawnedParams)
	end

    if IsValid(player) then
	    player:SetRespawning(false)
	end

end


function ServerManager:ClientConnected(connectParams)

    local clientConnectClock = WTimer()

	--Do some basic checks...
	local clientName = connectParams:GetParameterAtIndex(0, true):GetStringData()
	local clientID = connectParams:GetParameterAtIndex(1, true):GetIntData()
	--Copy the custom item data into new parameters
	local customItemParams = Parameters()
	local currParam = 2
	while currParam < connectParams:GetNumberOfParameters() do
		customItemParams:AddParameter(connectParams:GetParameterAtIndex(currParam, true))
		currParam = currParam + 1
	end

	if clientName == nil or clientName:len() == 0 then
		print("No client name sent to ServerManager:ClientConnected()")
		return
	end
	local connectedClient = GetServerSystem():GetPeerFromID(clientID)
	if connectedClient == nil then
		print("No client named " .. clientName .. " in the NetworkSystem in ServerManager:ClientConnected()")
		return
	end

	if not IsValid(self.map) then
		--If no map is loaded, boot the player from the server
		GetServerSystem():DisconnectPeer(connectedClient, "Server does not have a map loaded")
		return
	end

	--Notify the connected clients of the new connection (before we setup the new client)
	self.params:GetOrCreateParameter(0):SetStringData(connectedClient:GetName())
	--Send the uniqueID of this peer
	self.params:GetOrCreateParameter(1):SetIntData(connectedClient:GetUniqueID())
	GetServerSystem():EmitSignalToAllPeers("ClientConnected", self.params)

	--Add the required signals to this new peer
	--This signal notifies the client that a new client connected
	local clientConnected = self:CreateSignal("ClientConnected")
	GetServerSystem():RequestConnectSignalToPeer(clientConnected, connectedClient, GetServerSystem():GenerateUniqueID(), "", "", true)

	--This signal notifies the client that a client disconnected
	local clientDisconnected = self:CreateSignal("ClientDisconnected")
	GetServerSystem():RequestConnectSignalToPeer(clientDisconnected, connectedClient, GetServerSystem():GenerateUniqueID(), "", "", true)

	local initialSyncDoneSignal = self:CreateSignal("InitialSyncDone")
	GetServerSystem():RequestConnectSignalToPeer(initialSyncDoneSignal, connectedClient, GetServerSystem():GenerateUniqueID(), "", "", true)

	--This signal notifies the client to load a map
	local loadMap = self:CreateSignal("LoadMap")

	GetServerSystem():RequestConnectSignalToPeer(loadMap, connectedClient, GetServerSystem():GenerateUniqueID(), "", "", true)

	--This signal notifies the client that a new map is going to load soon
	local loadMapNotification = self:CreateSignal("LoadMapNotification")
	GetServerSystem():RequestConnectSignalToPeer(loadMapNotification, connectedClient, GetServerSystem():GenerateUniqueID(), "", "", true)

	--Tell the new client to load the current map if it is already loaded on the server
	self.params:GetOrCreateParameter(0):SetStringData(self.mapName)
	connectedClient:GetPeerSignal("LoadMap", "", "", true):Emit(self.params)

	--Client must be added to the world right after loading the map
	--We must add the client to the world before adding the player to the player manager
	--because the player manager has a signal that any connecting slots (game mode) may
	--use to spawn objects because of this new client
	self:AddClientToWorld(connectedClient, connectParams)

    --NOTE: The next chunk takes almost 0 time
	--Right after the map is loaded, Notify the connected client of all the currently connected players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		if player:GetUniqueID() ~= connectedClient:GetUniqueID() then
			self.params:GetOrCreateParameter(0):SetStringData(player:GetName())
			self.params:GetOrCreateParameter(1):SetIntData(player:GetUniqueID())
			connectedClient:GetPeerSignal("ClientConnected", "", "", true):Emit(self.params)
		end
		i = i + 1
	end

    --NOTE: The next chunk takes almost 0 time
	--Add the player to the PlayerManager
	local newPlayerServer = PlayerServer(connectedClient:GetName(), connectedClient:GetUniqueID(), connectedClient)
	newPlayerServer:Init()

	local addPlayerToManagerClock = WTimer()
	GetPlayerManager():AddPlayer(newPlayerServer)
	print("** AddPlayerToManager Time: " .. tostring(addPlayerToManagerClock:GetTimeSeconds()))

	--Make the server MapObject connections to the client that just connected
	self:HandleMapObjectConnections(connectedClient)

    --NOTE: The next chunk takes almost 0 time
	self:AddKartCustomSettingsToStateTable(newPlayerServer, customItemParams)

    connectedClient:GetPeerSignal("InitialSyncDone", "", "", true):Emit(Parameters())

    print("** Client Connect From Script Time: " .. tostring(clientConnectClock:GetTimeSeconds()))

end


function ServerManager:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	local disconnectedClient = GetServerSystem():GetPeerFromID(playerID)
	if disconnectedClient == nil then
		GetConsole():Print("Invalid client ID passed into ServerManager:ClientDisconnected()")
		return
	end

	if IsValid(player) then
		--Must remove the player before doing anything else?
		local playerName = player:GetName()
		GetPlayerManager():RemovePlayer(player)

		self:RemoveClientFromWorld(disconnectedClient)

		self:RemoveKartCustomSettingsToStateTable(player)

		--Notify the remaining clients of the disconnection
		self.params:GetOrCreateParameter(0):SetIntData(playerID)
		GetServerSystem():EmitSignalToAllPeers("ClientDisconnected", self.params)

		GetConsole():Print("Client named " .. playerName .. " disconnected!")
	end

end


function ServerManager:AddClientToWorld(addClient, connectParams)

	local disableWorldSync = false
	local disableWorldSyncParam = connectParams:GetParameter("DisableWorldSync", false)
	if IsValid(disableWorldSyncParam) then
		disableWorldSync = disableWorldSyncParam:GetBoolData()
	end
	--Notify the ServerWorld of this new client
	GetServerWorld():ClientConnected(addClient, disableWorldSync)

end


function ServerManager:RemoveClientFromWorld(removeClient)

	--Notify the ServerWorld that this client disconnected
	GetServerWorld():ClientDisconnected(removeClient)

end


--Handle chat forwarding
function ServerManager:SendChatMessage(sendParams)

	local player = sendParams:GetParameterAtIndex(0, false)
	local message = sendParams:GetParameterAtIndex(1, false)
	local prefixLen = self.serverMsgPrefix:len()
	local peerID = sendParams:GetParameter("PeerID", true):GetIntData()
	if IsValid(player) and IsValid(message) then
	    message = message:GetStringData()
	    local messageLen = message:len()
	    
	    if player:GetStringData() == self.serverMsgPrefix then
            while messageLen >= prefixLen and message:sub(1, prefixLen) == self.serverMsgPrefix do
                if messageLen == prefixLen then --Don't send blank messages
                    return nil
                end
                
                -- If the player's name happens to be the server prefix, strip out the prefix from the beginning
                -- of their message, if it exists.
                message = message:sub(prefixLen + 1)
            end
            
            sendParams:GetOrCreateParameter(1):SetStringData(message)
	    end
		print("*** " .. player:GetStringData() .. " (SID:" .. GetSteamServerSystem():GetClientSteamID(peerID) .. "): " .. message)
		--Foward it along...
		self.receiveMessageSignal:Emit(sendParams)
	end

end

--Handle forwarding special messages from the server
function ServerManager:SendServerMessage(message)
    --local message = sendParams:GetParameterAtIndex(0, true)
    
    --if IsValid(message) then
        local newParams = Parameters()
        newParams:GetOrCreateParameter(0):SetStringData(self.serverMsgPrefix)
        newParams:GetOrCreateParameter(1):SetStringData(self.serverMsgPrefix .. message)
        self.receiveMessageSignal:Emit(newParams)
    --end
end

function ServerManager:SetGameMode(setGameMode)

	self.gameMode = setGameMode

end


function ServerManager:GetGameMode()

	return self.gameMode

end

function ServerManager:RemoveMapFromCycle(map)

    for i=1,#self.serverSettings.mapCycle do
	    if map == self.serverSettings.mapCycle[i] then
            table.remove(self.serverSettings.mapCycle,i)
	        return
	    end
	end

end

function ServerManager:AddMapToCycle(map)

    table.insert(self.serverSettings.mapCycle, map)

end

function ServerManager:SetMinPlayers(min)

    print("ServerManager:SetMinPlayers: "..min)
    self.serverSettings.minPlayers = min

end

function ServerManager:SetMaxPlayers(max)

    self.serverSettings.maxPlayers = max

end

function ServerManager:SetMapTime(time)

    self.serverSettings.mapTime = time

end

function ServerManager:SetKartCC(speed)

    self.serverSettings.kartCC = speed

end

function ServerManager:SetCurrentBotType(setType)

	self.currentBotType = setType

end


function ServerManager:GetCurrentBotType()

	return self.currentBotType

end


local bots = { }
local botFirstNames = { "Boss", "Fuzzy", "Dash", "Rick", "Wendy", "Doc", "Karate", "Llewelyn", "Anton", "Princess", "Clark", "Marty", "Sonic", "Krang", "Splinter", "Sensei", "Domo", "Sparky", "Hiro", "Chuck", "Huckleberry", "Red", "Mac", "Francois", "Frank", "John", "Delbert", "Coco", "Bixworth", "Zorro", "Prince", "Count", "Vladmir", "Charlene", "Darcy", "Bertha", "Lulz", "Penny", "Tina", "Brock", "Little", "Donny", "Cleo", "Hobert", "Thaddeus", "Wendell", "Dante", "Herman", "Seven", "Soda", "Bunny", "Cosmo", "Ted", "Liberty", "Fancy", "Pants", "Ives", "Mama", "Papa", "Uncle", "Auntie", "Cousin", "Carlito", "Roger", "DJ", "Atticus", "Axel", "Bubba", "MC", "Miss", "Mister", "Bozzo", "Beeps", "Butters", "Buster", "Snake", "Buddy", "Bubbles", "Jefe", "Fonzie", "Earl", "Floyd", "Elroy", "Elvis", "Dexter", "Wiz", "Evil", "Buzzsaw", "Foxy", "Thor", "Mad Dog", "Snowball", "Ichabod", "Gizmo", "Gumby", "Herbie", "America", "Lulu", "Lucy", "Muffin", "Zero", "Nibbles", "Lexis", "Lucky", "Napoleon", "Darth", "Velcro", "Punchy", "King", "Jade", "Queen", "Rosie", "Eva", "Baby", "Doctor", "Ludicrus", "Puffy", "Vincent", "Carlton", "Geoff", "Patrick", "Stinky", "Mitch", "Stevie", "Bob", "Timmy", "Zap", "Turbo", "Viper", "Crazy Eyes", "Agent", "Dallas", "Master of", "Ajax", "Fred", "Albert", "Ace", "Zombie", "Annie", "Spike", "Justin", "Death", "Shooter", "Beefy", "Bruce", "Brother", "Big", "Bishop", "Jane", "Shorty", "Purple", "Red", "Blazing", "Blinky", "Don", "Pookie", "Ashley", "Turd", "Mighty", "Cap'n", "General", "Admiral", "Sgt.", "Mandy", "Britney", "Yogurt", "Cheesy", "Mickey", "Moxie", "Corky", "Fluffy", "Cutie", "Sparkle", "Spooky", "Squishy", "Shiny", "Peach", "Mario", "Teddy", "Vanilla", "Chocolate", "Pilot", "Fifi", "Apple", "Kid", "Sage", "Lowtax", "Gabe", "Tycho", "Maddox", "Forest", "Ocean", "Rocket", "Jazzy", "Rocco", "Baron von", "Kim", "Unholy", "Viking", "Speedy", "Sparkplug", "Zeus", "Taquito", "Mega", "Ruth", "Alice", "Dizzy", "Tapio", "Hikari", "Navi", "AJ", "Ogre", "Chrome", "Julius", "Daisy", "Bubby", "Aziz", "Archer", "Charlie", "Slade", "Buzz", "Artemis", "Wesley", "Terrible", "Ralph", "Anime", "Savage", "Jewel", "Cabbage", "Fez", "Reverend", "Elvira", "Dixie", "Clara", "Heidi", "Garth", "Blue", "Reggie", "Oscar", "Tobias", "Hex", "Sammie", "Alfonso", "Nancy", "Tula", "Avacado", "Eugene", "Cornelius", "Stanley", "Flippy", "Elton", "Ivan", "Brian", "Ian", "Dave", "Hot", "Tomato", "Presto", "Baggy", "Cookie", "Hanso", "Popsy", "Scooter", "Scruffy", "Smarty", "Tickles", "Twinkles", "Yoyo", "Lumpy", "Dracula", "Lando", "Stabbo", "Tippy", "Stringy", "Senator", "Cooper", "Inigo", "Cletus", "Horus", "Finnish", "Boxcar", "Harry", "Falcon", "Bixy", "Jolly", "Chicken", "Rex", "Stubbs", "Molly", "Diego", "Zaxxon", "Jethro", "Bolt", "Manny", "Kenny", "Booster", "Commodore", "Dee", "Patty", "Woody", "Guppy", "Beanbag", "Grant", "Salty", "Fats", "Crispy", "Canadian", "Zombie", "Winston", "Citizen", "Lord", "Champion", "Skippy", "Emperor", "Antonio", "Elmer", "Crybaby", "Oregon", "Bingo", "Micro", "Duke", "Romeo", "Zesty", "Spicy", "Ollie", "Rufus", "Meat", "Yuri", "Honorable", "Rocky", "Professor" }
local botLastNames = { "the Weasel", "Donkeyface", "Incredible", "Speed", "Moss", "Chigurh", "Wayne", "Ruth", "Kent", "Fury", "McFly", "O'Doyle", "Boom", "Underpants", "Jupiter", "Sputnik", "Samsonite", "Norris", "Dillinger", "McBain", "McClane", "Connor", "Kimble", "Spartan", "McClintock", "Burwell", "Slugworth", "McClure", "Herring", "Sampson", "Palmer", "Chan", "Wheeler", "Mcgee", "Guy", "Caramello", "Croissant", "Freedom", "Meatloaf", "le Riche", "Rose", "Bruiser", "Boost", "Cuddles", "Plisken", "Bootsie", "Bramble", "Octane", "Chainsaw", "Volt", "Fudge", "Evanrude", "Fuzz", "Morgan", "the Brave", "Ghost", "Blaster", "Magnum", "Elwood", "Roundhouse", "Garfunkle", "Funk", "the Bot", "Killington", "Happyface", "Face", "Gear", "Spud", "Punch", "Bot", "Shadow", "O'Brien", "Snowflake", "Thunder", "Flash", "McDoom", "Awesome", "Darkheart", "Tanner", "Winslow", "Duffy", "Stinky", "Drywall", "Farthing", "Fire", "Michigan", "Laser", "Ice", "Miester", "Nitro", "Malibu", "Lace", "Blaze", "Bronco", "Night", "Titan", "Idaho", "New York", "McBee", "Gold", "Silver", "Storm", "Cyclone", "Wolf", "Havoc", "Sky", "Steel", "Wilson", "Rogers", "Hawk", "Biggs", "Einstein", "Spoon", "Shoe", "Bush", "Bum", "Jam", "Lasagna", "Pepperoni", "Horror", "Archer", "Giggles", "Eradicator", "Zeemo", "Shark", "Batwing", "Romance", "Cake", "Wheelie", "Endo", "Barrelroll", "Twist", "Florida", "Knight", "Mamba", "Ninja", "Blackout", "Skull", "Boomsauce", "Bean", "Brain", "Sherman", "Rebellion", "Fusion", "Cheese", "Speed", "Love", "Lugnut", "Ferguson", "Bear", "Turtle", "Sock", "Dawg", "Longbottom", "Pie", "Flowers", "Spaceship", "Tuna", "Walnut", "Moon", "Wood", "Pickles", "Joe", "Ireland", "Rock", "Domino", "Phoenix", "Destroyer", "Spidergoat", "Gonzales", "Cornwad", "Dumbface", "Ravioli", "Spaghetti", "Magico", "Pantalones", "Grande", "Sterling", "Jellybean", "Libjingle", "Bullet", "Jones", "McDonald", "Ceasar", "Jackson", "Supercrush", "McCool", "Jerky", "Piledriver", "Crusher", "Horse", "Oats", "Noobcake", "HyperDuck", "Honeycutt", "Justice", "Mancini", "Burger", "Canyon", "Haywood", "Rice", "Mooney", "Tyranny", "Peanut", "McKenzie", "Margarita", "Cricket", "Burrito", "Hax", "Headshot", "Sandwich", "Tulip", "Jenkins", "Samurai", "Valentino", "Chowder", "Foxx", "Canabalt", "Scoops", "Potato", "Magnifico", "Houdini", "Britches", "Doodles", "Jingles", "Lollypop", "Shotgun", "Katana", "Machete", "Sparx", "Lobster", "Waterfall", "Blackjack", "Silverino", "Dangles", "Nixon", "Shingles", "Nougat", "Stabbington", "Roboto", "Canoe", "Brocolli", "Angelos", "Nubbins", "Calamari", "Snails", "Magma", "McGruder", "Bannister", "Champagne", "Montoya", "X", "Nugget", "Peacock", "Chesthair", "Aquatic", "Cincinnati", "Chicago", "Express", "Manzanita", "Microfiche", "Moped", "Bunyan", "Starfish", "Bill", "Crisp", "Bacon", "Cowbell", "Bandana", "Franklin", "Lint", "Winnipeg", "Nelson", "Longhorn", "Suds", "Airplane", "Rocketship", "Overload", "Cranberry", "Pendleton", "Chalmers", "Fork", "Hitchcock", "von Ludwig", "California", "Sunshine", "Hopp", "Pitchfork", "Smokestack", "Candle", "Bearclaw", "Caboose", "Beekeeper", "Helmet", "Andy", "Oklahoma", "Hotsauce" }
function GenerateBotName()

    --Using SRANDOM() as it returns >= 0 and < 1 as 1 for random will result in an index over the total number of items
    local firstName = math.modf((SRANDOM() * #botFirstNames) + 1)
	local lastName = math.modf((SRANDOM() * #botLastNames) + 1)
	local genName = botFirstNames[firstName] .. " " .. botLastNames[lastName]
	local nameValid = true

	for index, botInfo in ipairs(bots) do
	    if botInfo[2]:GetName() == genName then
	        nameValid = false
	        break
	    end
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local currPlayer = 1
	while currPlayer < numPlayers and nameValid do
	    if GetPlayerManager():GetPlayer(currPlayer):GetName() == genName then
	        nameValid = false
	        break
	    end
	    currPlayer = currPlayer + 1
	end

    if not nameValid then
        genName = GenerateBotName()
    end
	return genName

end

local botKarts = {"56 Cruiser","Barrel","Micro","Fat Boy","Rail Buggy","Baja","Barnacle Bucket","Basic Kart","Formula 2","Gumshoe","Lynx Buggy","Moonmobile","Scarab","Skullkar","Tank","Willy"}
function RandKart()
    return botKarts[math.modf((SRANDOM() * #botKarts) + 1)]
end

local botAccessories = {"000None","Hypno Glasses","Moustache","Rad Glasses","Spectacles","Steam Goggles","Stogie"}
function RandAccessory()
    return botAccessories[math.modf((SRANDOM() * #botAccessories) + 1)]
end

local botChars = {"Chinchilla", "ChinchillaBigEars", "ChinchillaTinyEars"} 
function RandChar()
    return botChars[math.modf((SRANDOM() * #botChars) + 1)]
end

local botHats = {"00None","Chinchilla Visor","Baseball Cap", "Beanie", "Devil Horns", "Halo", "Pigtails", "Propeller", "Race Helmet", "Road Cone"}
function RandHat()
    return botHats[math.modf((SRANDOM() * #botHats) + 1)]
end

local botWheels = {"Army Wheels","Star","Floating","5Star","Innertube","Donut","Bottlecaps","Buttons","Defender","Dubs","Hubbah Hubbah","Hypnowheels","Max Trax","Penny","Race Tire","Shoe Wheel","Starfish","SuperPuff","Tracks"}
function RandWheels()
    return botWheels[math.modf((SRANDOM() * #botWheels) + 1)]
end

--Pass in a number to spawn that many bots, otherwise pass nil to spawn just one
function SB(howMany, enableSync, botType)

	if IsValid(howMany) then
		local i = 0
		while i < howMany do
			--Recursion to spawn one
			SB(nil, enableSync, botType)
			i = i + 1
		end
	else
		if not IsValid(enableSync) then
		    --Default to not syncing the ServerWorld to the bots
			enableSync = false
		end
		if not IsValid(botType) then
			botType = GetServerManager():GetCurrentBotType()
		end
		local botName = GenerateBotName()
		if botType == nil then
			botType = "TestBot"
		end
		--This is what the bot will look like
		local customItemParams = Parameters()
		customItemParams:AddParameter(Parameter("KartName", RandKart()))
		customItemParams:AddParameter(Parameter("KartColor1", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("KartColor2", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("HatName", RandHat()))
		customItemParams:AddParameter(Parameter("HatColor1", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("HatColor2", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("AccessoryName", RandAccessory()))
		customItemParams:AddParameter(Parameter("AccessoryColor1", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("AccessoryColor2", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("WheelName", RandWheels()))
		customItemParams:AddParameter(Parameter("WheelColor1", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("WheelColor2", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		customItemParams:AddParameter(Parameter("CharacterName", RandChar()))
		customItemParams:AddParameter(Parameter("CharacterColor1", tostring(SRANDOM()).." "..tostring(SRANDOM()).." "..tostring(SRANDOM()).." ".." 1"))
		--Setting sync disabled makes it so world updates are not sent to this client
		customItemParams:AddParameter(Parameter("DisableWorldSync", not enableSync))
		local bot = GetBotSystem():SpawnBot(botName, botType, "Scripts/Bots/", customItemParams)
		--First is the bot ID, second is the bot instance
		table.insert(bots, { #bots, bot })
		print("Spawned Bot named " .. botName)
	end

end

--Pass in nil to remove all bots, otherwise pass in how many bots should be destroyed
function DB(howMany)

    print("Number of bots in ServerManager list: " .. tostring(#bots))
	local destroyedBotsList = { }
	for index, botInfo in ipairs(bots) do
		if not IsValid(howMany) or howMany > 0 then
			print("Removed Bot named " .. botInfo[2]:GetName())
			GetBotSystem():DestroyBot(botInfo[2]:GetName())
			table.insert(destroyedBotsList, botInfo)
			if IsValid(howMany) then
				howMany = howMany - 1
			end
			if howMany == 0 then
				break
			end
		end
	end

	--Now clear the destroyed bot(s) out of the list
	for index, botInfo in ipairs(destroyedBotsList) do
	    for botsIndex, realBotsInfo in ipairs(bots) do
	        if realBotsInfo == botInfo then
		        table.remove(bots, botsIndex)
		        break
		    end
		end
	end

end

--SERVERMANAGER CLASS END