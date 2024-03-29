UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMKARTFOV CLASS START

class 'CamKartFOV' (ICamController)

function CamKartFOV:__init(kartObject, setCamera) super(kartObject)

	self.kartObject = kartObject
	self.camera = setCamera
	self.enabled = true

	self.cameraFOV = self.camera:GetBaseFOV()
	self.cameraFOVStep = 30
	self.handbrakeKartAngle = 0
	self.handbrakeFOVModifier = 5
	self.boostFOVTarget = 8
	self.boostFOVStep = 8

end


function CamKartFOV:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamKartFOV:GetEnabled()

	return self.enabled

end


function CamKartFOV:SetFollowObjectImp(followObject)

	self.kartObject = followObject

end


function CamKartFOV:NotifyActive()

end


function CamKartFOV:ProcessCamController(frameTime)

	local paramFOV = GetSettingTable():GetSetting("FOV", "Shared", false)
    if IsValid(paramFOV) then
    	fovNum = tonumber(paramFOV:GetStringData())
    end
    
	local baseCameraFOV = self.camera:GetBaseFOV()/2 + fovNum

	--BRIAN TODO: Find a better way to query the handbrake state considering some
	--controllers won't have a handbrake
	if self.enabled and IsValid(self.kartObject) and IsValid(self.kartObject.GetHandbrakeEnabled) then

		--Camera FOV effect
		if self.kartObject:GetHandbrakeEnabled() then
			local targetFOV = baseCameraFOV + math.abs(self.handbrakeKartAngle) / self.handbrakeFOVModifier
			self:SetFOVOverTime(targetFOV, self.cameraFOVStep, frameTime)
			self.camera:SetFOV(self.cameraFOV)
		end

		--Boost FOV effect
		if false and self.kartObject:GetBoostEnabled() then
			self:SetFOVOverTime(baseCameraFOV + self.boostFOVTarget, self.boostFOVStep, frameTime)
			self.camera:SetFOV(self.cameraFOV)
		end

		--Always attempt to normalise the FOV
		--Only do this if this object is owned by the player
		--and the handbrake is off
		if (not self.kartObject:GetHandbrakeEnabled()) and (not self.kartObject:GetBoostEnabled()) then
			self:SetFOVOverTime(baseCameraFOV, self.cameraFOVStep, frameTime)
			self.camera:SetFOV(self.cameraFOV)
		end

	end

end


function CamKartFOV:SetFOVOverTime(targetFOV, FOVStep, frameTime)

	if self.cameraFOV < targetFOV then
		self.cameraFOV = self.cameraFOV + (FOVStep * frameTime)
		if self.cameraFOV > targetFOV then
			self.cameraFOV = targetFOV
		end
	elseif self.cameraFOV > targetFOV then
		self.cameraFOV = self.cameraFOV - (FOVStep * frameTime)
		if self.cameraFOV < targetFOV then
			self.cameraFOV = targetFOV
		end
	end

end

--CAMKARTFOV CLASS END