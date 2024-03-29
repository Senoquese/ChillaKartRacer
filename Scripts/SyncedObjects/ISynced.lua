UseModule("IScriptObject", "Scripts/")

--ISYNCED CLASS START
--All ISynced objects must implement the following functions:
--GetSyncedActive() - Only active synced objects get synced
--SetSyncedStateData(stateBuiltTime, setState)
--GetSyncedStateData(returnState)

--Signals:
--Slots:

class 'ISynced' (IScriptObject)

function ISynced:__init() super()

end


function ISynced:BuildInterfaceDefIScriptObject()

	self:AddClassDef("ISynced", "IScriptObject", "An ISynced object is expected to sync over the network")
	self:AddFuncDef("ISynced", self.GetSyncedActive, self.I_REQUIRED_FUNC, "GetSyncedActive", "Will be called to check if this object should update")
	self:AddFuncDef("ISynced", self.SetSyncedStateData, self.I_REQUIRED_FUNC, "SetSyncedStateData", "Called when new state is recieved")
	self:AddFuncDef("ISynced", self.GetSyncedStateData, self.I_REQUIRED_FUNC, "GetSyncedStateData", "Called to collect the current state of the object")
	self:AddFuncDef("ISynced", self.ProcessSyncedObject, self.I_REQUIRED_FUNC, "ProcessSyncedObject", "Called to give processing time to the object")
	self:AddFuncDef("ISynced", self.BuildInterfaceDefISynced, self.I_REQUIRED_FUNC, "BuildInterfaceDefISynced", "The child class must build their interface in this function")

	self:BuildInterfaceDefISynced()

end


function ISynced:SetStateData(stateBuiltTime, setState)

	self:SetSyncedStateData(stateBuiltTime, setState)

end


function ISynced:GetStateData(returnState)

	self:GetSyncedStateData(returnState)

end


function ISynced:GetActive()

	return self:GetSyncedActive()

end


function ISynced:ProcessScriptObject(frameTime)

	if IsServer() and IsValid(self.scriptObject) then
		self.scriptObject:SetActive(self:GetActive())
	end

	self:ProcessSyncedObject(frameTime)

end