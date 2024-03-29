UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERGOTO CLASS START

class 'CamControllerGoTo' (ICamController)

function CamControllerGoTo:__init(gotoPos, gotoLookAt, setCamera) super()

	self.gotoPos = gotoPos
	self.gotoLookAt = gotoLookAt
	self.camera = setCamera

end


function CamControllerGoTo:ProcessCamController(frameTime)

	local camPos = self.camera:GetPosition()
	camPos = camPos + ((self.gotoPos - camPos) * frameTime)
	self.camera:SetPosition(camPos)

	camPos = self.camera:GetLookAt():GetPosition()
	camPos = camPos + ((self.gotoLookAt - camPos) * frameTime)
	self.camera:GetLookAt():SetPosition(camPos)

end


function CamControllerGoTo:SetFollowObjectImp(setFollowObj)

end


function CamControllerGoTo:NotifyActive()

end

--CAMCONTROLLERGOTO CLASS END