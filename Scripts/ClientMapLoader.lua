UseModule("IBase", "Scripts/")

--CLIENTMAPLOADER CLASS START

class 'ClientMapLoader' (IBase)

function ClientMapLoader:__init() super()

	self.mapLoadStart = self:CreateSignal("MapLoadStart")
	self.mapUnloadStart = self:CreateSignal("MapUnloadStart")
	self.mapParams = Parameters()

	local objFactory = NavObjectFactory()
	--The intended profile is the Client, only spawn client objects
	self.mapSerializer = MapSerializer("Client", GetClientWorld())
	self.map = nil
	self.mapName = ""
end


function ClientMapLoader:BuildInterfaceDefIBase()

	self:AddClassDef("ClientMapLoader", "IBase", "Handles loading and unloading maps on the client")

end


function ClientMapLoader:Load(mapName)

	--Always unload first
	self:Unload()

	self.mapLoadStart:Emit(self.mapParams)

	--Reset the physics world
	GetBulletPhysicsSystem():Reset()

	--Assume the new game mode will not manually control the roster
	GetMenuManager():GetRoster():SetManuallyControlled(false)

	self.mapName = mapName
	self.resourceLocation = "Maps\\" .. self.mapName
	LoadOgreResourceGroup(self.mapName, ASSET_DIR .. self.resourceLocation .. "\\Graphics", "FileSystem", false)

	GetOGRESystem():SetCurrentResourceGroup(self.mapName)

    print("Beginning map serialization from file")

	self.map = self.mapSerializer:MapFromFile(ASSET_DIR, self.resourceLocation .. "\\" .. self.mapName .. ".xml")
	if not IsValid(self.map) then
	    GetOGRESystem():SetCurrentResourceGroup("")
	    return nil
	end

	print("Beginning map load")
	local mapLoadClock = WTimer()
	--Only spawn objects that match the profile "Client"
	self.map:LoadMap("Client")
	print("Finished map load in " .. tostring(mapLoadClock:GetTimeSeconds()) .. " seconds")

	GetOGRESystem():SetCurrentResourceGroup("")

	self:HandleMapObjectConnections(self.map)

	--Load the settings defined in the map
	self:LoadSettings(self.mapName)

	print("Adding the default camera controller")
	--Always start out with the free move camera
	GetCameraManager():AddController(self.camFreeMove, 0)

	return self.map

end


function ClientMapLoader:LoadSettings(mapName)

    print("Start ClientMapLoader:LoadSettings()")

	--SkyBox
	local skyBoxSetting = self.map:GetSetting("SkyBox", false)
	if IsValid(skyBoxSetting) and string.len(skyBoxSetting:GetStringData()) > 0 then
		--The mapName is the resource group name
		print("Start setting the skybox to " .. skyBoxSetting:GetStringData())
		GetOGRESystem():SetSkyBox(skyBoxSetting:GetStringData(), self.mapName)
		print("Finished setting the skybox")
	else
	    print("No skybox")
		GetOGRESystem():SetSkyBox("", "")
	end

	--Fog
	local fogMode = OGRESystem.FOG_NONE
	local fogColors = { 0.5, 0.5, 0.5, 0 }
	local fogExpDensity = 50
	local fogLinStart = 100
	local fogLinEnd = 1000
	local fogModeSetting = self.map:GetSetting("FogMode", false)
	if IsValid(fogModeSetting) and string.len(fogModeSetting:GetStringData()) > 0 then
		local fogModeStr = fogModeSetting:GetStringData()
		if fogModeStr == "EXP" then
			fogMode = OGRESystem.FOG_EXP
		elseif fogModeStr == "EXP2" then
			fogMode = OGRESystem.FOG_EXP2
		elseif fogModeStr == "LINEAR" then
			fogMode = OGRESystem.FOG_LINEAR
		end
	end
	fogModeSetting = self.map:GetSetting("FogColorR", false)
	if IsValid(fogModeSetting) then
		fogColors[1] = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogColorG", false)
	if IsValid(fogModeSetting) then
		fogColors[2] = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogColorB", false)
	if IsValid(fogModeSetting) then
		fogColors[3] = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogColorA", false)
	if IsValid(fogModeSetting) then
		fogColors[4] = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogExpDensity", false)
	if IsValid(fogModeSetting) then
		fogExpDensity = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogLinearStart", false)
	if IsValid(fogModeSetting) then
		fogLinStart = fogModeSetting:GetFloatData()
	end
	fogModeSetting = self.map:GetSetting("FogLinearEnd", false)
	if IsValid(fogModeSetting) then
		fogLinEnd = fogModeSetting:GetFloatData()
	end
	GetOGRESystem():SetFog(fogMode, WColorValue(fogColors[1], fogColors[2], fogColors[3], fogColors[4]),
						   fogExpDensity, fogLinStart, fogLinEnd)

    print("Finished ClientMapLoader:LoadSettings()")

end


function ClientMapLoader:InitIBase()

	self.camFreeMove = CamControllerFreeMove(GetCamera())

end


function ClientMapLoader:UnInitIBase()

    print("Starting ClientMapLoader:UnInitIBase()")

	self.mapSerializer = nil
	self:Unload()

	if IsValid(self.camFreeMove) then
		self.camFreeMove:UnInit()
		self.camFreeMove = nil
	end

	print("Finished ClientMapLoader:UnInitIBase()")

end


function ClientMapLoader:Unload()

    print("Starting ClientMapLoader:Unload()")

	self.mapUnloadStart:Emit(self.mapParams)

	--Default to allowing loading
	GetClientManager():SetLoadingAllowed(true)

    print("Starting GetBulletPhysicsSystem():ClearCollisions()")

	--Clear all collisions
	GetBulletPhysicsSystem():ClearCollisions()

    print("Starting GetPlayerManager():ResetUserData()")

	GetPlayerManager():ResetUserData()

    print("Starting self.map:UnloadMap()")

	if IsValid(self.map) and self.map:IsLoaded() then
		self.map:UnloadMap()
		self.map = nil
		if string.len(self.mapName) > 0 then
			UnloadOgreResourceGroup(self.mapName, self.resourceLocation .. "\\Graphics")
		end
		ClearUnreferencedResources()
	end

    print("Starting GetClientWorld():DestroyAllObjects()")

	--Clear the world
	GetClientWorld():DestroyAllObjects()

    print("Starting GetCameraManager():RemoveAllControllers()")

	--Remove all controllers from the camera manager
	if IsValid(GetCameraManager()) then
		GetCameraManager():RemoveAllControllers()
	else
		print("Warning: CameraManager was invalid in ClientMapLoader:Unload()")
	end

	if IsValid(GetOGRESystem()) then
		--Remove any SkyBox
		GetOGRESystem():SetSkyBox("", "")
		--Remove any fog
		GetOGRESystem():SetFog(OGRESystem.FOG_NONE, WColorValue(), 0, 0, 0)
		--Disable all screen effects
		--GetOGRESystem():DisableAllCompositors()
		--Some compositor effects shouldn't be disabled like Tiling
		GetOGRESystem():SetCompositorEnabled("Radial Blur", false)
	else
		print("Warning: OGRESystem was invalid in ClientMapLoader:Unload()")
	end

	if IsValid(GetParticleSystem()) then
		--Clear any particles created with GetParticleSystem():AddEffect()
		GetParticleSystem():DestroyEffects()
	else
		print("Warning: ParticleSystem was invalid in ClientMapLoader:Unload()")
	end
	
	if IsValid(GetPlayerManager():GetLocalPlayer()) then
        GetPlayerManager():GetLocalPlayer():SetGUIVisible(true)
    end

    print("Finished ClientMapLoader:Unload()")

end


function ClientMapLoader:HandleMapObjectConnections(fromMap)

	if fromMap then

		local numObjs = fromMap:GetNumberOfMapObjects()
		local i = 0
		while i < numObjs do

			local currentMapObj = fromMap:GetMapObject(i, true)
			--Only do this if the map object belongs to us
			if currentMapObj:MatchProfileName("Client") then
				self:HandleMapObjectConnection(currentMapObj)
			end
			i = i + 1

		end

	else
		GetConsole():Print("Something went wrong in ClientMapLoader:HandleMapObjectConnections()")
	end

end


function ClientMapLoader:HandleMapObjectConnection(currentMapObj)

	local numCons = currentMapObj:GetNumberOfConnections()
	local c = 0
	while c < numCons do

		local currentConnection = currentMapObj:GetConnection(c)

		local connectionObj = nil
		--Try to get the object out of the map, if there is one specified
		if currentConnection:GetObjectName() ~= "" then
			connectionObj = self.map:GetMapObject(currentConnection:GetObjectName(), false)
		end
		if IsValid(connectionObj) then
			if IsValid(GetClientSystem():GetServerPeer()) and connectionObj:MatchProfileName("Server") then

				--Check if this connection should be reliable
				local reliable = true
				if currentConnection:GetTag() == "Unreliable" then
					reliable = false
				end

				--Send the request over the network
				--0 is the unique ID so that the server will generate an ID for us
				GetClientSystem():RequestConnectSignalToPeer(currentMapObj:Get():GetSignal(currentConnection:GetSignalName(), true), GetClientSystem():GetServerPeer(), 0, currentConnection:GetObjectName(), currentConnection:GetObjectSlotName(), reliable)
			else
				--Connect it locally, both objects are local to the client
				currentMapObj:Get():GetSignal(currentConnection:GetSignalName(), true):Connect(connectionObj:Get():GetSlot(currentConnection:GetObjectSlotName(), true))
			end
		else
			error("No map object found with name " .. currentConnection:GetObjectName() .. " while trying to make a map object connection")
		end

		c = c + 1

	end
end


function ClientMapLoader:HandleMapObjectDisconnections(fromMap)

	if fromMap then
		local numObjs = fromMap:GetNumberOfMapObjects()
		local i = 0
		while i < numObjs do

			local currentMapObj = fromMap:GetMapObject(i, true)
			--Only do this if the map object belongs to us
			if currentMapObj:MatchProfileName("Client") then
				self:HandleMapObjectDisconnection(currentMapObj)
			end
			i = i + 1

		end
	else
		error("Something went sour in ClientMapLoader:HandleMapObjectDisconnections()")
	end

end


function ClientMapLoader:HandleMapObjectDisconnection(currentMapObj)
	local numCons = currentMapObj:GetNumberOfConnections()
	local c = 0
	while c < numCons do

		local currentConnection = currentMapObj:GetConnection(c)

		local connectionObj = nil
		--Try to get the object out of the map, if there is one specified
		if currentConnection:GetObjectName() ~= "" then
			connectionObj = self.map:GetMapObject(currentConnection:GetObjectName(), false)
		end
		if IsValid(connectionObj) then
			if connectionObj:MatchProfileName("Server") then
				--Send the request over the network
				if IsValid(GetClientSystem():GetServerPeer()) then
                    local networkSignal = GetClientSystem():GetServerPeer():GetPeerSignal(currentConnection:GetSignalName(), currentConnection:GetObjectName(),
                                                                                          currentConnection:GetObjectSlotName(), false)
				end

                if IsValid(networkSignal) and IsValid(GetClientSystem():GetServerPeer()) then
					GetClientSystem():RequestDisconnectSignalFromPeer(networkSignal, GetClientSystem():GetServerPeer())
				end
			else
				--Disconnect it locally, both objects are local to the client
				currentMapObj:Get():GetSignal(currentConnection:GetSignalName(), true):Disconnect(connectionObj:Get():GetSlot(currentConnection:GetObjectSlotName(), true))
			end
		else
			error("No map object found with name " .. currentConnection:GetObjectName() .. " while trying to make a map object disconnection")
		end

		c = c + 1

	end
end


function ClientMapLoader:GetMap()

	return self.map

end

--CLIENTMAPLOADER CLASS END