UseModule("IBase", "Scripts/")

--IKART CLASS START

--BRIAN TODO: Is this needed anymore? don't think so...
class 'IKart' (IBase)

function IKart:__init() super()

end


function IKart:BuildInterfaceDefIBase()

	self:AddClassDef("IKart", "IBase", "The interface for a kart object")

end


function IKart:InitIBase()

end


function IKart:UnInitIBase()

end


function IKart:GetName()

	return "NoName"

end


function IKart:GetObject()

	return nil

end


function IKart:GetPosition()

	return WVector3()

end


function IKart:GetOrientation()

	return WQuaternion()

end


function IKart:DoesOwn(ownObject)

	return false

end

--IKART CLASS END