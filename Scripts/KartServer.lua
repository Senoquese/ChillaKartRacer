
UseModule("IKart", "Scripts/")

--KARTSERVER CLASS START

class 'KartServer' (IKart)

function KartServer:__init(setKartObjectServer, setKartObjectClient) super()

	if (not IsValid(setKartObjectServer)) or (not IsValid(setKartObjectClient)) then
		error("Invalid params passed into KartServer:__init()")
	end

	--The server kart is a BulletVehicle
	self.kartObjectServer = setKartObjectServer
	--The client kart is a MapObject
	self.kartObjectClient = setKartObjectClient

	--Grab some processing time
	self.processSlot = self:CreateSlot("Process", "Process")
	--We need to process after the kart object has processed
	self.kartObjectServer:GetSignal("ProcessBegin", true):Connect(self.processSlot)

	--Values needed for wheel friction
	self.wheelsFrictionMod = 1
	self.frictionTime = 0.15

	self.anyWheelInContact = false
	self.allWheelsInContact = false

end


function KartServer:UnInitImp()

	IKart.UnInitImp(self)

end


function KartServer:GetName()

	return self.kartObjectServer:GetName()

end


function KartServer:Reset()

	self.kartObjectServer:Reset()

end


function KartServer:SetEnableControls(enable)

	self.kartObjectServer:SetEnableControls(enable)

end


function KartServer:GetEnableControls(enable)

	return self.kartObjectServer:GetEnableControls()

end


function KartServer:GetAnyWheelInContact()

	return self.anyWheelInContact

end


function KartServer:GetAllWheelsInContact()

	return self.allWheelsInContact

end


function KartServer:GetObject()

	return self.kartObjectServer

end


function KartServer:GetPosition()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetPosition()
	end

	return WVector3()

end


function KartServer:GetOrientation()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetOrientation()
	end

	return WQuaternion()

end


function KartServer:GetGravity()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetGravity()
	end

	return WVector3()

end


function KartServer:GetClientObject()

	return self.kartObjectClient

end


function KartServer:DoesOwn(ownObject)

	local ownObjectName = ""
	if type(ownObject) == "string" then
		ownObjectName = ownObject
	else
		ownObjectName = ownObject:GetName()
	end

	if (IsValid(self.kartObjectServer) and ownObjectName == self.kartObjectServer:GetName()) or
	   (IsValid(self.kartObjectClient) and ownObjectName == self.kartObjectClient:GetName()) then
		return true
	end

	return false

end


function KartServer:RemoveOwnedObject(object)

	local ownObjectName = ""
	if type(object) == "string" then
		ownObjectName = object
	else
		ownObjectName = object:GetName()
	end

	if (IsValid(self.kartObjectServer) and ownObjectName == self.kartObjectServer:GetName()) then
		self.kartObjectServer = nil
	end
	if (IsValid(self.kartObjectClient) and ownObjectName == self.kartObjectClient:GetName()) then
		self.kartObjectClient = nil
	end

end


function KartServer:Process()

	local timeDiff = GetFrameTime()

	--Check if the back wheels are in contact with something
	local leftBackInContact = self.kartObjectServer:GetWheelInContact(BulletVehicle.LEFT_BACK_WHEEL)
	local rightBackInContact = self.kartObjectServer:GetWheelInContact(BulletVehicle.RIGHT_BACK_WHEEL)
	local leftFrontInContact = self.kartObjectServer:GetWheelInContact(BulletVehicle.LEFT_FRONT_WHEEL)
	local rightFrontInContact = self.kartObjectServer:GetWheelInContact(BulletVehicle.RIGHT_FRONT_WHEEL)
	self.anyWheelInContact = leftBackInContact or rightBackInContact or leftFrontInContact or rightFrontInContact
	self.allWheelsInContact = leftBackInContact and rightBackInContact and leftFrontInContact and rightFrontInContact

	--When no wheels are touching, remove all friction
	if not self.allWheelsInContact then
		self.wheelsFrictionMod = 0
	--When all wheels are touching, add friction back over time
	elseif self.allWheelsInContact then
		self.wheelsFrictionMod = self.wheelsFrictionMod + ((1 / self.frictionTime) * timeDiff)
	end
	--If less than all wheels are touching, the friction stays at 0

	self.wheelsFrictionMod = Clamp(self.wheelsFrictionMod, 0, 1)

	self.kartObjectServer:SetWheelFrictionModifier(BulletVehicle.LEFT_BACK_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(BulletVehicle.RIGHT_BACK_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(BulletVehicle.LEFT_FRONT_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(BulletVehicle.RIGHT_FRONT_WHEEL, self.wheelsFrictionMod)

end

--KARTSERVER CLASS END