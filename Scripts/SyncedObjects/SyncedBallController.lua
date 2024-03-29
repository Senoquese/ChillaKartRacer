--SyncedBallController is a player controller
UseModule("IController", "Scripts/")
UseModule("SyncedBall", "Scripts/SyncedObjects")

--SYNCEDBALLCONTROLLER CLASS START

--SyncedBallController is a wrapper around SyncedBall
class 'SyncedBallController' (IController)

function SyncedBallController:__init() super()

	self.controlForward = false
	self.controlBack = false
	self.controlRight = false
	self.controlLeft = false

	self.mass = 200
	self.forceAmount = 8000
	self.maxSpeed = 50

	self.camController = nil

	self.syncedBall = SyncedBall()

	self.predictionCompleteSlot = self:CreateSlot("PredictionComplete", "PredictionComplete")

end


function SyncedBallController:ActivateCamController()

	--Character camera controllers are always priority 1
	GetCameraManager():AddController(self.camController, 1)

end


function SyncedBallController:DeactivateCamController()

	--BRIAN TODO: Test code only
	print("SyncedBallController:DeactivateCamController() called")

	GetCameraManager():RemoveController(self.camController)

end


function SyncedBallController:InitController()

	self.syncedBall:SetParameter(Parameter("Mass", self.mass))
	self.syncedBall:SetParameter(Parameter("Friction", 0.8))
	self.syncedBall:SetParameter(Parameter("Restitution", 0.7))
	self.syncedBall:SetParameter(Parameter("AngularDamping", 0.10))
	self.syncedBall:SetParameter(Parameter("LinearDamping", 0.10))
	self.syncedBall:SetParameter(Parameter("CastShadows", true))
	self.syncedBall:SetParameter(Parameter("ReceiveShadows", false))
	self.syncedBall:SetParameter(Parameter("RenderMeshName", "soccer_ball.mesh"))
	self.syncedBall:SetPosition(self:GetPosition())
	self.syncedBall:SetOrientation(self:GetOrientation())
	self.syncedBall:Init()

	print("FUCK: " .. tostring(self.syncedBall:GetPosition()))

	if IsClient() then
		self.camController = CamControllerRotator(self, GetCamera(), 0.5, 500, 0.348, 2.79)
		self.camController:Init()
	end

end


function SyncedBallController:UnInitController()

	self.syncedBall:UnInit()

	if IsClient() then
		if IsValid(self.camController) then
			self.camController:UnInit()
			self.camController = nil
		end
	end

end


function SyncedBallController:SetControllerEnabled(setEnabled)

end


function SyncedBallController:SetInWorldImp(inWorld)

	self.syncedBall:SetInWorld(inWorld)

end


function SyncedBallController:SetEnableControlsImp(enable)

end


function SyncedBallController:SetBoostEnabledImp(setEnabled)

end


function SyncedBallController:DoesOwn(ownObjectID)

	return self.syncedBall:DoesOwn(ownObjectID)

end


function SyncedBallController:Reset()

	self.syncedBall:Reset()

end


function SyncedBallController:NotifyControllerPositionChange(setPos)

	self.syncedBall:NotifyScriptObjectPositionChange(setPos)

end


function SyncedBallController:NotifyControllerOrientationChange(setOrien)

	self.syncedBall:NotifyScriptObjectOrientationChange(setOrien)

end


function SyncedBallController:NotifyRespawnedImp(respawnPos, respawnOrien)

end


function SyncedBallController:GetGraphicalPosition()

	return self.syncedBall:GetGraphicalPosition()

end


function SyncedBallController:GetGraphicalOrientation()

	return self.syncedBall:GetGraphicalOrientation()

end


function SyncedBallController:GetControllerUpNormal()

	return self.syncedBall:GetUpNormal()

end


function SyncedBallController:GetControllerLinearVelocity()

	return self.syncedBall:GetLinearVelocity()

end


function SyncedBallController:GetControllerSpeedPercent()

	local speed = self.syncedBall:GetLinearVelocity():Length()
	--print("Speed = " .. tostring(speed))
	return speed / self.maxSpeed

end


function SyncedBallController:GetControllerActive()

	return self.syncedBall:GetSyncedActive()

end


function SyncedBallController:SetControllerStateData(stateBuiltTime, setState)

	self.syncedBall:SetStateData(stateBuiltTime, setState)

end


function SyncedBallController:GetControllerStateData(returnState)

	self.syncedBall:GetStateData(returnState)

end


function SyncedBallController:KeyEvent(keyID, pressed, extraData)

	if self:GetEnableControls() then
		local inputName = GetNetworkedWorld():GetInputName(keyID)
		if inputName == "ControlAccel" then
			self.controlForward = pressed
		elseif inputName == "ControlReverse" then
			self.controlBack = pressed
		elseif inputName == "ControlRight" then
			self.controlRight = pressed
		elseif inputName == "ControlLeft" then
			self.controlLeft = pressed
		elseif inputName == "ControlReset" then
			
		elseif inputName == "ControlMouseLook" then
			
		elseif inputName == "ControlBoost" then
			if (pressed) then
				self.syncedBall:SetSynced(not self.syncedBall:GetSynced())
			end
		elseif inputName == "Hop" then
			
		end
	end

end


function SyncedBallController:SetParameter(param)

	self.syncedBall:SetParameter(param)

end


function SyncedBallController:EnumerateParameters(params)

	self.syncedBall:EnumerateParameters(params)

end


function SyncedBallController:ProcessController(frameTime)

	--BRIAN TODO: The project to plane method
	--pushVector = cameraPos - ((cameraPos - pointBallTouchesSurface) dot surfaceNormal) * surfaceNormal

	local dt = GetTimeDifference()

	if self:GetOwnerID() == 0 then
		--The owner may not be assigned yet
		return
	end

	local camPos = GetNetworkSystem():GetClientState(self:GetOwnerID()):GetCameraState(GetNetworkSystem():GetTime())

	--Change the impulse based on the current speed to reach but not exceed the max speed
	local speedPercent = self:GetControllerSpeedPercent()
	if speedPercent > 1 then
		speedPercent = 1
	end
	speedPercent = 1 - speedPercent
	if self.controlForward then
		local forward = self.syncedBall:GetPosition() - camPos
		forward:Normalise()
		local impulse = forward * self.forceAmount * speedPercent * dt
		self.syncedBall:ApplyWorldImpulse(impulse, WVector3())
		local impLen = impulse:Length()
		impulse:Normalise()
		--[[print("")
		print("Applied impulse dir: " .. tostring(impulse))
		print("Impulse len: " .. tostring(impLen))
		print("Impulse pos: " .. tostring(self.syncedBall:GetPosition()))
		print("Impulse time: " .. tostring(GetNetworkSystem():GetTime()))--]]
	end
	if self.controlBack then
		local forward = self.syncedBall:GetPosition() - camPos
		forward:Normalise()
		forward:Negate()
		self.syncedBall:ApplyWorldImpulse(forward * self.forceAmount * speedPercent * dt, WVector3())
	end
	if self.controlRight then
		local side = self.syncedBall:GetPosition() - camPos
		side:Normalise()
		side = side:CrossProduct(self.syncedBall:GetUpNormal())
		self.syncedBall:ApplyWorldImpulse(side * self.forceAmount * speedPercent * dt, WVector3())
	end
	if self.controlLeft then
		local side = self.syncedBall:GetPosition() - camPos
		side:Normalise()
		side = side:CrossProduct(self.syncedBall:GetUpNormal())
		side:Negate()
		self.syncedBall:ApplyWorldImpulse(side * self.forceAmount * speedPercent * dt, WVector3())
	end

	self.syncedBall:ProcessScriptObject(frameTime)

	--Update the ScriptObject every process
	self:SetPosition(self.syncedBall:GetPosition(), false)
	self:SetOrientation(self.syncedBall:GetOrientation(), false)

end


function SyncedBallController:PredictionComplete(params)

	self.syncedBall:PredictionComplete(params)

end

--SYNCEDBALLCONTROLLER CLASS END