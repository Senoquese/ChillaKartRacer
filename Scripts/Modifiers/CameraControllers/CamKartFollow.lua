UseModule("ScriptModifier", "Scripts/Modifiers/")

--CAMKARTFOLLOW CLASS START

class 'CamKartFollow' (ScriptModifier)

function CamKartFollow:__init(kartObject, setCamera) super()

	self.kartObject = kartObject
	self.camera = setCamera
	self.clock = WClock()
	self.enabled = true

	self.normalBuffer = { }
	self.bufferPushTimer = 0
	--How much time to wait before pushing the current
	--kart forward vector into the buffer
	--self.bufferPushTime = 0.005
	--self.maxBufferSize = 36
	self.bufferPushTime = 0.200
	self.maxBufferSize = 2
	self.oldestNormalPos = 1
	self.cameraSpeedPercent = 0
	self.cameraSpeedPercentStep = 0.75
	self.cameraMinDistance = 4.5
	self.cameraMaxDistance = 7.5
	self.cameraMinLookAtDistance = 20
	self.cameraMaxLookAtDistance = 40
	self.cameraMinHeight = 2.25
	self.cameraMaxHeight = 2
	self.lastGravity = WVector3(0, -10, 0)
	self.lastKartVelocity = WVector3()

	self.lastKartAvgFoward = WVector3()
	self.targetKartAvgForward = WVector3()

	--true when the player wants to look behind instead of forward
	self.lookBehind = false

	self.lookBackSlot = self:CreateSlot("ControlLookBack", "ControlLookBack")
	GetClientManager():GetInputSignal("ControlLookBack"):Connect(self.lookBackSlot)

end


function CamKartFollow:__finalize()

end


function CamKartFollow:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamKartFollow:GetEnabled()

	return self.enabled

end


function CamKartFollow:SetFollowObject(followObject)

	self.kartObject = followObject

end


function CamKartFollow:GetFollowObject()

	return self.kartObject

end


function CamKartFollow:Process()

	if (not IsValid(self.kartObject)) then
		return
	end

	local timeDiff = self.clock:GetTimeDifference()

	local forwardNormal = WVector3(self.kartObject:GetLinearVelocity())
	if forwardNormal:Equals(WVector3(0, 0, 0), 3) then
		if self.lastKartVelocity:IsZeroLength() then
			forwardNormal = WVector3(self.kartObject:GetOrientation():zAxis())
		--else
		--	forwardNormal = self.lastKartVelocity
		end
	end
	if self.lookBehind then
		forwardNormal:Negate()
	end
	forwardNormal:Normalise()

	if self.enabled then
		--BRIAN TODO: make the camera loosining code less dependant on time
		self.bufferPushTimer = self.bufferPushTimer + timeDiff

		if self.bufferPushTimer > self.bufferPushTime then
			--[[self.normalBuffer[self.oldestNormalPos] = forwardNormal
			self.oldestNormalPos = self.oldestNormalPos + 1
			if self.oldestNormalPos > self.maxBufferSize then
				self.oldestNormalPos = 1
			end]]

			self.bufferPushTimer = 0

			--Swap the current average kart foward into the new target
			self.lastKartAvgFoward = self.targetKartAvgForward

			self.targetKartAvgForward = forwardNormal

			--[[--Find the new average kart forward target
			self.targetKartAvgForward = WVector3()
			for i, vector in ipairs(self.normalBuffer) do
				self.targetKartAvgForward = self.targetKartAvgForward + vector
			end
			--self.kartAvgForward = self.kartAvgForward + forwardNormal
			--self.kartAvgForward = self.kartAvgForward / (#self.normalBuffer + 1)
			self.targetKartAvgForward = self.targetKartAvgForward / (#self.normalBuffer)
			self.targetKartAvgForward:Normalise()]]
		end

		local kartAvgForward = WVector3Lerp((self.bufferPushTimer / self.bufferPushTime), self.lastKartAvgFoward, self.targetKartAvgForward)
		kartAvgForward:Normalise()

		local currentCamPos = WVector3(self.camera:GetPosition())
		local currentCamLookAtPos = WVector3(self.camera:GetLookAt():GetPosition())
		local kartPos = WVector3(self.kartObject:GetPosition())
		local desiredCameraPosition = WVector3(kartPos)
		local desiredCamLookAtPos = WVector3(kartPos)

		local speedPercent = self.kartObject:GetSpeedPercent()
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

		--Camera Position
		local camDiff = self.cameraMaxDistance - self.cameraMinDistance
		--desiredCameraPosition = desiredCameraPosition - (kartAvgForward * (self.cameraMinDistance + (camDiff * self.cameraSpeedPercent)))
		desiredCameraPosition = desiredCameraPosition - (kartAvgForward * 5)
		--Height
		local camHeightDiff = self.cameraMaxHeight - self.cameraMinHeight
		--local cameraHeight = self.cameraMaxHeight - (camHeightDiff * self.kartObject:GetSpeedPercent())
		local cameraHeight = self.cameraMaxHeight
		--Negate the gravity to determine the up vector
		local upNormal = self.kartObject:GetUpNormal()
		desiredCameraPosition = desiredCameraPosition + (upNormal * cameraHeight)
		--desiredCameraPosition.y = desiredCameraPosition.y + cameraHeight
		--Look At
		local lookAtDiff = self.cameraMaxLookAtDistance - self.cameraMinLookAtDistance;
		desiredCamLookAtPos = desiredCamLookAtPos + kartAvgForward * (self.cameraMinLookAtDistance)-- + (lookAtDiff * self.cameraSpeedPercent))

		self.camera:SetPosition(desiredCameraPosition)
		self.camera:GetLookAt():SetPosition(desiredCamLookAtPos)

	end

end


function CamKartFollow:ControlLookBack(lookBackParams)

	local pressed = lookBackParams:GetParameter("Pressed", true):GetBoolData()
	if pressed then
		self.lookBehind = true
	else
		self.lookBehind = false
	end

end

--CAMKARTFOLLOW CLASS END