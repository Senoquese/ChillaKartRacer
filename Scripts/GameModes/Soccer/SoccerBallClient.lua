
--SOCCERBALLCLIENT CLASS START

class 'SoccerBallClient' (IBase)

function SoccerBallClient:__init() super()

	self.name = "DefaultSoccerBallName"
	self.ID = 0

	self.position = WVector3()
	self.orientation = WQuaternion()

	self.extrapolator = TransformExtrapolator(10)

	self.ballParams = Parameters()
	self.graphicalBall = nil

end


function SoccerBallClient:Init()

	--Setup the slots we will need to receive events over the network
	self.syncSlot = self:CreateSlot("SyncSoccerBall" .. tostring(self.ID), "Sync", GetClientSystem())

	self:InitGraphical()

end


function SoccerBallClient:UnInitImp()

	self:UnInitGraphical()

end


function SoccerBallClient:InitGraphical()

	--The graphical entity
	self.graphicalBall = OGREModel()
	self.graphicalBall:SetName(self.name)
	self.graphicalBall:Init(self.ballParams)

end


function SoccerBallClient:UnInitGraphical()

	if IsValid(self.graphicalBall) then
		self.graphicalBall:UnInit()
		self.graphicalBall = nil
	end

end


function SoccerBallClient:SetName(setName)

	self.name = setName

end


function SoccerBallClient:GetName()

	return self.name

end


function SoccerBallClient:NotifyPositionChange(setPos)

	self.position:Set(setPos)

	if IsValid(self.graphicalBall) then
		self.graphicalBall:SetPosition(setPos)
	end

end


function SoccerBallClient:NotifyOrientationChange(setOrien)

	self.orientation:Set(setOrien)

	if IsValid(self.graphicalBall) then
		self.graphicalBall:SetOrientation(setOrien)
	end

end


function SoccerBallClient:NotifyScaleChange(setScale)

end


function SoccerBallClient:SetParameter(param)

	if param:GetName() == "ID" then
		self.ID = param:GetIntData()
	else
		self.ballParams:AddParameter(Parameter(param))
	end

end


function SoccerBallClient:EnumerateParameters(params)

	params:AddParameter(Parameter("ID", Parameter.INT, self.ID))
	local i = 0
	while i < self.ballParams:GetNumberOfParameters() do
		params:AddParameter(Parameter(self.ballParams:GetParameter(i)))
		i = i + 1
	end

end


function SoccerBallClient:Process()

	local pos = self.extrapolator:ReadPositionSample(GetClientSystem():GetTime())
	local orien = self.extrapolator:ReadOrientationSample(GetClientSystem():GetTime(), self.graphicalBall:GetOrientation())
	self.graphicalBall:SetPosition(pos)
	self.graphicalBall:SetOrientation(orien)

end


function SoccerBallClient:Sync(syncParams)

	if IsValid(self.graphicalBall) then
		local x = syncParams:GetParameterAtIndex(0, true):GetFloatData()
		local y = syncParams:GetParameterAtIndex(1, true):GetFloatData()
		local z = syncParams:GetParameterAtIndex(2, true):GetFloatData()
		local newPos = WVector3(x, y, z)
		local qw = syncParams:GetParameterAtIndex(3, true):GetFloatData()
		local qx = syncParams:GetParameterAtIndex(4, true):GetFloatData()
		local qy = syncParams:GetParameterAtIndex(5, true):GetFloatData()
		local qz = syncParams:GetParameterAtIndex(6, true):GetFloatData()
		local newOrien = WQuaternion(qw, qx, qy, qz)

		local packetSentTime = GetClientSystem():GetTime() - (GetClientSystem():GetServerPing() / 2)

		self.extrapolator:AddSample(packetSentTime, GetClientSystem():GetTime(), newPos, newOrien)
	end

end

--SOCCERBALLCLIENT CLASS END