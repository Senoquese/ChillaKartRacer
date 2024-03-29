
--SOCCERBALLSERVER CLASS START

class 'SoccerBallServer' (IBase)

function SoccerBallServer:__init() super()

	self.name = "DefaultSoccerBallName"
	self.ID = 0

	self.position = WVector3()
	self.orientation = WQuaternion()
	self.startPosition = WVector3()

	--Used in syncing
	self.syncDistance = 0.01
	self.lastPosition = WVector3()

	self.ballParams = Parameters()
	self.physicalBall = nil

end


function SoccerBallServer:Init()

	self.startPosition:Set(self.position)

	--Setup the signals we will need to emit over the network
	--Sync the position of the detached ice cube
	self.syncSignal = self:CreateSignal("SyncSoccerBall" .. tostring(self.ID), GetServerSystem(), false)
	self.syncParams = Parameters()

	self:InitPhysical()

end


function SoccerBallServer:UnInitImp()

	self:UnInitPhysical()

end


function SoccerBallServer:InitPhysical()

	--The physical entity
	self.physicalBall = BulletSphere()
	self.physicalBall:SetName(self.name)
	self.physicalBall:Init(self.ballParams)

end


function SoccerBallServer:UnInitPhysical()

	if IsValid(self.physicalBall) then
		self.physicalBall:UnInit()
		self.physicalBall = nil
	end

end


function SoccerBallServer:SetName(setName)

	self.name = setName

end


function SoccerBallServer:GetName()

	return self.name

end


function SoccerBallServer:Reset()

	if IsValid(self.physicalBall) then
		self.physicalBall:Reset()
	end

end


function SoccerBallServer:NotifyPositionChange(setPos)

	self.position:Set(setPos)

	if IsValid(self.physicalBall) then
		self.physicalBall:SetPosition(setPos)
	end

end


function SoccerBallServer:NotifyOrientationChange(setOrien)

	self.orientation:Set(setOrien)

	if IsValid(self.physicalBall) then
		self.physicalBall:SetOrientation(setOrien)
	end

end


function SoccerBallServer:NotifyScaleChange(setScale)

end


function SoccerBallServer:SetParameter(param)

	if param:GetName() == "ID" then
		self.ID = param:GetIntData()
	else
		self.ballParams:AddParameter(Parameter(param))
	end

end


function SoccerBallServer:EnumerateParameters(params)

	params:AddParameter(Parameter("ID", Parameter.INT, self.ID))
	local i = 0
	while i < self.ballParams:GetNumberOfParameters() do
		params:AddParameter(Parameter(self.ballParams:GetParameter(i)))
		i = i + 1
	end

end


function SoccerBallServer:Process()

	self:ProcessSync()

end


function SoccerBallServer:ProcessSync()

	--This is an optimization, don't send an update if the position is close enough
	if not self.lastPosition:Equals(self.physicalBall:GetPosition(), self.syncDistance) then
		--Set the last position to be the current position of the mine
		self.lastPosition:Set(self.physicalBall:GetPosition())
		--Emit the position of the physical mine
		self.syncParams:GetOrCreateParameter(0):SetFloatData(self.physicalBall:GetPosition().x)
		self.syncParams:GetOrCreateParameter(1):SetFloatData(self.physicalBall:GetPosition().y)
		self.syncParams:GetOrCreateParameter(2):SetFloatData(self.physicalBall:GetPosition().z)
		self.syncParams:GetOrCreateParameter(3):SetFloatData(self.physicalBall:GetOrientation().w)
		self.syncParams:GetOrCreateParameter(4):SetFloatData(self.physicalBall:GetOrientation().x)
		self.syncParams:GetOrCreateParameter(5):SetFloatData(self.physicalBall:GetOrientation().y)
		self.syncParams:GetOrCreateParameter(6):SetFloatData(self.physicalBall:GetOrientation().z)
		self.syncSignal:Emit(self.syncParams)
	end

end

--SOCCERBALLSERVER CLASS END