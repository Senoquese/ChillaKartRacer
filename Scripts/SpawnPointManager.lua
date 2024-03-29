UseModule("IBase", "Scripts/")

--SPAWNPOINTMANAGER CLASS START

class 'SpawnPointManager' (IBase)

function SpawnPointManager:__init() super()

	self.spawnPointTags = { }
	self.spawnPoints = { }
	self.currentAssignPoint = 1

end


function SpawnPointManager:BuildInterfaceDefIBase()

	self:AddClassDef("SpawnPointManager", "IBase", "Manages all the spawn points and assignment to players")

end


function SpawnPointManager:InitIBase()

end


function SpawnPointManager:UnInitIBase()

end


function SpawnPointManager:AddSpawnPoint(addPoint, addOrientation, tag)

	if addPoint == nil then
		addPoint = WVector3()
	end
	if addOrientation == nil then
		addOrientation = WQuaternion()
	end

	--If this point has a tag assigned to it, add it to that tags list
	if IsValid(tag) and string.len(tag) > 0 then
		if not IsValid(self.spawnPointTags[tag]) then
			self.spawnPointTags[tag] = { 1, { } }
		end
		--First is the current assign point for this tag
		--Second is the spawn info for this spawn point
		table.insert(self.spawnPointTags[tag][2], { addPoint, addOrientation })
	end

	--Always insert into the main list
	table.insert(self.spawnPoints, { addPoint, addOrientation, tag } )

end


--If the passed in tag is a valid non-zero length string,
--find a spawn point with the same tag
function SpawnPointManager:GetFreeSpawnPoint(tag)

	--No points in list check
	if #self.spawnPoints == 0 then
		return nil, nil
	end

	--over check
	if self.currentAssignPoint > #self.spawnPoints then
		self.currentAssignPoint = 1
	end

	--If the tag is valid and exists in the spawn point tags list,
	--find the next spawn within the tag list
	if IsValid(tag) and string.len(tag) > 0 and IsValid(self.spawnPointTags[tag]) then
		local tagSpawnPoints = self.spawnPointTags[tag]
		local tagCurrentAssignPoint = tagSpawnPoints[1]
		if tagCurrentAssignPoint > #tagSpawnPoints[2] then
			tagCurrentAssignPoint = 1
		end
		local returnPoint = tagSpawnPoints[2][tagCurrentAssignPoint]
		tagCurrentAssignPoint = tagCurrentAssignPoint + 1
		--Copy the new assign point to the tag spawn point list
		tagSpawnPoints[1] = tagCurrentAssignPoint
		return returnPoint[1], returnPoint[2]
	end

	local returnPoint = self.spawnPoints[self.currentAssignPoint]
	self.currentAssignPoint = self.currentAssignPoint + 1
	return returnPoint[1], returnPoint[2]

end

function SpawnPointManager:ResetSpawnPointer()

    self.currentAssignPoint = 1

end

function SpawnPointManager:RemoveAllSpawnPoints()

	self.spawnPointTags = { }
	self.spawnPoints = { }

end

--SPAWNPOINTMANAGER CLASS END


local spawnPointManSingleton = SpawnPointManager()
function GetSpawnPointManager()

	return spawnPointManSingleton

end