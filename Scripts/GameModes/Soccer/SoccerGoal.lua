UseModule("IBase", "Scripts/")

--SOCCERGOAL CLASS START

--SoccerGoal is an sensor that emits a signal when a special "ball" object collides with it.
--BRIAN TODO: Make an IScriptObject
--BRIAN TODO: Is this needed? Sensor emits signal to sound, particle effect, and a way to score, same with jump targets
class 'SoccerGoal' (IBase)

function SoccerGoal:__init() super()

	self.name = "DefaultSoccerGoalName"
	self.teamID = "DefaultTeamID"
	self.goalID = 0
	self.position = WVector3()
	self.orientation = WQuaternion()

	--BRIAN TODO: Hack for now
	if IsClient() then
		self.celebrationPoint1 = WVector3()
		self.celebrationPoint2 = WVector3()
		self.celebrationEffect1 = ""
		self.celebrationEffect2 = ""

		self.soccerGoalScoredSlot = self:CreateSlot("SoccerGoalScored", "SoccerGoalScored", GetClientSystem())
	end

	self.sensorParams = { }
	self.dimensions = WVector3()

	self.objectEnterSlot = self:CreateSlot("ObjectEnter", "ObjectEnter")
	self.objectEnterSignal = self:CreateSignal("ObjectEnterSoccerGoal")
	self.objectParams = Parameters()

end


function SoccerGoal:BuildInterfaceDefIBase()

	self:AddClassDef("SoccerGoal", "IBase", "Defines a soccer goal")

end


function SoccerGoal:SetName(setName)

	self.name = setName

end


function SoccerGoal:GetName()

	return self.name

end


function SoccerGoal:GetTeamID()

	return self.teamID

end


function SoccerGoal:GetGoalID()

	return self.goalID

end


function SoccerGoal:InitIBase()

	if IsServer() then
		self:InitSensor()
	end

end


function SoccerGoal:UnInitIBase()

	if IsServer() then
		self:UnInitSensor()
	end

end


function SoccerGoal:InitSensor()

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


function SoccerGoal:UnInitSensor()

	self.sensor:UnInit()
	self.sensor = nil

end


function SoccerGoal:GetPosition()

	return self.position

end


function SoccerGoal:NotifyPositionChange(setPos)

	self.position:Set(setPos)

	if IsValid(self.sensor) then
		self.sensor:SetPosition(setPos)
	end

end


function SoccerGoal:NotifyOrientationChange(setOrien)

	self.orientation:Set(setOrien)

	if IsValid(self.sensor) then
		self.sensor:SetOrientation(setOrien)
	end

end


function SoccerGoal:NotifyScaleChange(setScale)

end


function SoccerGoal:SetParameter(param)

	if param:GetName() == "TeamID" then
		self.teamID = param:GetStringData()
	elseif param:GetName() == "GoalID" then
		self.goalID = param:GetIntData()
	elseif param:GetName() == "CubeWidth" then
		self.dimensions.x = param:GetFloatData()
	elseif param:GetName() == "CubeHeight" then
		self.dimensions.y = param:GetFloatData()
	elseif param:GetName() == "CubeDepth" then
		self.dimensions.z = param:GetFloatData()
	elseif IsClient() then
		if param:GetName() == "CelebrationPoint1X" then
			self.celebrationPoint1.x = param:GetFloatData()
		elseif param:GetName() == "CelebrationPoint1Y" then
			self.celebrationPoint1.y = param:GetFloatData()
		elseif param:GetName() == "CelebrationPoint1Z" then
			self.celebrationPoint1.z = param:GetFloatData()
		elseif param:GetName() == "CelebrationPoint2X" then
			self.celebrationPoint2.x = param:GetFloatData()
		elseif param:GetName() == "CelebrationPoint2Y" then
			self.celebrationPoint2.y = param:GetFloatData()
		elseif param:GetName() == "CelebrationPoint2Z" then
			self.celebrationPoint2.z = param:GetFloatData()
		elseif param:GetName() == "CelebrationEffect1" then
			self.celebrationEffect1 = param:GetStringData()
		elseif param:GetName() == "CelebrationEffect2" then
			self.celebrationEffect2 = param:GetStringData()
		end
	end

end


function SoccerGoal:EnumerateParameters(params)

	params:AddParameter(Parameter("TeamID", self.teamID))
	params:AddParameter(Parameter("GoalID", Parameter.INT, self.goalID))
	if IsClient() then
		params:AddParameter(Parameter("CelebrationPoint1X", self.celebrationPoint1.x))
		params:AddParameter(Parameter("CelebrationPoint1Y", self.celebrationPoint1.y))
		params:AddParameter(Parameter("CelebrationPoint1Z", self.celebrationPoint1.z))
		params:AddParameter(Parameter("CelebrationPoint2X", self.celebrationPoint2.x))
		params:AddParameter(Parameter("CelebrationPoint2Y", self.celebrationPoint2.y))
		params:AddParameter(Parameter("CelebrationPoint2Z", self.celebrationPoint2.z))
		params:AddParameter(Parameter("CelebrationEffect1", self.celebrationEffect1))
		params:AddParameter(Parameter("CelebrationEffect2", self.celebrationEffect2))
	end
	for index, param in ipairs(self.sensorParams)
	do
		params:AddParameter(Parameter(param))
	end

end


function SoccerGoal:Process(frameTime)

	if IsValid(self.sensor) then
		self.sensor:Process(frameTime)
	end

end


function SoccerGoal:ObjectEnter(enterParams)

	local enterObjectID = enterParams:GetParameter("CollideObjectID", true):GetIntData()
	self.objectParams:GetOrCreateParameter("SoccerGoal"):SetStringData(self:GetName())
	self.objectParams:GetOrCreateParameter("EnterObjectID"):SetIntData(enterObjectID)
	self.objectEnterSignal:Emit(self.objectParams)

end


function SoccerGoal:SoccerGoalScored(goalParams)

	local teamID = goalParams:GetParameter("TeamID", true):GetStringData()
	local goalID = goalParams:GetParameter("GoalID", true):GetIntData()

	--Check if this is for this goal
	if goalID == self.goalID then
		GetParticleSystem():AddEffect(self.celebrationEffect1, self.celebrationPoint1)
		GetParticleSystem():AddEffect(self.celebrationEffect2, self.celebrationPoint2)
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/AMB_Goal.wav", WVector3(), 0.6, 10, false, SoundSystem.HIGH)
	end

end

--SOCCERGOAL CLASS END