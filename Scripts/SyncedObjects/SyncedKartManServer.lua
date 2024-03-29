
UseModule("IKart", "Scripts/")

--SYNCEDKARTMANSERVER CLASS START

class 'SyncedKartManServer' (IKart)

function SyncedKartManServer:__init(setKartObjectServer) super()

	if (not IsValid(setKartObjectServer)) then
		error("Invalid params passed into SyncedKartManServer:__init()")
	end

	--The server kart is a BulletVehicle
	self.kartObjectServer = setKartObjectServer

	--Values needed for wheel friction
	self.wheelsFrictionMod = 1
	self.frictionLossTime = 0.3
	self.frictionGainTime = 0.8

	self.anyWheelInContact = false
	self.allWheelsInContact = false
	self.allWheelsNotInContact = false
	
	self.hopKeyDown = false

end


function SyncedKartManServer:SetWheelFrictionTime(setLossTime, setGainTime)

	self.frictionLossTime = setLossTime
	self.frictionGainTime = setGainTime

end


function SyncedKartManServer:GetName()

	return self.kartObjectServer:GetName()

end


function SyncedKartManServer:Reset()

	self.kartObjectServer:Reset()

end


function SyncedKartManServer:SetEnableControls(enable)

	self.kartObjectServer:SetEnableControls(enable)

end


function SyncedKartManServer:GetEnableControls()

	return self.kartObjectServer:GetEnableControls()

end


function SyncedKartManServer:GetAnyWheelInContact()

	return self.anyWheelInContact

end


function SyncedKartManServer:GetAllWheelsInContact()

	return self.allWheelsInContact

end


function SyncedKartManServer:GetAllWheelsNotInContact()

    return self.allWheelsNotInContact

end


function SyncedKartManServer:GetObject()

	return self.kartObjectServer

end


function SyncedKartManServer:GetPosition()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetPosition()
	end

	return WVector3()

end


function SyncedKartManServer:GetOrientation()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetOrientation()
	end

	return WQuaternion()

end


function SyncedKartManServer:GetGravity()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetGravity()
	end

	return WVector3()

end


function SyncedKartManServer:DoesOwn(ownObjectID)

	if (IsValid(self.kartObjectServer) and ownObjectID == self.kartObjectServer:GetID()) then
		return true
	end

	return false

end


function SyncedKartManServer:Process(frameTime)

	self.kartObjectServer:Process(frameTime)

	--Check if the back wheels are in contact with something
	local leftBackInContact = self.kartObjectServer:GetWheelInContact(WheelID.LEFT_BACK_WHEEL)
	local rightBackInContact = self.kartObjectServer:GetWheelInContact(WheelID.RIGHT_BACK_WHEEL)
	local leftFrontInContact = self.kartObjectServer:GetWheelInContact(WheelID.LEFT_FRONT_WHEEL)
	local rightFrontInContact = self.kartObjectServer:GetWheelInContact(WheelID.RIGHT_FRONT_WHEEL)
	self.anyWheelInContact = leftBackInContact or rightBackInContact or leftFrontInContact or rightFrontInContact
	self.allWheelsInContact = leftBackInContact and rightBackInContact and leftFrontInContact and rightFrontInContact
	self.allWheelsNotInContact = (not leftBackInContact) and (not rightBackInContact) and (not leftFrontInContact) and (not rightFrontInContact)

	--When no wheels are touching, remove all friction
	if not self.allWheelsInContact then
		self.wheelsFrictionMod = self.wheelsFrictionMod - ((1 / self.frictionLossTime) * frameTime)
	--When all wheels are touching, add friction back over time
	elseif self.allWheelsInContact then
	    --if self.hopKeyDown then
	    --    self.wheelsFrictionMod = -0.75
        --else
		    self.wheelsFrictionMod = self.wheelsFrictionMod + ((1 / self.frictionGainTime) * frameTime)
	    --end
	end
	--If less than all wheels are touching, the friction doesn't change

	self.wheelsFrictionMod = Clamp(self.wheelsFrictionMod, 0, 1)

	self.kartObjectServer:SetWheelFrictionModifier(WheelID.LEFT_BACK_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(WheelID.RIGHT_BACK_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(WheelID.LEFT_FRONT_WHEEL, self.wheelsFrictionMod)
	self.kartObjectServer:SetWheelFrictionModifier(WheelID.RIGHT_FRONT_WHEEL, self.wheelsFrictionMod)

    --print("Friction: "..self.kartObjectServer:GetWheelFriction())

end

--SYNCEDKARTMANSERVER CLASS END