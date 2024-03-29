UseModule("IBase", "Scripts/")

--RACECHECKPOINTMANAGER CLASS START

--The RaceCheckpointManager is responsible for tracking which checkpoints a player
--has crossed and emitting a signal when a player completes a lap
class 'RaceCheckpointManager' (IBase)

function RaceCheckpointManager:__init(map, raceNodeManager) super()

	self.map = map
	self.checkpoints = { }

	self.objectEnterSlot = self:CreateSlot("ObjectEnter", "ObjectEnter")

	--This is emitted when a player enters a new checkpoint
	self.playerEntersCheckpoint = self:CreateSignal("PlayerEntersCheckpoint")
	self.playerEntersCheckpointParams = Parameters()

	--This is emitted when a player completes a lap
	self.playerFinishedLap = self:CreateSignal("PlayerFinishedLap")
	self.playerFinishedLapParams = Parameters()

	--This is emitted when a player hits a checkpoint out of order
	self.playerHitInvalidCheckpoint = self:CreateSignal("PlayerHitInvalidCheckpoint")
	self.playerHitInvalidCheckpointParams = Parameters()

	self:_InitCheckpoints(raceNodeManager)

	self.registeredPlayers = { }

	self.CP_PLAYER_BLOCK_TIMER = 2

end


function RaceCheckpointManager:BuildInterfaceDefIBase()

	self:AddClassDef("RaceCheckpointManager", "IBase", "Manages all the checkpoints")

end


function RaceCheckpointManager:InitIBase()

end


function RaceCheckpointManager:_InitCheckpoints(raceNodeManager)

	--Find all the checkpoints in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "ScriptObject" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "RaceCheckpoint" then
				table.insert(self.checkpoints, scriptObject)
				scriptObject:GetSignal("ObjectEnter", true):Connect(self.objectEnterSlot)
				self:_InitCheckpoint(scriptObject:Get(), raceNodeManager)
			end
		end
		mapObjectIter:Next()
	end

end


function RaceCheckpointManager:_InitCheckpoint(checkpoint, raceNodeManager)

	--Assign this checkpoint the nodes it owns
	local startIndex = checkpoint:GetOwnedNodesStartIndex()
	local endIndex = checkpoint:GetOwnedNodesEndIndex()
	local ownNodes = { }
	local currIndex = startIndex
	while currIndex < endIndex + 1 do
	    local ownNode = raceNodeManager:GetNode(currIndex)
		table.insert(ownNodes, ownNode)
		currIndex = currIndex + 1
	end
	checkpoint:SetNodes(ownNodes)

end


function RaceCheckpointManager:UnInitIBase()

end


function RaceCheckpointManager:Process(frameTime)

end


function RaceCheckpointManager:GetNumCheckpoints()

	return #self.checkpoints

end


--Pass in the checkpoint name or index and it will be returned
function RaceCheckpointManager:GetCheckpoint(checkpointID)

    local checkpointIDIsString = type(checkpointID) == "string"
    local checkpointIDIsNumber = type(checkpointID) == "number"
	local retCheck = nil
	for index, checkpoint in ipairs(self.checkpoints) do
		if checkpointIDIsString then
			if checkpoint:GetName() == checkpointID then
				retCheck = checkpoint
				break
			end
		elseif checkpointIDIsNumber then
			if index == checkpointID then
				retCheck = checkpoint
				break
			end
		end
	end

	return retCheck

end


--Returns which checkpoint the player is currently on (which one they passed last)
function RaceCheckpointManager:GetPlayerCheckpoint(player)

	--BRIAN TODO: Check if they are registered with the manager?
	return player.userData.currentCheckpoint

end


function RaceCheckpointManager:RegisterPlayer(newPlayer)

	--First check that this player isn't already registered
	for index, player in ipairs(self.registeredPlayers)
	do
		if player:GetUniqueID() == newPlayer:GetUniqueID() then
			--They are already registered, just return
			return
		end
	end

	newPlayer.userData.currentCheckpoint = 0
	newPlayer.userData.currentCheckpointName = ""
	table.insert(self.registeredPlayers, newPlayer)
	print("%%% Player: " .. newPlayer:GetName() .. " registered in the RaceCheckpointManager")

end


function RaceCheckpointManager:UnregisterPlayer(removePlayer)

	--Find this player is our list
	for index, player in ipairs(self.registeredPlayers) do
		--Only unregister them if they are registered already
		if player:GetUniqueID() == removePlayer:GetUniqueID() then
			player.userData.currentCheckpoint = nil
			player.userData.currentCheckpointName = nil
			table.remove(self.registeredPlayers, index)
			print("%%% Player: " .. removePlayer:GetName() .. " unregistered in the RaceCheckpointManager")
			return
		end
	end

end


function RaceCheckpointManager:ObjectEnter(enterParams)

	local sequenceNumber = enterParams:GetParameter("SequenceNumber", true):GetIntData()
	local enterObjectID = enterParams:GetParameter("EnterObjectID", true):GetIntData()
	local checkpointObject = enterParams:GetParameter("CheckpointObject", true):GetStringData()

	--Check if this is a player controller
	for index, player in ipairs(self.registeredPlayers) do
		--BRIAN TODO: Why does player:GetController() sometimes fail? player is nil or controller is?
		if IsValid(player:GetController()) and player:GetController():DoesOwn(enterObjectID) then
			if IsValid(player) then
				local isNextCheckpoint = false
				if player.userData.currentCheckpoint == 0 and sequenceNumber == 1 then
					isNextCheckpoint = true
				elseif player.userData.currentCheckpoint == sequenceNumber - 1 then
					isNextCheckpoint = true
				elseif player.userData.currentCheckpoint == self:GetNumCheckpoints() and sequenceNumber == 1 then
					isNextCheckpoint = true
					--The player completed a lap
					self.playerFinishedLapParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())
					self.playerFinishedLap:Emit(self.playerFinishedLapParams)
				end
				if isNextCheckpoint then
					player.userData.currentCheckpoint = sequenceNumber
					player.userData.currentCheckpointName = checkpointObject
					player.userData.checkpointBlockResetTime = GetNetworkSystem():GetTime()
					--The player entered a new checkpoint
					self.playerFinishedLapParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())
					self.playerFinishedLapParams:GetOrCreateParameter(1):SetIntData(player.userData.currentCheckpoint)
					self.playerEntersCheckpoint:Emit(self.playerFinishedLapParams)
				elseif not IsValid(player.userData.checkpointBlockResetTime) or
                       GetNetworkSystem():GetTime() - player.userData.checkpointBlockResetTime > self.CP_PLAYER_BLOCK_TIMER then
					--The player hit a checkpoint out of order
					local checkpoint = self:GetCheckpoint(player.userData.currentCheckpointName)
					print("Player: " .. player:GetName() .. " hit checkpoint number " .. tostring(sequenceNumber) .. " out of order, current is " .. tostring(player.userData.currentCheckpoint))
					self.playerHitInvalidCheckpointParams:GetOrCreateParameter("Player"):SetIntData(player:GetUniqueID())
					self.playerHitInvalidCheckpoint:Emit(self.playerHitInvalidCheckpointParams)
				end
			end
			break
		end
	end

end

--RACECHECKPOINTMANAGER CLASS END