UseModule("IBase", "Scripts/")

--JUMPTARGETMANAGER CLASS START

--The JumpTargetManager is responsible for awarding points to players when
--they go into a JumpTarget
class 'JumpTargetManager' (IBase)

function JumpTargetManager:__init(map) super()

	self.map = map
	self.jumpTargets = { }

	self.objectEnterSlot = self:CreateSlot("ObjectEnterJumpTarget", "ObjectEnterJumpTarget")
	self.increasePointsSlot = self:CreateSlot("IncreasePoints", "IncreasePoints")
	self.resetPointsSlot = self:CreateSlot("ResetPoints", "ResetPoints")

	--This is emitted when a player scores points
	self.playerScoresPoints = self:CreateSignal("PlayerScoresPoints")
	self.playerScoresPointsParams = Parameters()

	self:_InitJumpTargets()

	self.registeredPlayers = { }

end


function JumpTargetManager:BuildInterfaceDefIBase()

    self:AddClassDef("JumpTargetManager", "IBase", "Manages the jump targets")

end


function JumpTargetManager:InitIBase()

end


function JumpTargetManager:UnInitIBase()

	self:_UnInitJumpTargets()

end


function JumpTargetManager:_InitJumpTargets()

	--Find all the checkpoints in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "ScriptObject" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "JumpTarget" then
				table.insert(self.jumpTargets, scriptObject)
				scriptObject:GetSignal("ObjectEnterJumpTarget", true):Connect(self.objectEnterSlot)
			end
		end
		mapObjectIter:Next()
	end

end

function JumpTargetManager:GetRandomTarget()

    return self.jumpTargets[math.modf((Random() * #self.jumpTargets) + 1)]

end

function JumpTargetManager:_UnInitJumpTargets()

	self.jumpTargets = { }

end


function JumpTargetManager:Process(frameTime)

	for index, target in ipairs(self.jumpTargets) do
		target:Process(frameTime)
	end

end


function JumpTargetManager:GetNumJumpTargets()

	return #self.jumpTargets

end


--Pass in the jump target name or index and it will be returned
function JumpTargetManager:GetJumpTarget(jumpTargetID)

	for index, target in ipairs(self.jumpTargets) do
		if type(jumpTargetID) == "string" then
			if target:GetName() == jumpTargetID then
				return target
			end
		elseif type(jumpTargetID) == "number" then
			if index == jumpTargetID then
				return target
			end
		end
	end

end


function JumpTargetManager:RegisterPlayer(newPlayer)

	--First check that this player isn't already registered
	for index, player in ipairs(self.registeredPlayers)
	do
		if player:GetUniqueID() == newPlayer:GetUniqueID() then
			--They are already registered, just return
			return
		end
	end

	table.insert(self.registeredPlayers, newPlayer)
	print("%%% Player: " .. newPlayer:GetName() .. " registered in the JumpTargetManager")

end


function JumpTargetManager:UnregisterPlayer(removePlayer)

	--Find this player is our list
	for index, player in ipairs(self.registeredPlayers) do
		--Only unregister them if they are registered already
		if player:GetUniqueID() == removePlayer:GetUniqueID() then
			table.remove(self.registeredPlayers, index)
			print("%%% Player: " .. removePlayer:GetName() .. " unregistered in the JumpTargetManager")
			return
		end
	end

end


function JumpTargetManager:ObjectEnterJumpTarget(enterParams)

	local points = enterParams:GetParameter("Points", true):GetIntData()
	local jumpTargetName = enterParams:GetParameter("JumpTarget", true):GetStringData()
	local jumpTarget = self:GetJumpTarget(jumpTargetName)
	local enterObjectID = enterParams:GetParameter("EnterObjectID", true):GetIntData()

	--Check if this is a player kart
	for index, player in ipairs(self.registeredPlayers) do
		if player:GetController():DoesOwn(enterObjectID) then
			--The player entered a new checkpoint
			self.playerScoresPointsParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())
			self.playerScoresPointsParams:GetOrCreateParameter(1):SetStringData(jumpTargetName)
			self.playerScoresPointsParams:GetOrCreateParameter(2):SetIntData(points)
			self.playerScoresPoints:Emit(self.playerScoresPointsParams)

			--Now that this target has been hit, reset to the base points
			self:UpdatePoints(jumpTarget, jumpTarget:Get():GetBasePoints())
			break
		end
	end

end


function JumpTargetManager:IncreasePoints(pointsParams)

	for index, target in ipairs(self.jumpTargets) do
		self:UpdatePoints(target, target:Get():GetPoints() + 10)
	end

end


function JumpTargetManager:ResetPoints(pointsParams)

	for index, target in ipairs(self.jumpTargets) do
		self:UpdatePoints(target, target:Get():GetBasePoints())
	end

end


function JumpTargetManager:UpdatePoints(forTarget, newPointAmount)

	forTarget:Get():SetPoints(newPointAmount)

end

--JUMPTARGETMANAGER CLASS END