UseModule("IBase", "Scripts/")

--RACECHECKPOINT CLASS START

--RaceCheckpoint is an sensor that senses any physical object that passes a defined volume
--BRIAN TODO: Make an IScriptObject
class 'RaceCheckpoint' (IBase)

function RaceCheckpoint:__init() super()

	self.name = "DefaultRaceCheckpointName"
	self.sequenceNumber = 0

	self.sensorParams = { }
	self.dimensions = WVector3()

	self.objectEnterSlot = self:CreateSlot("ObjectEnter", "ObjectEnter")
	self.objectEnterSignal = self:CreateSignal("ObjectEnter")
	self.objectParams = Parameters()

	self.objectExitSlot = self:CreateSlot("ObjectExit", "ObjectExit")

	self.nodes = { }
	self.ownedNodesStartIndex = 0
	self.ownedNodesEndIndex = 0

end


function RaceCheckpoint:BuildInterfaceDefIBase()

	self:AddClassDef("RaceCheckpoint", "IBase", "Manages a checkpoint in race mode")

end


function RaceCheckpoint:SetName(setName)

	self.name = setName

end


function RaceCheckpoint:GetName()

	return self.name

end


function RaceCheckpoint:InitIBase()

	self:InitSensor()

end


function RaceCheckpoint:InitSensor()

	self.sensor = BulletSensor()
	self.sensor:SetName(self.name)
	local params = Parameters()
	for index, param in ipairs(self.sensorParams) do
		params:AddParameter(param)
	end
	params:AddParameter(Parameter("Dimensions", self.dimensions))
	self.sensor:Init(params)
	self.sensor:GetSignal("StartCollision", true):Connect(self.objectEnterSlot)

	--self.sensor:GetSignal("EndCollision", true):Connect(self.objectExitSlot)

end


function RaceCheckpoint:UnInitSensor()

	if IsValid(self.sensor) then
		self.sensor:UnInit()
		self.sensor = nil
	end

end


function RaceCheckpoint:UnInitIBase()

	self:UnInitSensor()

end


function RaceCheckpoint:NotifyPositionChange(setPos)

	if IsValid(self.sensor) then
		self.sensor:SetPosition(setPos)
	end

end


function RaceCheckpoint:NotifyOrientationChange(setOrien)

	if IsValid(self.sensor) then
		self.sensor:SetOrientation(setOrien)
	end

end


function RaceCheckpoint:NotifyScaleChange(setScale)

end


function RaceCheckpoint:SetParameter(param)

	if param:GetName() == "OwnedNodesStartIndex" then
		self.ownedNodesStartIndex = param:GetIntData()
	elseif param:GetName() == "OwnedNodesEndIndex" then
		self.ownedNodesEndIndex = param:GetIntData()
	elseif param:GetName() == "SequenceNumber" then
		self.sequenceNumber = param:GetIntData()
	elseif param:GetName() == "Shape" then
		table.insert(self.sensorParams, Parameter(param))
	elseif param:GetName() == "CubeWidth" then
		self.dimensions.x = param:GetFloatData()
	elseif param:GetName() == "CubeHeight" then
		self.dimensions.y = param:GetFloatData()
	elseif param:GetName() == "CubeDepth" then
		self.dimensions.z = param:GetFloatData()
	end

end


function RaceCheckpoint:EnumerateParameters(params)

	params:AddParameter(Parameter("OwnedNodesStartIndex", Parameter.INT, self.ownedNodesStartIndex))
	params:AddParameter(Parameter("OwnedNodesEndIndex", Parameter.INT, self.ownedNodesEndIndex))
	params:AddParameter(Parameter("SequenceNumber", Parameter.INT, self.sequenceNumber))
	for index, param in ipairs(self.sensorParams)
	do
		params:AddParameter(Parameter(param))
	end

end


function RaceCheckpoint:Process(frameTime)

	self.sensor:Process(frameTime)

end


function RaceCheckpoint:SetNodes(setNodes)

	--Only allow tables
	if type(setNodes) == "table" then
		self.nodes = setNodes
	else
		error("Passed in parameter was not a table")
	end

end


--Returns the list of nodes that this checkpoint owns
function RaceCheckpoint:GetNodes()

	return self.nodes

end


function RaceCheckpoint:GetOwnedNodesStartIndex()

	return self.ownedNodesStartIndex

end


function RaceCheckpoint:GetOwnedNodesEndIndex()

	return self.ownedNodesEndIndex

end


function RaceCheckpoint:GetOwnsNode(node)

	if node:Get():GetIndex() < self.ownedNodesStartIndex then
		return false
	end
	if node:Get():GetIndex() > self.ownedNodesEndIndex then
		return false
	end

	return true

end


function RaceCheckpoint:ObjectEnter(enterParams)

	local enterObjectID = enterParams:GetParameter("CollideObjectID", true):GetIntData()

	self.objectParams:GetOrCreateParameter("SequenceNumber"):SetIntData(self.sequenceNumber)
	self.objectParams:GetOrCreateParameter("EnterObjectID"):SetIntData(enterObjectID)
	self.objectParams:GetOrCreateParameter("CheckpointObject"):SetStringData(self:GetName())

    --[[if IsServer() then
        local pos = WVector3(enterParams:GetParameter("ImpactX", true):GetFloatData(), enterParams:GetParameter("ImpactY", true):GetFloatData(), enterParams:GetParameter("ImpactZ", true):GetFloatData())
	    print("Object with ID: " .. enterObjectID .. " entered checkpoint " .. self:GetName() .. " at pos " .. tostring(pos) .. " at time: " .. tostring(GetServerSystem():GetTime()))
    end--]]

	self.objectEnterSignal:Emit(self.objectParams)

end


function RaceCheckpoint:ObjectExit(exitParams)

    --local exitObjectID = exitParams:GetParameter("CollideObjectID", true):GetIntData()

    --[[if IsServer() then
        local pos = WVector3(exitParams:GetParameter("ImpactX", true):GetFloatData(), exitParams:GetParameter("ImpactY", true):GetFloatData(), exitParams:GetParameter("ImpactZ", true):GetFloatData())
        print("Object with ID: " .. exitObjectID .. " exited checkpoint " .. self:GetName() .. " at pos " .. tostring(pos) .. " at time: " .. tostring(GetServerSystem():GetTime()))
    end--]]

end

--RACECHECKPOINT CLASS END