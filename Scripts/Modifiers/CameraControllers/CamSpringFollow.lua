UseModule("ScriptModifier", "Scripts/Modifiers/")

--CAMSPRINGFOLLOW CLASS START

local CAM_SPRING_STIFFNESS = 1500.0
local setSpring = function (value) CAM_SPRING_STIFFNESS = value end
local getSpring = function () return CAM_SPRING_STIFFNESS end
DefineVar("CAM_SPRING_STIFFNESS", setSpring, getSpring)

local CAM_SPRING_DAMPING = 200.0
local setDamping = function (value) CAM_SPRING_DAMPING = value end
local getDamping = function () return CAM_SPRING_DAMPING end
DefineVar("CAM_SPRING_DAMPING", setDamping, getDamping)

local CAM_SPRING_REST_LENGTH = 0.5
local setRest = function (value) CAM_SPRING_REST_LENGTH = value end
local getRest = function () return CAM_SPRING_REST_LENGTH end
DefineVar("CAM_SPRING_REST_LENGTH", setRest, getRest)

local CAM_SPRING_MASS = 50.0
local setMass = function (value) CAM_SPRING_MASS = value end
local getMass = function () return CAM_SPRING_MASS end
DefineVar("CAM_SPRING_MASS", setMass, getMass)

local CAM_SPRING_DRAG = 0.97
local setDrag = function (value) CAM_SPRING_DRAG = value end
local getDrag = function () return CAM_SPRING_DRAG end
DefineVar("CAM_SPRING_DRAG", setDrag, getDrag)

class 'CamSpringFollow' (ScriptModifier)

function CamSpringFollow:__init(followObject, setCamera) super(followObject)

	self.followObject = followObject
	self.camera = setCamera
	self.clock = WTimer()
	self.enabled = true

	self.position = WVector3()
	self.velocity = WVector3()
	self.acceleration = WVector3()

	self.cameraSpeedPercent = 0
	self.cameraSpeedPercentStep = 0.75
	self.cameraMinHeight = 2.25
	self.cameraMaxHeight = 2
	self.cameraMinDistance = 4.5
	self.cameraMaxDistance = 7.5

	self.direction = WVector3()
	self.force = WVector3()

end


function CamSpringFollow:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamSpringFollow:GetEnabled()

	return self.enabled

end


function CamSpringFollow:SetFollowObjectImp(followObject)

	self.followObject = followObject

end


function CamSpringFollow:Process()

	if (not IsValid(self.followObject)) then
		return
	end

	local timeDiff = self.clock:GetTimeDifference()

	if self.enabled then
		local targetPos = WVector3(self.followObject:GetPosition())

		--Find the correct forward normal
		local forwardNormal = WVector3(self.followObject:GetLinearVelocity())
		if forwardNormal:Equals(WVector3(0, 0, 0), 3) then
			forwardNormal = WVector3(self.followObject:GetOrientation():zAxis())
		end
		forwardNormal:Normalise()

		local speedPercent = self.followObject:GetSpeedPercent()
		if self.cameraSpeedPercent < speedPercent then
			self.cameraSpeedPercent = self.cameraSpeedPercent + (self.cameraSpeedPercentStep * timeDiff)
			if self.cameraSpeedPercent > speedPercent then
				self.cameraSpeedPercent = speedPercent
			end
		elseif self.cameraSpeedPercent > speedPercent then
			self.cameraSpeedPercent = self.cameraSpeedPercent - (self.cameraSpeedPercentStep * timeDiff)
			if self.cameraSpeedPercent < speedPercent then
				self.cameraSpeedPercent = speedPercent
			end
		end

		--Camera height
		local camHeightDiff = self.cameraMaxHeight - self.cameraMinHeight
		local cameraHeight = self.cameraMaxHeight - (camHeightDiff * self.followObject:GetSpeedPercent())
		--Negate the gravity to determine the up vector
		local upNormal = self.followObject:GetUpNormal()
		targetPos = targetPos + (upNormal * cameraHeight)

		--Camera distance
		local camDiff = self.cameraMaxDistance - self.cameraMinDistance
		targetPos = targetPos - (forwardNormal * (self.cameraMinDistance + (camDiff * self.cameraSpeedPercent)))

		self:ProcessSpring(timeDiff, targetPos)
		self:Integrate(timeDiff)

		self.camera:SetPosition(self.position)
		self.camera:GetLookAt():SetPosition(self.position + forwardNormal)
	end

end


function CamSpringFollow:ProcessSpring(timeDiff, targetPos)

	local currentPos = WVector3(self.camera:GetPosition())
	--Get the direction vector
	self.direction:Set(currentPos - targetPos)

	--Check for zero vector
	if not self.direction:IsZeroLength() then
		local currLength = self.direction:Length()

		self.direction:Normalise()

		--Add spring force
		self.force = (-CAM_SPRING_STIFFNESS * ((currLength - CAM_SPRING_REST_LENGTH) * self.direction)) * timeDiff

		--Add spring damping force
		self.force = self.force + (-CAM_SPRING_DAMPING * self.velocity:DotProduct(self.direction) * self.direction) * timeDiff

	end

end


function CamSpringFollow:Integrate(timeDiff)

	--Calc acceleration
	self.acceleration = self.force / CAM_SPRING_MASS
	--Apply acceleration
	self.velocity = self.velocity + (self.acceleration * timeDiff)

	--Apply psuedo drag
	self.velocity = self.velocity * CAM_SPRING_DRAG

	--Apply velocity
	self.position = self.position + self.velocity

	--Clear forces
	self.force.x = 0
	self.force.y = 0
	self.force.z = 0

end

--CAMSPRINGFOLLOW CLASS END