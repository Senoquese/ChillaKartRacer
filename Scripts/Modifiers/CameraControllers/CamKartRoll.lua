UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMKARTROLL CLASS START

class 'CamKartRoll' (ICamController)

function CamKartRoll:__init(kartObject, setCamera) super(kartObject)

	self.kartObject = kartObject
	self.camera = setCamera
	self.enabled = true

	self.cameraRoll = 0
	self.cameraRollSpeed = DegreeToRadian(3)
	self.maxCameraRoll = DegreeToRadian(3)

end


function CamKartRoll:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamKartRoll:GetEnabled()

	return self.enabled

end


function CamKartRoll:SetFollowObjectImp(followObject)

	self.kartObject = followObject

end


function CamKartRoll:NotifyActive()

end


function CamKartRoll:ProcessCamController(frameTime)

	if self.enabled and IsValid(self.kartObject) and IsValid(self.kartObject.GetObject) then

		local kart = self.kartObject

		if IsValid(kart) then
			--Rotate the camera based on the turn state
			--if there is no turning or if the kart is traveling back, no roll
			if kart:GetTurnState() == VehicleTurnState.TURN_NONE or kart:GetCurrentSpeed() < 0 then
				if self.cameraRoll > 0 then
					self.cameraRoll = self.cameraRoll - (self.cameraRollSpeed * frameTime)
					if self.cameraRoll < 0 then
						self.cameraRoll = 0
					end
				elseif self.cameraRoll < 0 then
					self.cameraRoll = self.cameraRoll + (self.cameraRollSpeed * frameTime)
					if self.cameraRoll > 0 then
						self.cameraRoll = 0
					end
				end
			elseif kart:GetTurnState() == VehicleTurnState.TURN_RIGHT then
				self.cameraRoll = self.cameraRoll - (self.cameraRollSpeed * frameTime)
			elseif kart:GetTurnState() == VehicleTurnState.TURN_LEFT then
				self.cameraRoll = self.cameraRoll + (self.cameraRollSpeed * frameTime)
			end

			--Over/Under check, only check if the kart is going forward
			if kart:GetCurrentSpeed() > 0 then
				if self.cameraRoll > self.maxCameraRoll * kart:GetSpeedPercent() then
					self.cameraRoll = self.maxCameraRoll * kart:GetSpeedPercent()
				elseif self.cameraRoll < (-self.maxCameraRoll * kart:GetSpeedPercent()) then
					self.cameraRoll = (-self.maxCameraRoll * kart:GetSpeedPercent())
				end
			end

			self.camera:Roll(self.cameraRoll)
		end

	end

end

--CAMKARTROLL CLASS END