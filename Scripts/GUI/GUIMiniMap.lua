UseModule("IGUI", "Scripts/GUI/")

--GUIMINIMAP CLASS START

class 'GUIMiniMap' (IGUI)

function GUIMiniMap:__init() super()

	self.processPlayerParams = Parameters()
	self.processObjectParams = Parameters()
	self.processClock = WTimer()
	--BRIAN TODO: Once a second for testing!
	--self.processTimer = 1
	self.processTimer = 0.03

	self.mapOffset = nil

	self.otherPlayers = { }

	self.playerAddedSlot = self:CreateSlot("PlayerAdded", "PlayerAdded")
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.playerAddedSlot)

	self.playerRemovedSlot = self:CreateSlot("PlayerRemoved", "PlayerRemoved")
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.playerRemovedSlot)
	self.playerRemovedParams = Parameters()

	self.xmlLoaded = false
	self.mapLoaded = false

	local flashCreator = GUIPageCreator()
	flashCreator:SetPageName("MiniMap" .. tostring(GenerateID()))
	flashCreator:SetPageURL("GUI\\flash\\minimap\\MiniMap.swf")
	flashCreator:SetAbsoluteWidth(188)
	flashCreator:SetAbsoluteHeight(188)
	flashCreator:SetMovable(false)
	self.flashPage = GetHikariGUISystem():AddPage(flashCreator)
	--Position from the bottom right of the gui
	self.flashPage:SetAnchorPoint(HikariGUIPage.BottomRight)
	self.flashPage:SetPosition(WVector3(0.95, 0.95, 0), true)
	self.flashPage:SetTransparent(true, false)

	self:InitGUISignalsAndSlots()

	--Register this GUI with the IGUI base
	self:Set(self.flashPage)

end


function GUIMiniMap:InitIGUI()

end


function GUIMiniMap:UnInitIGUI()

	GetHikariGUISystem():RemovePage(self.flashPage:GetName())
	self.flashPage = nil

	self.xmlLoaded = false
	self.mapLoaded = false

end


function GUIMiniMap:InitGUISignalsAndSlots()

	--Slots
	self.mapLoadedSlot = self:CreateSlot("MapLoaded", "MapLoaded")
	self.flashPage:RequestSlotConnectToSignal(self.mapLoadedSlot, "MapLoaded")

	self.XMLLoadedSlot = self:CreateSlot("XMLLoaded", "XMLLoaded")
	self.flashPage:RequestSlotConnectToSignal(self.XMLLoadedSlot, "XMLLoaded")

end


function GUIMiniMap:GetReady()

	if self.xmlLoaded and self.mapLoaded then
		return true
	end
	return false

end


function GUIMiniMap:ProcessImp()

	PUSH_PROFILE("GUIMiniMap:ProcessImp()")

	if self:GetReady() then
		if self.processClock:GetTimeSeconds() > self.processTimer then
			self.processClock:Reset()

			local i = 1
			local numPlayers = GetPlayerManager():GetNumberOfPlayers()
			while i < (numPlayers + 1) do
				local player = GetPlayerManager():GetPlayer(i)

				local posX = player:GetGraphicalPosition().x
				local posZ = player:GetGraphicalPosition().z
				if IsValid(self.mapOffset) then
					posX = posX + self.mapOffset.x
					posZ = posZ + self.mapOffset.z
				end

				if player:IsLocalPlayer() then
					self.processPlayerParams:GetOrCreateParameter(0):SetFloatData(posX)
					self.processPlayerParams:GetOrCreateParameter(1):SetFloatData(posZ)
					local eulerY = player:GetGraphicalOrientation():GetEulerY()
					self.processPlayerParams:GetOrCreateParameter(2):SetFloatData(-eulerY)
					--ZOOM, values between 0 and 100
					if IsValid(player:GetController()) then
						local zoomVal = math.abs(player:GetController():GetSpeedPercent() * 100)
						--Make sure the zoom stays between 0 and 100, strange things will happen if it does not
						zoomVal = Clamp(zoomVal, 0, 100)
						self.processPlayerParams:GetOrCreateParameter(3):SetFloatData(zoomVal)
					else
						self.processPlayerParams:GetOrCreateParameter(3):SetFloatData(0)
					end
					self.flashPage:CallFunction("setPlayerPosition", self.processPlayerParams)
				else
					self.processObjectParams:GetOrCreateParameter(0):SetStringData("kart")
					self.processObjectParams:GetOrCreateParameter(1):SetStringData(tostring(player:GetUniqueID()))
					self.processObjectParams:GetOrCreateParameter(2):SetFloatData(posX)
					self.processObjectParams:GetOrCreateParameter(3):SetFloatData(posZ)
					local eulerY = player:GetGraphicalOrientation():GetEulerY()
					self.processObjectParams:GetOrCreateParameter(4):SetFloatData(-eulerY)
					self.flashPage:CallFunction("setObjectPosition", self.processObjectParams)
				end
				i = i + 1
			end
		end
	end

	POP_PROFILE("GUIMiniMap:ProcessImp()")

end


--The minimap needs a reference to the actual map
function GUIMiniMap:SetMap(setMap, miniMapPath)

	self.map = setMap
	self.mapExtents = ToWTransform(self.map:GetMapObject("SingleWorldMesh", true):Get()):GetBoundingBox()
	local mapWorldExtents = ToWTransform(self.map:GetMapObject("SingleWorldMesh", true):Get()):GetWorldBoundingBox()

	self:SetMapImage(miniMapPath, self.mapExtents:GetWidth(), self.mapExtents:GetDepth())
	self.mapOffset = mapWorldExtents:GetCenter()

end


function GUIMiniMap:SetMapImage(imageName, mapWidth, mapDepth)

	local params = Parameters()
	imageName = FindAndReplace(imageName, "\\", "/")
	imageName = FindAndReplace(imageName, "..", "uu")
	params:AddParameter(Parameter("", imageName))
	params:AddParameter(Parameter("", mapWidth))
	params:AddParameter(Parameter("", mapDepth))
	self.mapLoaded = false
	self.flashPage:CallFunction("loadMap", params)

end


function GUIMiniMap:PlayerAdded(playerParams)

	if self:GetReady() then
		if IsValid(self.flashPage) then
			local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
			local player = GetPlayerManager():GetPlayerFromID(playerID)
			self:AddPlayer(player)
		end
	end

end


function GUIMiniMap:PlayerRemoved(playerParams)

	if self:GetReady() then
		if IsValid(self.flashPage) then
			local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
			local player = GetPlayerManager():GetPlayerFromID(playerID)
			self:RemovePlayer(player)
		end
	end

end


function GUIMiniMap:AddExistingPlayers()

	if self:GetReady() then
		if IsValid(self.flashPage) then
			local i = 1
			local numPlayers = GetPlayerManager():GetNumberOfPlayers()
			while i <= numPlayers do
				local player = GetPlayerManager():GetPlayer(i)
				self:AddPlayer(player)
				i = i + 1
			end
		end
	end

end


function GUIMiniMap:RemoveAllPlayers()

	if self:GetReady() then
		for index, otherPlayer in ipairs(self.otherPlayers) do
			self.playerRemovedParams:GetOrCreateParameter(0):SetStringData("kart")
			self.playerRemovedParams:GetOrCreateParameter(1):SetStringData(tostring(playerID))
			self.flashPage:CallFunction("removeObject", self.playerRemovedParams)
		end
		self.otherPlayers = { }
	end

end


function GUIMiniMap:AddPlayer(player)

	if self:GetReady() then
		if IsValid(player) then
			--Do not attempt to add the local player
			if not player:IsLocalPlayer() then
				self.processObjectParams:GetOrCreateParameter(0):SetStringData("kart")
				self.processObjectParams:GetOrCreateParameter(1):SetStringData(tostring(player:GetUniqueID()))
				self.processObjectParams:GetOrCreateParameter(2):SetFloatData(player:GetGraphicalPosition().x)
				self.processObjectParams:GetOrCreateParameter(3):SetFloatData(player:GetGraphicalPosition().z)
				local eulerY = player:GetGraphicalOrientation():GetEulerY()
				self.processObjectParams:GetOrCreateParameter(4):SetFloatData(-eulerY)
				self.flashPage:CallFunction("setObjectPosition", self.processObjectParams)
				table.insert(self.otherPlayers, player)
			end
		end
	end

end


function GUIMiniMap:RemovePlayer(player)

	if self:GetReady() then
		if IsValid(player) then
			--Do not attempt to remove the local player
			if not player:IsLocalPlayer() then
				for index, otherPlayer in ipairs(self.otherPlayers) do
					if otherPlayer:GetUniqueID() == player:GetUniqueID() then
						self.playerRemovedParams:GetOrCreateParameter(0):SetStringData("kart")
						self.playerRemovedParams:GetOrCreateParameter(1):SetStringData(tostring(playerID))
						self.flashPage:CallFunction("removeObject", self.playerRemovedParams)
						table.remove(self.otherPlayers, index)
						break
					end
				end
			end
		end
	end

end


function GUIMiniMap:XMLLoaded()

	self.xmlLoaded = true

	if self:GetReady() then
		self:RemoveAllPlayers()
		--Add any existing players to the minimap
		self:AddExistingPlayers()
	end

end


function GUIMiniMap:MapLoaded()

	self.mapLoaded = true

	if self:GetReady() then
		self:RemoveAllPlayers()
		--Add any existing players to the minimap
		self:AddExistingPlayers()
	end

end


function GUIMiniMap:SystemInited(initParams)

	--BRIAN TODO: Get the mini map back inited with the correct map and players, etc
	self:InitGUISignalsAndSlots()

end

--GUIMINIMAP CLASS END