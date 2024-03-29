UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")
UseModule("CamControllerFollow", "Scripts/Modifiers/CameraControllers/")
UseModule("CamKartFOV", "Scripts/Modifiers/CameraControllers/")
UseModule("CamKartRoll", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERKARTCOMBINER CLASS START

class 'CamControllerKartCombiner' (ICamController)

function CamControllerKartCombiner:__init(kartObject, setCamera) super(kartObject)

	self.kartObject = kartObject
	self.camera = setCamera
	self.enabled = true

	self.camControllerFollow = CamControllerFollow(self.kartObject, self.camera)
	self.camKartFOV = CamKartFOV(self.kartObject, self.camera)
	self.camKartRoll = CamKartRoll(self.kartObject, self.camera)
	self:SetFollowObject(kartObject)

end


function CamControllerKartCombiner:NotifyActive()

    self.camControllerFollow:NotifyActive()

end


function CamControllerKartCombiner:SetEnabled(setEnabled)

	self.enabled = setEnabled

	self.camControllerFollow:SetEnabled(self.enabled)
	self.camKartFOV:SetEnabled(self.enabled)
	self.camKartRoll:SetEnabled(self.enabled)

end


function CamControllerKartCombiner:GetEnabled()

	return self.enabled

end


function CamControllerKartCombiner:SetFollowObjectImp(followObject)

	if IsValid(self.camControllerFollow) then
		self.camControllerFollow:SetFollowObject(followObject)
	end
	if IsValid(self.camKartFOV) then
		self.camKartFOV:SetFollowObject(followObject)
	end
	if IsValid(self.camKartRoll) then
		self.camKartRoll:SetFollowObject(followObject)
	end

end


function CamControllerKartCombiner:ProcessCamController(frameTime)

	if self.enabled then
		self.camControllerFollow:Process(frameTime)
		self.camKartFOV:Process(frameTime)
		self.camKartRoll:Process(frameTime)
	end

end

--CAMCONTROLLERKARTCOMBINER CLASS END