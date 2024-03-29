UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERFREEMOVEVEL CLASS START

class 'CamControllerFreeMoveVel' (ICamController)

function CamControllerFreeMoveVel:__init(setCamera) super()

	self.camera = setCamera
	self.enabled = true

	self.rotVelX = 0
	self.rotVelY = 0
	self.rotVelXLimit = 0.5
	self.rotVelYLimit = 0.5
	self.moveVel = WVector3()
	self.moveSlowLimit = 0.15
	self.moveFastLimit = 0.4
	self.moveLimit = self.moveSlowLimit

	self.moveLeft = false
	self.moveRight = false
	self.moveForward = false
	self.moveBack = false
	self.moveSpeedSlow = 0.3
	self.moveSpeedFast = 0.5
	self.moveSpeed = self.moveSpeedSlow
	self.rotateSpeed = 0.01
	self.moveSlowDown = 0.15
	self.rotateSlowDown = 0.2
	--This is the amount that gets multiplied by the speed
	--and then added to the rotate velocity limits
	self.rotateSpeedMod = 0.3

	self.mouseMovedSlot = self:CreateSlot("MouseMoved", "MouseMoved")
	GetClientInputManager():GetSignal("MouseMoved", true):Connect(self.mouseMovedSlot)
	self.keyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	GetClientInputManager():GetSignal("KeyPressed", true):Connect(self.keyPressedSlot)
	self.keyReleasedSlot = self:CreateSlot("KeyReleased", "KeyReleased")
	GetClientInputManager():GetSignal("KeyReleased", true):Connect(self.keyReleasedSlot)

end


function CamControllerFreeMoveVel:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamControllerFreeMoveVel:GetEnabled()

	return self.enabled

end


function CamControllerFreeMoveVel:ProcessCamController(frameTime)

	if self.enabled then
		local moveScale = self.moveSpeed * frameTime

		if self.moveLeft then
			self.moveVel.x = self.moveVel.x + -moveScale
		end
		if self.moveRight then
			self.moveVel.x = self.moveVel.x + moveScale
		end
		self.moveVel.x = Clamp(self.moveVel.x, -self.moveLimit, self.moveLimit)

		if self.moveForward then
			self.moveVel.z = self.moveVel.z + -moveScale
		end
		if self.moveBack then
			self.moveVel.z = self.moveVel.z + moveScale
		end
		self.moveVel.z = Clamp(self.moveVel.z, -self.moveLimit, self.moveLimit)

		self.camera:MoveRelative(self.moveVel)
		self.camera:Yaw(DegreeToRadian(self.rotVelX), true)
		self.camera:Pitch(DegreeToRadian(self.rotVelY))

		self.moveVel.x = ToZero(self.moveVel.x, self.moveSlowDown * timeDiff)
		self.moveVel.z = ToZero(self.moveVel.z, self.moveSlowDown * timeDiff)
		self.rotVelX = ToZero(self.rotVelX, self.rotateSlowDown * timeDiff)
		self.rotVelY = ToZero(self.rotVelY, self.rotateSlowDown * timeDiff)
	end

end


function CamControllerFreeMoveVel:NotifyActive()

end


function CamControllerFreeMoveVel:MouseMoved(mouseParams)

	self.rotVelX = self.rotVelX + -(mouseParams:GetParameter("MouseXRelative", true):GetIntData() * self.rotateSpeed)
	self.rotVelY = self.rotVelY + -(mouseParams:GetParameter("MouseYRelative", true):GetIntData() * self.rotateSpeed)
	local currentSpeed = self.moveVel:Length()
	local maxSpeed = WVector3(self.moveLimit, 0, self.moveLimit):Length()
	local addLimit = (currentSpeed / maxSpeed) * self.rotateSpeedMod
	self.rotVelX = Clamp(self.rotVelX, -(self.rotVelXLimit + addLimit), self.rotVelXLimit + addLimit)
	self.rotVelY = Clamp(self.rotVelY, -(self.rotVelYLimit + addLimit), self.rotVelYLimit + addLimit)

end


function CamControllerFreeMoveVel:KeyPressed(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()
	if key == StringToKeyCode("RSHIFT") then
		self.moveSpeed = self.moveSpeedFast
		self.moveLimit = self.moveFastLimit
	elseif key == StringToKeyCode("J") then
		self.moveLeft = true
	elseif key == StringToKeyCode("L") then
		self.moveRight = true
	elseif key == StringToKeyCode("I") then
		self.moveForward = true
	elseif key == StringToKeyCode("K") then
		self.moveBack = true
	end

end


function CamControllerFreeMoveVel:KeyReleased(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()
	if key == StringToKeyCode("RSHIFT") then
		self.moveSpeed = self.moveSpeedSlow
		self.moveLimit = self.moveSlowLimit
	elseif key == StringToKeyCode("J") then
		self.moveLeft = false
	elseif key == StringToKeyCode("L") then
		self.moveRight = false
	elseif key == StringToKeyCode("I") then
		self.moveForward = false
	elseif key == StringToKeyCode("K") then
		self.moveBack = false
	end

end

--CAMCONTROLLERFREEMOVEVEL CLASS END