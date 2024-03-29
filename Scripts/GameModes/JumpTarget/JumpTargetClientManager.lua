UseModule("IBase", "Scripts/")

--JUMPTARGETCLIENTMANAGER CLASS START

--The JumpTargetClientManager is responsible for managing the JumpTargets in the map.
class 'JumpTargetClientManager' (IBase)

function JumpTargetClientManager:__init(map) super()

	self.map = map
	self.jumpTargets = { }

	self:_InitJumpTargets()

end


function JumpTargetClientManager:BuildInterfaceDefIBase()

	self:AddClassDef("JumpTargetClientManager", "IBase", "Manages all the jump targets on the client")

end


function JumpTargetClientManager:InitIBase()

end


function JumpTargetClientManager:UnInitIBase()

	self:_UnInitJumpTargets()

end


function JumpTargetClientManager:_InitJumpTargets()

	--Find all the checkpoints in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "ScriptObject" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "JumpTarget" then
				table.insert(self.jumpTargets, scriptObject)
			end
		end
		mapObjectIter:Next()
	end

end


function JumpTargetClientManager:_UnInitJumpTargets()

end


function JumpTargetClientManager:Process()

end


function JumpTargetClientManager:GetNumJumpTargets()

	return #self.jumpTargets

end


--Pass in the jump target name or index and it will be returned
function JumpTargetClientManager:GetJumpTarget(jumpTargetID)

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


function JumpTargetClientManager:GetJumpTargets()

	return self.jumpTargets

end

--JUMPTARGETCLIENTMANAGER CLASS END