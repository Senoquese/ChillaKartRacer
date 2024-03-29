UseModule("IBase", "Scripts/")

--PERSISTENTSLOTWRAPPER CLASS START

--This wrapper ensures the persistent slot gets removed from the network system
class 'PersistentSlotWrapper' (IBase)

function PersistentSlotWrapper:__init(setPersistentSlot, setNetworkSystem) super()

	self.networkSystemUnInitSlot = self:CreateSlot("NetworkUnInit", "NetworkUnInit")

	self.persistentSlot = setPersistentSlot
	self.networkSystem = setNetworkSystem

	if IsValid(self.networkSystem) then
		self.networkSystem:GetSignal("UnInitBegin", true):Connect(self.networkSystemUnInitSlot)
	end

end


function PersistentSlotWrapper:BuildInterfaceDefIBase()

	self:AddClassDef("PersistentSlotWrapper", "IBase", "Wraps a slot that gets emitted to over the network")

end


function PersistentSlotWrapper:InitIBase()

end


function PersistentSlotWrapper:UnInitIBase()

	if IsValid(self.persistentSlot) and IsValid(self.networkSystem) then
		self.networkSystem:RemovePersistentSlot(self.persistentSlot)
	end

	self:NetworkUnInit()

end


function PersistentSlotWrapper:NetworkUnInit()

	self.persistentSlot = nil
	self.networkSystem = nil

end

--PERSISTENTSLOTWRAPPER CLASS END