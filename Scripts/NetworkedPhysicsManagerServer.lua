--BRIAN TODO: Not used, remove

UseModule("IBase", "Scripts/")

--NETWORKEDPHYSICSMANAGERSERVER CLASS START

--This class is responsible for 
class 'NetworkedPhysicsManagerServer' (IBase)

function NetworkedPhysicsManagerServer:__init() super()

	self.processSlot = self:CreateSlot("Process", "Process")
	--Process right before the network system processes
	--so that we can make sure the state gets sent out right away
	GetServerSystem():GetSignal("ProcessBegin", true):Connect(self.processSlot)

end


function NetworkedPhysicsManagerServer:UnInitImp()

end


function NetworkedPhysicsManagerServer:Process()

end