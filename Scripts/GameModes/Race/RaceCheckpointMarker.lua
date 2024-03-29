UseModule("IBase", "Scripts/")

--RACECHECKPOINTMARKER CLASS START

--RaceCheckpointMarker is a display for checkpoints.
--The next checkpoint the player is supposed to cross is marked by these.
--When a player crosses a checkpoint, it switches from On to Off.
--BRIAN TODO: Make an IScriptObject
class 'RaceCheckpointMarker' (IBase)

function RaceCheckpointMarker:__init() super()

	self.name = "DefaultRaceCheckpointMarkerName"

	self.markerPos = WVector3()
	self.markerOrien = WQuaternion()
	self.checkpointIndex = 0
	self.isOn = false

end


function RaceCheckpointMarker:BuildInterfaceDefIBase()

	self:AddClassDef("RaceCheckpointMarker", "IBase", "Defines and manages a visual checkpoint marker")

end


function RaceCheckpointMarker:SetName(setName)

	self.name = setName

end


function RaceCheckpointMarker:GetName()

	return self.name

end


function RaceCheckpointMarker:InitIBase()

	self:InitGraphical()

end


function RaceCheckpointMarker:InitGraphical()

	self.off = OGREModel()
	local params = Parameters()
	params:GetOrCreateParameter("RenderMeshName"):SetStringData("checkpoint_off.mesh")
	params:GetOrCreateParameter("PositionX"):SetFloatData(self.markerPos.x)
	params:GetOrCreateParameter("PositionY"):SetFloatData(self.markerPos.y)
	params:GetOrCreateParameter("PositionZ"):SetFloatData(self.markerPos.z)
	params:GetOrCreateParameter("OrientationW"):SetFloatData(self.markerOrien.w)
	params:GetOrCreateParameter("OrientationX"):SetFloatData(self.markerOrien.x)
	params:GetOrCreateParameter("OrientationY"):SetFloatData(self.markerOrien.y)
	params:GetOrCreateParameter("OrientationZ"):SetFloatData(self.markerOrien.z)
	self.off:SetName("markerOff")
	self.off:Init(params)
	self.off:SetCastShadows(true)
	self.off:SetReceiveShadows(false)
	self.off:SetVisible(true)

	self.on = OGREModel()
	params:GetOrCreateParameter("RenderMeshName"):SetStringData("checkpoint_on.mesh")
	self.on:SetName("markerOn")
	self.on:Init(params)
	self.on:SetCastShadows(true)
	self.on:SetReceiveShadows(false)
	self.on:SetVisible(false)
	self.onAnim = self.on:GetAnimation("idle", true)

end


function RaceCheckpointMarker:UnInitIBase()

	if IsValid(self.off) then
		self.off:UnInit()
		self.off = nil
	end

	self.onAnim = nil

	if IsValid(self.on) then
		self.on:UnInit()
		self.on = nil
	end

end


function RaceCheckpointMarker:NotifyPositionChange(setPos)

	self.markerPos.x = setPos.x
	self.markerPos.y = setPos.y
	self.markerPos.z = setPos.z

end


function RaceCheckpointMarker:NotifyOrientationChange(setOrien)

	self.markerOrien.w = setOrien.w
	self.markerOrien.x = setOrien.x
	self.markerOrien.y = setOrien.y
	self.markerOrien.z = setOrien.z

end


function RaceCheckpointMarker:NotifyScaleChange(setScale)

end


function RaceCheckpointMarker:SetParameter(param)

	if param:GetName() == "CheckpointIndex" then
		self.checkpointIndex = param:GetIntData()
	end

end


function RaceCheckpointMarker:EnumerateParameters(params)

	params:AddParameter(Parameter("CheckpointIndex", Parameter.INT, self.checkpointIndex))

end


function RaceCheckpointMarker:Process(frameTime)

	self.off:Process(frameTime)
	self.on:Process(frameTime)
	if self.on:GetVisible() then
		self.onAnim:Process(frameTime)
	end

end


function RaceCheckpointMarker:GetCheckpointIndex()

	return self.checkpointIndex

end


function RaceCheckpointMarker:TurnOn()

	self.isOn = true
	self.off:SetVisible(false)
	self.on:SetVisible(true)
	--SetTimePosition(0) basically reset the animation
	self.onAnim:SetTimePosition(0)
	self.onAnim:Play()

end


function RaceCheckpointMarker:TurnOff()

	self.isOn = false
	self.off:SetVisible(true)
	self.on:SetVisible(false)
	self.onAnim:Stop()

end


function RaceCheckpointMarker:GetOn()

	return self.isOn

end

--RACECHECKPOINTMARKER CLASS END