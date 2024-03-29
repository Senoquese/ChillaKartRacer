UseModule("ISynced", "Scripts/SyncedObjects/")

--ICONTROLLER CLASS START
--Any character controller needs to derive from IController
--All IControllers must implement the following functions:
--ActivateCamController() - Add the IController's ICamController to the CameraManager
--DeactivateCamController() - Remove the IController's ICamController from the CameraManager
--InitController()
--UnInitController()
--SetEnabled(enabled)
--SetEnableControlsImp(enable)
--SetBoostEnabledImp(enable)
--NotifyRespawnedImp(pos, orien)
--GetControllerUpNormal()
--GetControllerLinearVelocity()
--GetControllerSpeedPercent()
--ProcessController()
--GetControllerActive() - Only active controllers get synced
--SetControllerStateData(stateBuiltTime, setState)
--GetControllerStateData(returnState)

--All IControllers may implement the following functions:
--NotifyControllerPositionChange() - Will be called when SetPosition() is called on the IController
--NotifyControllerOrientationChange() - Will be called when SetOrientation() is called on the IController
--NotifyControllerScaleChange() - Will be called when SetScale() is called on the IController
--NotifyControllerSetMass() - Will be called to notify the controller it's mass has changed

--Signals:
--BoostEnabled - Emitted when the boost is enabled or disabled
--BoostPercent - Emitted when the amount of boost changes
--Slots:

class 'IController' (ISynced)

function IController:__init() super()

	self.ownerID = 0
	self.enabled = true
	self.inWorld = false
	self.controlsEnabled = true
	--How much boost juice the controller currently has
	self.boostPercent = 0
	--Is boost enabled in the controller
	self.boostEnabled = false

	self.boostEnabledSignal = self:CreateSignal("BoostEnabled")
	self.boostPercentSignal = self:CreateSignal("BoostPercent")
	self.boostParams = Parameters()

	self.enableControlsSignal = self:CreateSignal("EnableControls")
	self.enableControlsParams = Parameters()

end


function IController:BuildInterfaceDefISynced()

	self:AddClassDef("IController", "ISynced", "An IController object is any object that can be controlled by a player")
	self:AddFuncDef("IController", self.ActivateCamController, self.I_REQUIRED_FUNC, "ActivateCamController", "")
	self:AddFuncDef("IController", self.DeactivateCamController, self.I_REQUIRED_FUNC, "DeactivateCamController", "")
	self:AddFuncDef("IController", self.InitController, self.I_REQUIRED_FUNC, "InitController", "")
	self:AddFuncDef("IController", self.UnInitController, self.I_REQUIRED_FUNC, "UnInitController", "")
	self:AddFuncDef("IController", self.SetEnabledImp, self.I_REQUIRED_FUNC, "SetEnabledImp", "")
	self:AddFuncDef("IController", self.SetEnableControlsImp, self.I_REQUIRED_FUNC, "SetEnableControlsImp", "")
	self:AddFuncDef("IController", self.SetBoostEnabledImp, self.I_REQUIRED_FUNC, "SetBoostEnabledImp", "")
	self:AddFuncDef("IController", self.NotifyRespawnedImp, self.I_REQUIRED_FUNC, "NotifyRespawnedImp", "")
	self:AddFuncDef("IController", self.GetGraphicalPosition, self.I_REQUIRED_FUNC, "GetGraphicalOrientation", "")
	self:AddFuncDef("IController", self.GetGraphicalOrientation, self.I_REQUIRED_FUNC, "GetGraphicalOrientation", "")
	self:AddFuncDef("IController", self.GetControllerUpNormal, self.I_REQUIRED_FUNC, "GetControllerUpNormal", "")
	self:AddFuncDef("IController", self.GetControllerLinearVelocity, self.I_REQUIRED_FUNC, "GetControllerLinearVelocity", "")
	self:AddFuncDef("IController", self.GetControllerSpeedPercent, self.I_REQUIRED_FUNC, "GetControllerSpeedPercent", "")
	self:AddFuncDef("IController", self.ProcessController, self.I_REQUIRED_FUNC, "ProcessController", "")
	self:AddFuncDef("IController", self.GetControllerActive, self.I_REQUIRED_FUNC, "GetControllerActive", "")
	self:AddFuncDef("IController", self.SetControllerStateData, self.I_REQUIRED_FUNC, "SetControllerStateData", "")
	self:AddFuncDef("IController", self.GetControllerStateData, self.I_REQUIRED_FUNC, "GetControllerStateData", "")
	self:AddFuncDef("IController", self.NotifyControllerPositionChange, self.I_OPTIONAL_FUNC, "NotifyControllerPositionChange", "")
	self:AddFuncDef("IController", self.NotifyControllerOrientationChange, self.I_OPTIONAL_FUNC, "NotifyControllerOrientationChange", "")
	self:AddFuncDef("IController", self.NotifyControllerScaleChange, self.I_OPTIONAL_FUNC, "NotifyControllerScaleChange", "")
	self:AddFuncDef("IController", self.NotifyControllerSetMass, self.I_OPTIONAL_FUNC, "NotifyControllerSetMass", "")
	self:AddFuncDef("IController", self.NotifyControllerSetLinearDamping, self.I_OPTIONAL_FUNC, "NotifyControllerSetLinearDamping", "")
	self:AddFuncDef("IController", self.NotifyControllerSetAngularDamping, self.I_OPTIONAL_FUNC, "NotifyControllerSetAngularDamping", "")
	self:AddFuncDef("IController", self.NotifyOwnerIDChanged, self.I_OPTIONAL_FUNC, "NotifyOwnerIDChanged", "")
	self:AddFuncDef("IController", self.BuildInterfaceDefIController, self.I_REQUIRED_FUNC, "BuildInterfaceDefISynced", "")

	self:BuildInterfaceDefIController()

end


function IController:InitIBase()

	self:InitController()
	
	if IsServer() then
	    --Init the enabled state
	    GetServerSystem():GetSendStateTable("Map"):NewState("Enabled" .. tostring(self:GetID()))
	    self.enabledParam = Parameter()
	else
	    self.enabledSlot = self:CreateSlot("SetEnabledSlot", "SetEnabledSlot")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("Enabled" .. tostring(GetClientWorld():GetServerObjectID(self:GetID())), self.enabledSlot)
	end

end


function IController:UnInitIBase()

	self:UnInitController()

end


function IController:SetOwnerID(setOwnerID)

	if setOwnerID == 0 then
		error("OwnerID is 0 in IController:SetOwnerID()")
	end
	local oldID = self.ownerID
	self.ownerID = setOwnerID
	if IsValid(self.NotifyOwnerIDChanged) then
		self:NotifyOwnerIDChanged(oldID, self.ownerID)
	end

end


function IController:GetOwnerID()

	return self.ownerID

end

function IController:SetEnabledSlot(enabledParams)

    print("IController:SetEnabledSlot:"..tostring(enabledParams:GetParameter(0, true):GetBoolData()))
	self:SetEnabled(enabledParams:GetParameter(0, true):GetBoolData())

end

function IController:SetEnabled(setEnabled)

	self.enabled = setEnabled
	self:SetEnabledImp(self.enabled)
	
	if IsServer() then
	    -- Update enabled state on client
	    self.enabledParam:SetBoolData(setEnabled)
		--GetServerSystem():GetSendStateTable("Map"):SetState("Enabled" .. tostring(self:GetID()), self.enabledParam)
	end

end


function IController:GetEnabled()

	return self.enabled

end


function IController:GetInWorld()

	return self.inWorld

end


function IController:SetEnableControls(enable)

	self.controlsEnabled = enable
	--The child handles this
	self:SetEnableControlsImp(enable)

	self.enableControlsParams:GetOrCreateParameter("Enable"):SetBoolData(self.controlsEnabled)
    self.enableControlsSignal:Emit(self.enableControlsParams)

end


function IController:GetEnableControls()

	return self.controlsEnabled

end


function IController:SetBoostEnabled(setEnabled)

	if self.boostEnabled ~= setEnabled then

		self.boostEnabled = setEnabled
		self:SetBoostEnabledImp(self.boostEnabled)

		--Emit the signal to notify everyone of the boost state change
		self.boostParams:GetOrCreateParameter(0):SetBoolData(self.boostEnabled)
		self.boostEnabledSignal:Emit(self.boostParams)
	end

end


function IController:GetBoostEnabled()

	return self.boostEnabled

end


function IController:SetBoostPercent(setPercent)

	if self.boostPercent ~= setPercent then
		--Clamp to between 0 and 1
		if setPercent < 0 then
			setPercent = 0
		elseif setPercent > 1 then
			setPercent = 1
		end

		self.boostPercent = setPercent

		--Emit the signal to notify everyone of the boost percent change
		self.boostParams:GetOrCreateParameter(0):SetFloatData(self.boostPercent)
		self.boostPercentSignal:Emit(self.boostParams)
	end

end


function IController:GetBoostPercent()

	return self.boostPercent

end


function IController:NotifyRespawned(respawnPos, respawnOrien)

	self:NotifyRespawnedImp(respawnPos, respawnOrien)

end


function IController:GetUpNormal()

	return self:GetControllerUpNormal()

end


function IController:GetLinearVelocity()

	return self:GetControllerLinearVelocity()

end


function IController:GetSpeedPercent()

	return self:GetControllerSpeedPercent()

end


function IController:SetMass(setMass)

	if IsValid(self.NotifyControllerSetMass) then
		self:NotifyControllerSetMass(setMass)
	end

end


function IController:SetLinearDamping(setDamping)

	if IsValid(self.NotifyControllerSetLinearDamping) then
		self:NotifyControllerSetLinearDamping(setDamping)
	end

end


function IController:SetAngularDamping(setDamping)

	if IsValid(self.NotifyControllerSetAngularDamping) then
		self:NotifyControllerSetAngularDamping(setDamping)
	end

end


function IController:NotifyScriptObjectPositionChange(setPos)

	PUSH_PROFILE("IController:NotifyScriptObjectPositionChange(setPos)")

	if IsValid(self.NotifyControllerPositionChange) then
		self:NotifyControllerPositionChange(setPos)
	end

	POP_PROFILE("IController:NotifyScriptObjectPositionChange(setPos)")

end


function IController:NotifyScriptObjectOrientationChange(setOrien)

	PUSH_PROFILE("IController:NotifyScriptObjectOrientationChange(setOrien)")

	if IsValid(self.NotifyControllerOrientationChange) then
		self:NotifyControllerOrientationChange(setOrien)
	end

	POP_PROFILE("IController:NotifyScriptObjectOrientationChange(setOrien)")

end


function IController:NotifyScriptObjectScaleChange(setScale)

	if IsValid(self.NotifyControllerScaleChange) then
		self:NotifyControllerScaleChange(setScale)
	end

end


function IController:ProcessSyncedObject(frameTime)

	self:ProcessController(frameTime)

end


function IController:GetSyncedActive()

	return self:GetControllerActive()

end


function IController:SetSyncedStateData(stateBuiltTime, setState)

	local boostEnabled = setState:ReadBool()
	self:SetBoostEnabled(boostEnabled)
	local boostPercent = setState:ReadFloat()
	self:SetBoostPercent(boostPercent)

	self:SetControllerStateData(stateBuiltTime, setState)

end


function IController:GetSyncedStateData(returnState)

	returnState:WriteBool(self:GetBoostEnabled())
	returnState:WriteFloat(self:GetBoostPercent())

	self:GetControllerStateData(returnState)

end

--ICONTROLLER CLASS END