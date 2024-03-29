UseModule("IBase", "Scripts/")

--RACECHECKPOINTMARKERMANAGER CLASS START

--The RaceCheckpointMarkerManager is responsible for tracking which checkpoint a
--player needs to reach next and turning the markers on or off
class 'RaceCheckpointMarkerManager' (IBase)

function RaceCheckpointMarkerManager:__init(map) super()

	self.map = map
	self.checkpointMarkers = { }

	self:_InitCheckpointMarkers()

end


function RaceCheckpointMarkerManager:BuildInterfaceDefIBase()

	self:AddClassDef("RaceCheckpointMarkerManager", "IBase", "Manages all checkpoint markers on the client")

end


function RaceCheckpointMarkerManager:_InitCheckpointMarkers()

	--Find all the checkpoints in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "ScriptObject" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "RaceCheckpointMarker" then
				table.insert(self.checkpointMarkers, scriptObject)
			end
		end
		mapObjectIter:Next()
	end

end


function RaceCheckpointMarkerManager:InitIBase()

end


function RaceCheckpointMarkerManager:UnInitIBase()

end


function RaceCheckpointMarkerManager:Process(frameTime)

end


function RaceCheckpointMarkerManager:GetNumCheckpointMarkers()

	return #self.checkpointMarkers

end


function RaceCheckpointMarkerManager:SetCurrentCheckpoint(currentCheckpoint)

	--We want to turn on the markers for the next checkpoint, so find what checkpoint is next
	local nextCheckpoint = currentCheckpoint + 1
	--Assuming that the number of markers is twice the number of checkpoints
	if currentCheckpoint == self:GetNumCheckpointMarkers() / 2 then
		nextCheckpoint = 1
	end

	for index, marker in ipairs(self.checkpointMarkers) do
		if marker:Get():GetCheckpointIndex() == nextCheckpoint then
			marker:Get():TurnOn()
		else
			marker:Get():TurnOff()
		end
	end

end


function RaceCheckpointMarkerManager:TurnOffAllMarkers()

	for index, marker in ipairs(self.checkpointMarkers) do
		marker:Get():TurnOff()
	end

end

--RACECHECKPOINTMARKERMANAGER CLASS END