UseModule("IBase", "Scripts/")

--ICAMCONTROLLER CLASS START
--Any camera controller needs to derive from ICamController
--All ICamController must implement the following functions:
--ProcessCamController()
--NotifyActive() - Will be called when this controller is the active controller

--All ICamController may implement the following functions:

--Signals:
--Slots:

class 'ICamController' (IBase)

function ICamController:__init(setFollowObject) super()

	self.enabled = true
	self.followObj = nil
	self:SetFollowObject(setFollowObject)

end


function ICamController:BuildInterfaceDefIBase()

	self:AddClassDef("ICamController", "IBase", "The base class for any class that is a camera controller")
	self:AddFuncDef("ICamController", self.ProcessCamController, self.I_REQUIRED_FUNC, "ProcessCamController", "Called to give the camera controller processor time")
	self:AddFuncDef("ICamController", self.NotifyActive, self.I_REQUIRED_FUNC, "NotifyActive", "Called to notify the controller it is now active")
	self:AddFuncDef("ICamController", self.SetFollowObjectImp, self.I_OPTIONAL_FUNC, "SetFollowObjectImp", "Call to set the optional object the camera should follow")

end


function ICamController:InitIBase()

end


function ICamController:UnInitIBase()

end


function ICamController:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function ICamController:GetEnabled()

	return self.enabled

end


function ICamController:SetFollowObject(followObject)

	self.followObj = followObject
	--Notify the child
	self:SetFollowObjectImp(self.followObj)
	GetCameraManager():_NotifyFollowObjectChanged(self.followObject, self)

end


function ICamController:GetFollowObject()

	return self.followObj

end


function ICamController:Process(frameTime)

	self:ProcessCamController(frameTime)

end

--ICAMCONTROLLER CLASS END