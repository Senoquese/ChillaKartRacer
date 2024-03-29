UseModule("IBase", "Scripts/")

--PERSISTENTSIGNALWRAPPER CLASS START

--This wrapper ensures the persistent signal gets removed from the network system
class 'PersistentSignalWrapper' (IBase)

function PersistentSignalWrapper:__init(setPersistentSignal, setNetworkSystem) super()

	self.networkSystemUnInitSlot = self:CreateSlot("NetworkUnInit", "NetworkUnInit")

	self.persistentSignal = setPersistentSignal
	self.networkSystem = setNetworkSystem

	if IsValid(self.networkSystem) then
		self.networkSystem:GetSignal("UnInitBegin", true):Connect(self.networkSystemUnInitSlot)
	end

end


function PersistentSignalWrapper:BuildInterfaceDefIBase()

	self:AddClassDef("PersistentSignalWrapper", "IBase", "Wraps a signal that emits over the network")

end


function PersistentSignalWrapper:InitIBase()

end


function PersistentSignalWrapper:UnInitIBase()

	if IsValid(self.persistentSignal) and IsValid(self.networkSystem) then
		self.networkSystem:RemovePersistentSignal(self.persistentSignal)
	end

	self:NetworkUnInit()

end


function PersistentSignalWrapper:NetworkUnInit()

	self.persistentSignal = nil
	self.networkSystem = nil

end

--PERSISTENTSIGNALWRAPPER CLASS END