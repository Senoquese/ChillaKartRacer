UseModule("IBase", "Scripts/")

--PLAYERSPAWNPOINT CLASS START

--BRIAN TODO: Make an IScriptObject
--BRIAN TODO: Generalize as a simple spawn point (enemies too! not just players)
class 'PlayerSpawnPoint' (IBase)

function PlayerSpawnPoint:__init() super()

	self.spawnPos = WVector3()
	self.spawnOrien = WQuaternion()
	self.tag = ""

end


function PlayerSpawnPoint:BuildInterfaceDefIBase()

	self:AddClassDef("PlayerSpawnPoint", "IBase", "Defines a spawn point")

end


function PlayerSpawnPoint:SetParameter(param)

	if param:GetName() == "Tag" then
		self.tag = param:GetStringData()
	end

end


function PlayerSpawnPoint:NotifyPositionChange(newPos)

	self.spawnPos = newPos

end


function PlayerSpawnPoint:NotifyOrientationChange(newOrien)

	self.spawnOrien = newOrien

end


function PlayerSpawnPoint:InitIBase()

	GetSpawnPointManager():AddSpawnPoint(self.spawnPos, self.spawnOrien, self.tag)

end


function PlayerSpawnPoint:UnInitIBase()

end


function PlayerSpawnPoint:EnumerateParameters(params)

end

--PLAYERSPAWNPOINT CLASS END