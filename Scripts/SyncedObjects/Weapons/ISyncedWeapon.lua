UseModule("ISynced", "Scripts/SyncedObjects/")

--ISYNCEDWEAPON CLASS START

--All ISyncedWeapons must implement the following functions:
--InitWeapon()
--UnInitWeapon()
--DoesWeaponOwn(objectName)
--UseItemUp(pressed)
--UseItemDown(pressed)
--PlayerInvalid() - Called when the owner player of this weapon leaves the server or is otherwise no longer valid to reference
--GetWeaponActive()
--SetWeaponStateData()
--GetWeaponStateData()

--A ISyncedWeapon must also call SetWeaponDead() when the weapon is done being used
--and should be removed from the world.

--Signals:
--WeaponUsed - When this weapon has been used by the player and
--the player no longer has control over it, the player can then pick up or use another weapon.
--Note, the weapon might still be active even after it has been used (a mine on the field stays
--on the field for a period of time).

class 'ISyncedWeapon' (ISynced)

function ISyncedWeapon:__init(maxGuideRadius) super()

	self.name = "DefaultISyncedWeaponName"
	self.ID = 0
	self.ownerID = 0
	self.weaponDead = false
    self.aimNormal = WVector3()
    self.aimDotMin = 0.75
    
    self.defaultMaxGuideRadius = 100
    if IsValid(maxGuideRadius) then
	    self.maxGuideRadius = maxGuideRadius
	else
	    self.maxGuideRadius = self.defaultMaxGuideRadius
	end
    self.defaultGuideStrength = 0.5
    self.defaultGuideRadius = 30
    
    self.guideSensor = BulletSensor()
	self.guideSensor:SetName(self.name .. "guideSensor")
	local params = Parameters()
	params:AddParameter(Parameter("Shape", "Sphere"))
	params:AddParameter(Parameter("Dimensions", WVector3(self.maxGuideRadius, self.maxGuideRadius, self.maxGuideRadius)))
	self.guideSensor:Init(params)

	self.weaponUsedSignal = self:CreateSignal("WeaponUsed")
	self.weaponParams = Parameters()

end


function ISyncedWeapon:BuildInterfaceDefISynced()

	self:AddClassDef("ISyncedWeapon", "ISynced", "An ISyncedWeapon object is any weapon that can be used by a player")
	self:AddFuncDef("ISyncedWeapon", self.InitWeapon, self.I_REQUIRED_FUNC, "InitWeapon", "")
	self:AddFuncDef("ISyncedWeapon", self.UnInitWeapon, self.I_REQUIRED_FUNC, "UnInitWeapon", "")
	self:AddFuncDef("ISyncedWeapon", self.DoesWeaponOwn, self.I_REQUIRED_FUNC, "DoesWeaponOwn", "")
	self:AddFuncDef("ISyncedWeapon", self.UseItemUp, self.I_REQUIRED_FUNC, "UseItemUp", "")
	self:AddFuncDef("ISyncedWeapon", self.UseItemDown, self.I_REQUIRED_FUNC, "UseItemDown", "")
	self:AddFuncDef("ISyncedWeapon", self.PlayerInvalid, self.I_REQUIRED_FUNC, "PlayerInvalid", "")
	self:AddFuncDef("ISyncedWeapon", self.GetWeaponActive, self.I_REQUIRED_FUNC, "GetWeaponActive", "")
	self:AddFuncDef("ISyncedWeapon", self.SetWeaponStateData, self.I_REQUIRED_FUNC, "SetWeaponStateData", "")
	self:AddFuncDef("ISyncedWeapon", self.GetWeaponStateData, self.I_REQUIRED_FUNC, "GetWeaponStateData", "")
	self:AddFuncDef("ISyncedWeapon", self.BuildInterfaceDefISyncedWeapon, self.I_REQUIRED_FUNC, "BuildInterfaceDefISynced", "")

	self:BuildInterfaceDefISyncedWeapon()

end


function ISyncedWeapon:SetName(setName)

	self.name = setName

end


function ISyncedWeapon:GetName()

	return self.name

end


function ISyncedWeapon:SetID(setID)

	self.ID = setID

end


function ISyncedWeapon:GetID()

	return self.ID

end


function ISyncedWeapon:GetServerID()

	return GetClientWorld():GetServerObjectID(self:GetID())

end


function ISyncedWeapon:GetOwner()

	return GetPlayerManager():GetPlayerFromID(self.ownerID)

end


function ISyncedWeapon:InitIBase()

	self:InitWeapon()

end


function ISyncedWeapon:UnInitIBase()

	self:UnInitWeapon()

end


function ISyncedWeapon:DoesOwn(ownObjectID)

	return self:DoesWeaponOwn(ownObjectID)

end


--Any weapon owned by somebody will receive input events
--and can act upon them in any way.
function ISyncedWeapon:KeyEvent(keyID, pressed, extraData)

	if IsValid(extraData) then
		self.aimNormal = extraData:GetWVector3Data()
	end

	local inputName = GetNetworkedWorld():GetInputName(keyID)
	if inputName == "UseItemUp" then
		self:UseItemUp(pressed, extraData)
	elseif inputName == "UseItemDown" then
		self:UseItemDown(pressed, extraData)
	end

end


function ISyncedWeapon:GetGuideForce(position, linVel, radius, strength, frameTime)

    if not IsValid(position) or not IsValid(linVel) then
        return nil
    end
    if not IsValid(strength) then
        strength = self.defaultGuideStrength
    end
    if not IsValid(radius) or radius > self.maxGuideRadius then
        radius = self.defaultGuideRadius
    end
    if radius <= 0 then
        return
    end
    
    local targetPos = self:GetClosestPlayer(position, radius, linVel, frameTime)
    
    if IsValid(targetPos) then
        local guideForce = targetPos - position
        guideForce:Normalise()
        linVel:Normalise()
        guideForce = guideForce - linVel
        guideForce = guideForce * strength
        return guideForce
    end
    
    return nil
end


function ISyncedWeapon:GetClosestPlayer(position, radius, linVel, frameTime)

	local minDist = radius
	local minPos = nil
	
	self.guideSensor:SetPosition(position)
	self.guideSensor:Process(frameTime)
	local iter = self.guideSensor:GetIterator()
	while not iter:IsEnd() do
		local currentObject = iter:Get()
		
		-- make sure currentObject is not owned by this weapon's owner
        if not IsValid(self:GetOwner()) or not self:GetOwner():DoesOwn(currentObject:GetID()) then
            -- make sure currentObject is a player's kart
            local objOwner = GetPlayerManager():GetPlayerFromObjectID(currentObject:GetID())
            if IsValid(objOwner) then
                local PtoT = currentObject:GetPosition()-self.guideSensor:GetPosition()
                local distance = PtoT:Length()
                PtoT:Normalise()
                linVel:Normalise()
                --print("PtoT:"..tostring(PtoT).." RlvNorm:"..tostring(RlvNorm))
                local aimDot = (PtoT:DotProduct(linVel))
                --print("aimDot:"..aimDot)
                if distance <= minDist and aimDot >= self.aimDotMin then
                    minPos = currentObject:GetPosition()
                end
            end
        end
		iter:Next()
	end

	return minPos

end


function ISyncedWeapon:SetParameter(param)

	if param:GetName() == "OwnerID" then
		self.ownerID = param:GetIntData()
	else
		self:SetWeaponParameter(param)
	end

end


function ISyncedWeapon:EnumerateParameters(params)

	params:AddParameter(Parameter("OwnerID", Parameter.INT, self.ownerID))
	self:EnumerateWeaponParameters(params)

end


--DO NOT CALL! The weapon system calls this when the owner of this weapon is invalid.
function ISyncedWeapon:_PlayerInvalid(player)

	--Check if it is our owner
	if player:GetUniqueID() == self.ownerID then
		self.ownerID = 0
	end

	if IsValid(self.PlayerInvalid) then
		self:PlayerInvalid(player)
	end

end


function ISyncedWeapon:SetWeaponUsed()

	self.weaponParams:GetOrCreateParameter("ID"):SetIntData(self.ID)
	self.weaponUsedSignal:Emit(self.weaponParams)

end


--Call SetWeaponDead() when the weapon is done being used
--and should be removed from the world.
function ISyncedWeapon:SetWeaponDead()

	self.weaponDead = true

end


function ISyncedWeapon:GetWeaponDead()

	return self.weaponDead

end


function ISyncedWeapon:GetSyncedActive()

	return self:GetWeaponActive()

end


function ISyncedWeapon:SetSyncedStateData(stateBuiltTime, setState)

	self:SetWeaponStateData(stateBuiltTime, setState)

end


function ISyncedWeapon:GetSyncedStateData(returnState)

	self:GetWeaponStateData(returnState)

end

--ISYNCEDWEAPON CLASS END