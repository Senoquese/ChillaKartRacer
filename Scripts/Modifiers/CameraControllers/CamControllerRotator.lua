UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERROTATOR CLASS START

class 'CamControllerRotator' (ICamController)

function CamControllerRotator:__init(object, setCamera, minLimit, maxLimit, rotateXMinLimit, rotateXMaxLimit) super()

	self.object = object
	self.camera = setCamera
	self.radiusMinLimit = minLimit
	self.radiusMaxLimit = maxLimit
	self.rotateXMinLimit = rotateXMinLimit
	self.rotateXMaxLimit = rotateXMaxLimit

	--The zoom can be enabled even if the rotator is disabled
	self.zoomEnabled = false

	self.mouseXRel = 0
	self.mouseYRel = 0
	self.mouseZRel = 0
	self.velX = 0
	self.velXLimit = 20
	self.velY = 0
	self.velYLimit = 20
	self.velZ = 0
	self.velZLimit = 30
	self.slowDownSpeed = 75
	self.radius = 4
	self.theta = PI / 4
	self.phi = PI / 2.5
	self.mouseRelScale = 0.1
	self.rotSpeed = 0.5
	self.zoomSpeed = 0.5
	self.newPosition = WVector3()

	self.mouseMovedSlot = self:CreateSlot("MouseMoved", "MouseMoved")
	GetClientInputManager():GetSignal("MouseMoved", true):Connect(self.mouseMovedSlot)

end


function CamControllerRotator:SetZoomEnabled(setEnabled)

	self.zoomEnabled = setEnabled

end


function CamControllerRotator:GetZoomEnabled()

	return self.zoomEnabled

end


function CamControllerRotator:SetFollowObjectImp(followObject)

	self.object = followObject

end


function CamControllerRotator:ProcessCamController(frameTime)

	if (not self.zoomEnabled) or (self.zoomEnabled and IsValid(self.object)) then
		self:UpdateCamera(frameTime, self.mouseXRel, self.mouseYRel, self.mouseZRel)

		local objPos
		if IsValid(self.object.GetGraphicalPosition) then
			objPos = self.object:GetGraphicalPosition()
		else
			objPos = self.object:GetPosition()
		end
		local setPos = self.newPosition + objPos
		self.camera:SetPosition(setPos)
		self.camera:GetLookAt():SetPosition(objPos)

		--Reset values
		self.mouseXRel = 0
		self.mouseYRel = 0
		self.mouseZRel = 0
	end

end


function CamControllerRotator:NotifyActive()

end


function CamControllerRotator:MouseMoved(mouseParams)

	--Zoom can be enabled even if the other mouse movement isn't
	if self.zoomEnabled then
		self.mouseZRel = mouseParams:GetParameter("MouseZRelative", true):GetIntData() * self.mouseRelScale
	end
	if self:GetEnabled() then
		self.mouseXRel = mouseParams:GetParameter("MouseXRelative", true):GetIntData() * self.mouseRelScale
		self.mouseYRel = mouseParams:GetParameter("MouseYRelative", true):GetIntData() * self.mouseRelScale
	end

end


function CamControllerRotator:UpdateCamera(frameTime, mouseXRel, mouseYRel, mouseZRel)

	self.velX = self.velX + mouseXRel
	self.velY = self.velY - mouseYRel
	self.velZ = self.velZ + mouseZRel

	self.radius = self.radius - (self.zoomSpeed * (self.velZ * frameTime))
	if self.radius < self.radiusMinLimit then
		self.radius = self.radiusMinLimit
		--Velocity stops when we have hit the min limit
		self.velZ = 0
	end
	if self.radius > self.radiusMaxLimit then
		self.radius = self.radiusMaxLimit
		--Velocity stops when we have hit the max limit
		self.velZ = 0
	end

	self.theta = self.theta + (self.rotSpeed * (self.velX * frameTime))

	self.phi = self.phi + (self.rotSpeed * (self.velY * frameTime))

	if self.phi > self.rotateXMaxLimit then
		self.phi = self.rotateXMaxLimit
	elseif self.phi < self.rotateXMinLimit then
		self.phi = self.rotateXMinLimit
	end

	self.newPosition.x = self.radius * COS(self.theta) * SIN(self.phi)
	self.newPosition.y = self.radius * COS(self.phi)
	self.newPosition.z = self.radius * SIN(self.theta) * SIN(self.phi)

	--Try to bring the velocities back to 0
	self.velX = self:SlowDown(self.velX, self.velXLimit, frameTime)
	self.velY = self:SlowDown(self.velY, self.velYLimit, frameTime)
	self.velZ = self:SlowDown(self.velZ, self.velZLimit, frameTime)

end


function CamControllerRotator:SlowDown(velocity, velocityLimit, frameTime)

	--Check limit
	if velocity > velocityLimit then
		velocity = velocityLimit
	elseif velocity < -velocityLimit then
		velocity = -velocityLimit
	end

	--Slow the velocity down
	if velocity > 0 then
		velocity = velocity - (self.slowDownSpeed * frameTime)
		if velocity < 0 then
			velocity = 0
		end
	elseif velocity < 0 then
		velocity = velocity + (self.slowDownSpeed * frameTime)
		if velocity > 0 then
			velocity = 0
		end
	end

	return velocity

end

--CAMCONTROLLERROTATOR CLASS END