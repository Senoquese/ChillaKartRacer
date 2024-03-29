UseModule("IBase", "Scripts/")

--JUMPTARGET CLASS START

--JumpTarget is an sensor that senses any physical object that passes a defined volume
--BRIAN TODO: Turn into a IScriptObject
--BRIAN TODO: Why is this needed? connect sensor signal to particle emitter, sound, and some kind of score
class 'JumpTarget' (IBase)

function JumpTarget:__init() super()

	self.name = "DefaultJumpTargetName"
	self.position = WVector3()
	self.orientation = WQuaternion()

	self.basePoints = 0
	self.points = 0
	self.stateParam = Parameter()

	self.sensorParams = { }
	self.dimensions = WVector3()

	self.objectEnterSlot = self:CreateSlot("ObjectEnter", "ObjectEnter")
	self.objectEnterSignal = self:CreateSignal("ObjectEnterJumpTarget")
	self.objectParams = Parameters()

	self.pointsUpdateSlot = self:CreateSlot("UpdatePoints", "UpdatePoints")

end


function JumpTarget:BuildInterfaceDefIBase()

	self:AddClassDef("JumpTarget", "IBase", "Defines a jump target which senses any physics object")

end


function JumpTarget:SetName(setName)

	self.name = setName

end


function JumpTarget:GetName()

	return self.name

end


function JumpTarget:InitIBase()

	self:InitSensor()

	if IsValid(GetServerSystem) then
		--State for this target
		GetServerSystem():GetSendStateTable("Map"):NewState(self:GetName() .. "_Points")
		if self:GetPoints() == 0 then
			error("Points cannot be 0 here")
		end
		self.stateParam:SetIntData(self:GetPoints())
		GetServerSystem():GetSendStateTable("Map"):SetState(self:GetName() .. "_Points", self.stateParam)
	else
		GetClientSystem():GetReceiveStateTable("Map"):WatchState(self:GetName() .. "_Points", self.pointsUpdateSlot)
	end

end


function JumpTarget:UnInitIBase()

	self:UnInitSensor()

	if IsValid(GetServerSystem) then
		GetServerSystem():GetSendStateTable("Map"):RemoveState(self:GetName() .. "_Points")
	else
		self:UnInitParticles()
	end

end


function JumpTarget:InitSensor()

	self.sensor = BulletSensor()
	self.sensor:SetName(self.name .. "Sensor")
	local params = Parameters()
	params:AddParameter(Parameter("Shape", "Cube"))
	for index, param in ipairs(self.sensorParams) do
		params:AddParameter(param)
	end
	params:AddParameter(Parameter("Dimensions", self.dimensions))
	self.sensor:Init(params)
	self.sensor:GetSignal("StartCollision", true):Connect(self.objectEnterSlot)

end


function JumpTarget:UnInitSensor()

	self.sensor:UnInit()
	self.sensor = nil

end


function JumpTarget:InitParticles()

	self.scoreParticle = OGREParticleEffect()
	local particleParams = Parameters()
	particleParams:AddParameter(Parameter("ResourceName", tostring(self:GetPoints())))
	particleParams:AddParameter(Parameter("Loop", false))
	particleParams:AddParameter(Parameter("StartOnLoad", true))
	self.scoreParticle:SetName(self:GetName() .. "ParticleScore")
	self.scoreParticle:SetPosition(self.position)
	self.scoreParticle:SetOrientation(self.orientation)
	self.scoreParticle:Init(particleParams)

end


function JumpTarget:UnInitParticles()

	if IsValid(self.scoreParticle) then
		self.scoreParticle:UnInit()
		self.scoreParticle = nil
	end

end


function JumpTarget:ProcessParticles(frameTime)

	if IsValid(self.scoreParticle) then
		self.scoreParticle:Process(frameTime)
	end

end


function JumpTarget:NotifyPositionChange(setPos)

	self.position:Set(setPos)

	if IsValid(self.sensor) then
		self.sensor:SetPosition(setPos)
	end

	if IsValid(self.scoreParticle) then
		self.scoreParticle:SetPosition(self.position)
	end

end


function JumpTarget:NotifyOrientationChange(setOrien)

	self.orientation:Set(setOrien)

	if IsValid(self.sensor) then
		self.sensor:SetOrientation(setOrien)
	end

	if IsValid(self.scoreParticle) then
		self.scoreParticle:SetOrientation(self.orientation)
	end

end


function JumpTarget:NotifyScaleChange(setScale)

end


function JumpTarget:SetParameter(param)

	if param:GetName() == "Points" then
		self.points = param:GetIntData()
		self.basePoints = self.points
	elseif param:GetName() == "CubeWidth" then
		self.dimensions.x = param:GetFloatData()
	elseif param:GetName() == "CubeHeight" then
		self.dimensions.y = param:GetFloatData()
	elseif param:GetName() == "CubeDepth" then
		self.dimensions.z = param:GetFloatData()
	end

end


function JumpTarget:EnumerateParameters(params)

	params:AddParameter(Parameter("Points", Parameter.INT, self.points))
	for index, param in ipairs(self.sensorParams)
	do
		params:AddParameter(Parameter(param))
	end

end


function JumpTarget:Process(frameTime)

	self.sensor:Process(frameTime)

	if not IsValid(GetServerSystem) then
		self:ProcessParticles(frameTime)
	end

end


function JumpTarget:SetPoints(setPoints)

	if setPoints > 100 then
		setPoints = 100
	elseif setPoints <= 0 then
		error("setPoints is " .. tostring(setPoints) .. " in JumpTarget:SetPoints()")
	end

	--Safe to init the particle effect only after we have the points set
	if IsClient() and self.scoreParticle == nil then
		self:InitParticles()
	end

	self.points = setPoints

	--BRIAN TODO: HACK FOR NOW
	if IsValid(GetServerSystem) then
		--Update state
		self.stateParam:SetIntData(self:GetPoints())
		GetServerSystem():GetSendStateTable("Map"):SetState(self:GetName() .. "_Points", self.stateParam)
	end

end


function JumpTarget:GetPoints()

	return self.points

end


function JumpTarget:GetBasePoints()

	return self.basePoints

end


function JumpTarget:ObjectEnter(enterParams)

	local enterObjectID = enterParams:GetParameter("CollideObjectID", true):GetIntData()

	self.objectParams:GetOrCreateParameter("Points"):SetIntData(self.points)
	self.objectParams:GetOrCreateParameter("JumpTarget"):SetStringData(self:GetName())
	self.objectParams:GetOrCreateParameter("EnterObjectID"):SetIntData(enterObjectID)
	self.objectEnterSignal:Emit(self.objectParams)

end


function JumpTarget:UpdatePoints(pointsParams)

	self:SetPoints(pointsParams:GetParameter(0, true):GetIntData())
	if IsValid(self.scoreParticle) then
		self.scoreParticle:LoadEffect(tostring(self:GetPoints()))
	end

end

--JUMPTARGET CLASS END