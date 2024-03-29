UseModule("ScriptModifier", "Scripts/Modifiers/")

local VEL_CAM_FOLLOW = 10
local setFollow = function (value) VEL_CAM_FOLLOW = value end
local getFollow = function () return VEL_CAM_FOLLOW end
DefineVar("VEL_CAM_FOLLOW", setFollow, getFollow)

local VEL_CAM_SAMPLE_TIMER = 0.3
local setSampleTimer = function (value) VEL_CAM_SAMPLE_TIMER = value end
local getSampleTimer = function () return VEL_CAM_SAMPLE_TIMER end
DefineVar("VEL_CAM_SAMPLE_TIMER", setSampleTimer, getSampleTimer)

--CAMKARTVELFOLLOW CLASS START

class 'CamKartVelFollow' (ScriptModifier)

function CamKartVelFollow:__init(kartObject, setCamera) super(kartObject)

	self.kartObject = kartObject
	self.camera = setCamera
	self.enabled = true

	self.sampleClock = WTimer()
	--Two sampled normals stored at any time
	--They are lerped between for the current normal
	self.sampledNormals = { WVector3(), WVector3() }

	self.cameraMinDistance = 4.5
	self.cameraMaxDistance = 6
	self.cameraMinLookAtDistance = 8
	self.cameraMaxLookAtDistance = 16
	self.cameraMinHeight = 1
	self.cameraMaxHeight = 1.5
	--true when the player wants to look behind instead of forward
	self.lookBehind = false

	self.lookBackSlot = self:CreateSlot("ControlLookBack", "ControlLookBack")

end


function CamKartVelFollow:__finalize()

end


function CamKartVelFollow:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamKartVelFollow:GetEnabled()

	return self.enabled

end


function CamKartVelFollow:SetFollowObjectImp(followObject)

	self.kartObject = followObject

end


function CamKartVelFollow:Process()

	if (not IsValid(self.kartObject)) then
		return
	end

	local timeDiff = GetTimeDifference()

	if self.enabled then
		local kartVel = self.kartObject:GetLinearVelocity()
		if kartVel:Equals(WVector3(0, 0, 0), 5) then
			kartVel = self.kartObject:GetOrientation():zAxis()
		end
		local kartNormal = WVector3(kartVel)
		if self.lookBehind then
			kartNormal:Negate()
		end
		kartNormal:Normalise()

		--Camera Position
		local camDiff = self.cameraMaxDistance - self.cameraMinDistance
		local finalCamPos = WVector3(self.kartObject:GetPosition() - kartNormal * (self.cameraMinDistance + (camDiff * self.kartObject:GetSpeedPercent())))
		--Height
		local camHeightDiff = self.cameraMaxHeight - self.cameraMinHeight
		local cameraHeight = self.cameraMinHeight + (camHeightDiff * self.kartObject:GetSpeedPercent())
		finalCamPos.y = finalCamPos.y + cameraHeight

		--Look At
		local lookAtDiff = self.cameraMaxLookAtDistance - self.cameraMinLookAtDistance;
		local finalCamLookAtPos = WVector3(self.kartObject:GetPosition() + kartNormal * (self.cameraMinLookAtDistance + (lookAtDiff * self.kartObject:GetSpeedPercent())))

		self.camera:SetPosition(finalCamPos)
		self.camera:GetLookAt():SetPosition(finalCamLookAtPos)


		--[[
		--Time to sample?
		if self.sampleClock:GetTimeSeconds() > VEL_CAM_SAMPLE_TIMER then
			self.sampleClock:Reset()
			--Move the latest normal into the oldest normal spot
			self.sampledNormals[2] = self.sampledNormals[1]
			--Calculate a new latest
			local kartVel = self.kartObject:GetLinearVelocity()
			if kartVel:Equals(WVector3(0, 0, 0), 5) then
				kartVel = self.kartObject:GetOrientation():zAxis()
			end
			self.sampledNormals[1] = WVector3(kartVel)
			if self.lookBehind then
				self.sampledNormals[1]:Negate()
			end
			self.sampledNormals[1]:Normalise()
		end

		--Camera Position
		local camDiff = self.cameraMaxDistance - self.cameraMinDistance
		local finalCamPosStart = WVector3(self.kartObject:GetPosition() - self.sampledNormals[2] * (self.cameraMinDistance))-- + (camDiff * self.kartObject:GetSpeedPercent())))
		local finalCamPosEnd = WVector3(self.kartObject:GetPosition() - self.sampledNormals[1] * (self.cameraMinDistance))-- + (camDiff * self.kartObject:GetSpeedPercent())))
		--Height
		finalCamPosStart.y = finalCamPosStart.y + self.cameraHeight
		finalCamPosEnd.y = finalCamPosEnd.y + self.cameraHeight

		--Calculate a final camera position
		local finalCamPos = WVector3Lerp(self.sampleClock:GetTimeSeconds() / VEL_CAM_SAMPLE_TIMER, finalCamPosStart, finalCamPosEnd)

		--Look At
		local lookAtDiff = self.cameraMaxLookAtDistance - self.cameraMinLookAtDistance;
		local finalCamLookAtPosStart = WVector3(self.kartObject:GetPosition() + self.sampledNormals[2] * (self.cameraMinLookAtDistance))-- + (lookAtDiff * self.kartObject:GetSpeedPercent())))
		local finalCamLookAtPosEnd = WVector3(self.kartObject:GetPosition() + self.sampledNormals[1] * (self.cameraMinLookAtDistance))-- + (lookAtDiff * self.kartObject:GetSpeedPercent())))

		--Calculate a final camera look at position
		local finalCamLookAtPos = WVector3Lerp(self.sampleClock:GetTimeSeconds() / VEL_CAM_SAMPLE_TIMER, finalCamLookAtPosStart, finalCamLookAtPosEnd)

		self.camera:SetPosition(finalCamPos)
		self.camera:GetLookAt():SetPosition(finalCamLookAtPos)
		--]]
	end

end


function CamKartVelFollow:ControlLookBack(lookBackParams)

	local pressed = lookBackParams:GetParameter("Pressed", true):GetBoolData()
	if pressed then
		self.lookBehind = true
	else
		self.lookBehind = false
	end

end

--CAMKARTVELFOLLOW CLASS END