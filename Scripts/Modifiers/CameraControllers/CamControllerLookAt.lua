UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERLOOKAT CLASS START

class 'CamControllerLookAt' (ICamController)

function CamControllerLookAt:__init(followObject, setCamera) super(followObject)

	self.followObject = followObject
	self.camera = setCamera

end


function CamControllerLookAt:SetFollowObjectImp(followObject)

	self.followObject = followObject

end


function CamControllerLookAt:ProcessCamController(frameTime)

	if IsValid(self.followObject) then
		self.camera:GetLookAt():SetPosition(self.followObject:GetPosition())
	end

end


function CamControllerLookAt:NotifyActive()

end

--CAMCONTROLLERLOOKAT CLASS END