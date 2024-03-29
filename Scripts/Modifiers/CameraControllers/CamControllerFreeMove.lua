UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERFREEMOVE CLASS START

class 'CamControllerFreeMove' (ICamController)

function CamControllerFreeMove:__init(setCamera) super()

	self.camera = setCamera
	self.enabled = true

	self.forcePos = { false, nil }
	self.forceLookAt = { false, nil }

	self.rotX = 0
	self.rotY = 0
	self.translateVector = WVector3()
	self.moveLeft = false
	self.moveRight = false
	self.moveForward = false
	self.moveBack = false
	self.moveScale = 0
	self.moveSpeedSlow = 2
	self.moveSpeedFast = 20
	self.moveSpeed = self.moveSpeedSlow
	self.rotateSpeed = 0.1

	self:ResetCamValues()

	self.mouseMovedSlot = self:CreateSlot("MouseMoved", "MouseMoved")
	GetClientInputManager():GetSignal("MouseMoved", true):Connect(self.mouseMovedSlot)
	self.keyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	GetClientInputManager():GetSignal("KeyPressed", true):Connect(self.keyPressedSlot)
	self.keyReleasedSlot = self:CreateSlot("KeyReleased", "KeyReleased")
	GetClientInputManager():GetSignal("KeyReleased", true):Connect(self.keyReleasedSlot)

end


function CamControllerFreeMove:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamControllerFreeMove:GetEnabled()

	return self.enabled

end


function CamControllerFreeMove:SetFollowObjectImp(setFollowObj)

end


function CamControllerFreeMove:ProcessCamController(frameTime)

	if self.enabled then
		self.moveScale = self.moveSpeed * frameTime

		if self.moveLeft then
			self.translateVector.x = -self.moveScale
		end

		if self.moveRight then
			self.translateVector.x = self.moveScale
		end

		if self.moveForward then
			self.translateVector.z = -self.moveScale
		end

		if self.moveBack then
			self.translateVector.z = self.moveScale
		end

		--local hitWorld = self:RayTest(self.camera:GetPosition(), self.camera:GetPosition() + self.translateVector)
		--if IsValid(hitWorld) then
		--	local newTrans = self.camera:GetPosition() - hitWorld
		--	self.translateVector = newTrans
		--end

		self.camera:Yaw(DegreeToRadian(self.rotX), true)
		self.camera:Pitch(DegreeToRadian(self.rotY))
		self.camera:MoveRelative(self.translateVector)
		self:ResetMovementValues()

		if self.forcePos[1] then
			self.camera:SetPosition(self.forcePos[2])
			self.forcePos[1] = false
		end
		if self.forceLookAt[1] then
			self.camera:GetLookAt():SetPosition(self.forceLookAt[2])
			self.forceLookAt[1] = false
		end
	end

end


function CamControllerFreeMove:NotifyActive()

end


function CamControllerFreeMove:RayTest(startPos, endPos)

	local rayResult = GetBulletPhysicsSystem():RayCast(startPos, endPos)
	if IsValid(rayResult) and IsValid(rayResult:GetHitObject()) then
		return rayResult:GetHitPointWorld()
	end
	return nil

end


function CamControllerFreeMove:ResetCamValues()

	self:ResetMovementValues()

end


function CamControllerFreeMove:ResetMovementValues()

	self.rotX = 0
	self.rotY = 0
	self.translateVector.x = 0
	self.translateVector.y = 0
	self.translateVector.z = 0

end


function CamControllerFreeMove:SetForcePosition(setPos)

	self.forcePos = { true, setPos }
	self:ResetCamValues()

end


function CamControllerFreeMove:SetForceLookAt(setPos)

	self.forceLookAt = { true, setPos }
	self:ResetCamValues()

end


function CamControllerFreeMove:MouseMoved(mouseParams)

	if not self.forceLookAt.first then
		self.rotX = self.rotX + -(mouseParams:GetParameter("MouseXRelative", true):GetIntData() * self.rotateSpeed)
		self.rotY = self.rotY + -(mouseParams:GetParameter("MouseYRelative", true):GetIntData() * self.rotateSpeed)
	end

end


function CamControllerFreeMove:KeyPressed(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()
	if key == StringToKeyCode("RSHIFT") then
		self.moveSpeed = self.moveSpeedFast
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


function CamControllerFreeMove:KeyReleased(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()
	if key == StringToKeyCode("RSHIFT") then
		self.moveSpeed = self.moveSpeedSlow
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

--CAMCONTROLLERFREEMOVE CLASS END