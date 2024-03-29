UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")

local ICE_PLAYER_FORCE = 5000

local ICE_UP_FORCE = 500

local ICE_SYNC_TIME = 0.05

local ICE_SYNC_DISTANCE = 0.01

--SYNCEDGreenShell CLASS START

--SyncedGreenShell
class 'SyncedGreenShell' (ISyncedWeapon)

function SyncedGreenShell:__init() super()
	self.graphicalCube = nil
	self.physicalCube = nil

	self.cubeHitAnim = nil

	self.collisionSlot = self:CreateSlot("GreenShellCollision", "GreenShellCollision")

	self.detachClock = WTimer()
	self.detachTimer = 30

    self.damageSelfPreventionTimer = WTimer(1)

	self.ICS_NOT_USED = 0
	self.ICS_DETACHED = 1
	self.ICS_DROPPED = 4
	self.ICS_KILL_WEAPON = 3
	self.state = self.ICS_NOT_USED
	self.stateParam = Parameter();

end

function SyncedGreenShell:BuildInterfaceDefISynced()
	self:AddClassDef("SyncedGreenShell", "ISyncedWeapon", "")
end

function SyncedGreenShell:InitWeapon()
	if IsClient() then
		self.stateSlot = self:CreateSlot("SetICState", "SetICState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("GreenShellState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("GreenShellState_" .. tostring(self:GetID()))
		self:SetICState(self.state)
	end
end

function SyncedGreenShell:UnInitWeapon()
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("GreenShellState_" .. tostring(self:GetID()))
	end
	if IsClient() then
		self:UnInitGraphical()
	end
	self:UnInitPhysical()

end

function SyncedGreenShell:InitGraphical()
	self.graphicalCube = OGREModel()
	self.graphicalCube:SetName(self.name .. "G")
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "IceCube.mesh"))
	self.graphicalCube:Init(params)
	self.graphicalCube:SetPosition(self.physicalCube:GetPosition())
	self.graphicalCube:SetScale(WVector3(1, 1, 1))
	self.graphicalCube:SetCastShadows(true)
	self.graphicalCube:SetReceiveShadows(true)
	self.graphicalCube:SetVisible(false)
end

function SyncedGreenShell:UnInitGraphical()
	if IsValid(self.graphicalCube) then
		self.graphicalCube:UnInit()
		self.graphicalCube = nil
	end
end

function SyncedGreenShell:InitPhysical(detachBehind)
	self.physicalCube = BulletBox()
	self.physicalCube:SetName(self.name)
	local params = Parameters()
	local detachPos = WVector3()
	local forwardQuat = WQuaternion()
    if IsValid(self:GetOwner()) then
        detachPos = WVector3(self:GetOwner():GetPosition())
        forwardQuat = WQuaternion(self:GetOwner():GetOrientation())
    end

	local forwardNormal = self.aimNormal
    if detachBehind then
        forwardNormal = forwardQuat:zAxis()
    end
    if detachBehind then
		detachPos = detachPos - (forwardNormal * 3)
	else
		detachPos = detachPos + (forwardNormal * 3.25)
	end
	detachPos.y = detachPos.y + 1
	params:AddParameter(Parameter("PositionX", detachPos.x))
	params:AddParameter(Parameter("PositionY", detachPos.y))
	params:AddParameter(Parameter("PositionZ", detachPos.z))
	params:AddParameter(Parameter("Dimensions", WVector3(2, 2, 2)))
	params:AddParameter(Parameter("Friction", 0))
	params:AddParameter(Parameter("Restitution", 0))
	params:AddParameter(Parameter("LinearDamping", 0.5))
	params:AddParameter(Parameter("AngularDamping", 0.5))
	params:AddParameter(Parameter("Mass", 100))
	self.physicalCube:Init(params)
	self.physicalCube:SetLinearDamping(0.5)
	self.physicalCube:SetAngularDamping(0.5)

	if IsServer() then
		self.physicalCube:GetSignal("StartCollision", true):Connect(self.collisionSlot)
	end

	self.damageSelfPreventionTimer:Reset()
end

function SyncedGreenShell:UnInitPhysical()
	if IsValid(self.physicalCube) then
		self.physicalCube:UnInit()
		self.physicalCube = nil
	end
end

function SyncedGreenShell:SetICState(newState)
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
		if self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
			self:InitPhysical(true)
			self:InitGraphical()
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			local sound = "sound/Throw.wav"
			if self.state == self.ICS_DROPPED then
			    sound = "sound/Ice_Block_Drop.wav"
			end
			GetSoundSystem():EmitSound(ASSET_DIR .. sound, throwPos, 7, 1, true, SoundSystem.MEDIUM)
		elseif self.state == self.ICS_KILL_WEAPON then
			self:UnInitPhysical()       
		end
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("GreenShellState_" .. tostring(self:GetID()), self.stateParam)
	end

    if self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
		self.detachClock:Reset()
		self:SetWeaponUsed()
	elseif self.state == self.ICS_KILL_WEAPON then
		self:UnInitPhysical()
		if IsClient() then
            if IsValid(self.graphicalCube) then
                GetParticleSystem():AddEffect("icehit", self.graphicalCube:GetPosition())
                GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poofw.wav", self.graphicalCube:GetPosition(), 1, 3, true, SoundSystem.MEDIUM)
            end
		end
		self:SetWeaponDead()
	end
end

function SyncedGreenShell:DoesWeaponOwn(ownObjectID)
	if self.physicalCube:GetID() == ownObjectID then
		return true
	end
	if IsClient() then
		if self.graphicalCube:GetID() == ownObjectID then
			return true
		end
	end

	return false
end

function SyncedGreenShell:NotifyPositionChange(setPos)
	if IsValid(self.graphicalCube) and then
		self.graphicalCube:SetPosition(setPos)
        if not self.graphicalCube:GetVisible() then
            self.graphicalCube:SetVisible(true)
        end
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:SetPosition(setPos)
	end
end

function SyncedGreenShell:NotifyOrientationChange(setOrien)
	if IsValid(self.graphicalCube) then
		self.graphicalCube:SetOrientation(setOrien)
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:SetOrientation(setOrien)
	end
end

function SyncedGreenShell:GetPosition()
	if IsClient() then
		return self.graphicalCube:GetPosition()
	end
	return self.physicalCube:GetPosition()

end

function SyncedGreenShell:GetOrientation()
	if IsClient() then
		return self.graphicalCube:GetOrientation()
	end
	return self.physicalCube:GetOrientation()

end

function SyncedGreenShell:GetWeaponActive()
    if IsValid(self.physicalCube) then
	    return not self.physicalCube:GetSleeping()
	end
	return false

end

function SyncedGreenShell:SetWeaponStateData(stateBuiltTime, setState)
	local pos = setState:ReadWVector3()
	local orien = setState:ReadWQuaternion()

	if IsValid(self.physicalCube) then
		self.physicalCube:SetPosition(pos)
		self.physicalCube:SetOrientation(orien)
	end

	self:SetPosition(pos, false)
	self:SetOrientation(orien, false)

end

function SyncedGreenShell:GetWeaponStateData(returnState)
	if IsValid(self.physicalCube) then
		returnState:WriteWVector3(self.physicalCube:GetPosition())
		returnState:WriteWQuaternion(self.physicalCube:GetOrientation())
	end
end

function SyncedGreenShell:UseItemUp(pressed, extraData)
	if IsServer() and self.state == self.ICS_NOT_USED then
		if pressed then
			self:Throw()
		end
	end
end

function SyncedGreenShell:UseItemDown(pressed, extraData)
	if IsServer() and self.state == self.ICS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end
end

function SyncedGreenShell:SetWeaponParameter(param)
end

function SyncedGreenShell:EnumerateWeaponParameters(params)
end

function SyncedGreenShell:ProcessSyncedObject(frameTime)
	if self.state == self.ICS_NOT_USED then
	elseif self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
		self:ProcessDetached(frameTime)
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:Process(frameTime)
		self:SetPosition(self.physicalCube:GetPosition(), false)
        self:SetOrientation(self.physicalCube:GetOrientation(), false)
        self:SetLinearVelocity(self.physicalCube:GetLinearVelocity(), false)
	end

	if IsValid(self.graphicalCube) then	
		self.graphicalCube:Process(frameTime)
	end
end

function SyncedGreenShell:ProcessDetached(frameTime)
	if IsServer() then
	    if self.detachClock:GetTimeSeconds() < 0.5 then
            local guideForce = self:GetGuideForce(self.physicalCube:GetPosition(), self.physicalCube:GetLinearVelocity(), 30, 50.0, frameTime)
            if IsValid(guideForce) then
                self.physicalCube:ApplyWorldImpulse(guideForce, WVector3())
            end
        end
      	if self.detachClock:GetTimeSeconds() > self.detachTimer then
			self:KillWeapon()
		end
	end
end

function SyncedIceCube:KillWeapon()
	self:SetICState(self.ICS_KILL_WEAPON)
end

function SyncedGreenShell:Detach()
	if self.state == self.ICS_NOT_USED then
		self:SetICState(self.ICS_DROPPED)
		self:InitPhysical(true)
	end
end

function SyncedGreenShell:Throw()
	if self.state == self.ICS_NOT_USED then
		self:SetICState(self.ICS_DETACHED)
		
		self:InitPhysical(false)
		self.physicalCube:SetLinearVelocity(self:GetOwner():GetLinearVelocity())
		local forwardNormal = self.aimNormal
        local force = forwardNormal * ICE_PLAYER_FORCE
		force = force + WVector3(0, ICE_UP_FORCE, 0)
		self.physicalCube:ApplyWorldImpulse(force, WVector3())
	end
end

function SyncedGreenShell:HitPlayer(player)
	self:SetICState(self.ICS_KILL_WEAPON)
	local HitPlayerID = 0
	if IsValid(player) then
		HitPlayerID = player:GetUniqueID()
		self.HitPlayer = player
	end
end

function SyncedGreenShell:GreenShellCollision(collisionParams)
	if self.state ~= self.ICS_DETACHED and self.state ~= self.ICS_DROPPED  then
		return
	end

	local emitColl = false

	local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)

	if IsValid(hitPlayer) and
       (self.damageSelfPreventionTimer:IsTimerUp() or hitPlayer:GetUniqueID() ~= self:GetOwner():GetUniqueID()) then
		emitColl = true
	end

	if emitColl then
		print("Player " .. hitPlayer:GetName() .. " hit green shell with ID " .. tostring(self:GetID()))
		self:HitPlayer(hitPlayer)
	end
end