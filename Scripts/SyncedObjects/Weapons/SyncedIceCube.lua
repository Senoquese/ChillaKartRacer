UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")

local ICE_PLAYER_FORCE = 5000

local ICE_UP_FORCE = 500

local ICE_SYNC_TIME = 0.05

local ICE_SYNC_DISTANCE = 0.01

--SYNCEDICECUBE CLASS START

--SyncedIceCube
class 'SyncedIceCube' (ISyncedWeapon)

function SyncedIceCube:__init() super()

	self.graphicalCube = nil
	self.physicalCube = nil

	self.cubeMeltAnim = nil
	self.cubeHitAnim = nil

	--Called when something collides with the ice cube
	self.collisionSlot = self:CreateSlot("IceCubeCollision", "IceCubeCollision")

	self.detachClock = WTimer()
	--detachTimer is how long the ice cube will last on it's own
	self.detachTimer = 30

	self.meltClock = WTimer()
	--meltTimer is how long the ice cube will last once a player is trapped in it
	self.meltTimer = 6

    self.idealScale = WVector3(2, 2, 2)
	self.startScale = false
	self.scaleClock = WTimer()
    self.endScaleTime = 0.2

    --This is to make sure the player can't ice themselves for a period of time after
    --throwing the cube
    self.iceSelfPreventionTimer = WTimer(1)

	--Not used yet
	self.ICS_NOT_USED = 0
	--Used once, detached
	self.ICS_DETACHED = 1
	self.ICS_DROPPED = 4
	--Start melting
	self.ICS_START_MELT = 2
	--Done melting
	self.ICS_DONE_MELT = 3
	self.state = self.ICS_NOT_USED
	self.stateParam = Parameter();

end


function SyncedIceCube:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedIceCube", "ISyncedWeapon", "")

end


function SyncedIceCube:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetICState", "SetICState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("IceCubeState_" .. tostring(self:GetServerID()), self.stateSlot)
		self.icedPlayerSlot = self:CreateSlot("SetIcedPlayer", "SetIcedPlayer")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("IcedPlayer_" .. tostring(self:GetServerID()), self.icedPlayerSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("IceCubeState_" .. tostring(self:GetID()))
		self:SetICState(self.state)
		GetServerSystem():GetSendStateTable("Map"):NewState("IcedPlayer_" .. tostring(self:GetID()))
		self.stateParam:SetIntData(0)
		GetServerSystem():GetSendStateTable("Map"):SetState("IcedPlayer_" .. tostring(self:GetID()), self.stateParam)
	end

end


function SyncedIceCube:UnInitWeapon()

	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("IceCubeState_" .. tostring(self:GetID()))
		GetServerSystem():GetSendStateTable("Map"):RemoveState("IcedPlayer_" .. tostring(self:GetID()))
	end

    if IsValid(self.icedPlayer) then
		--Mark this player as not iced so he can be iced again
		self.icedPlayer.userData.iced = false
		if self.icedPlayer:GetControllerValid() then
			self.icedPlayer:GetController():SetWheelFriction(self.savedWheelFriction)
		end
		self.icedPlayer = nil
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedIceCube:InitGraphical()

	self.graphicalCube = OGREModel()
	self.graphicalCube:SetName(self.name .. "G")
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "icecube.mesh"))
	self.graphicalCube:Init(params)
	self.graphicalCube:SetPosition(self.physicalCube:GetPosition())
	self.graphicalCube:SetScale(WVector3(0, 0, 0))
	self.graphicalCube:SetCastShadows(true)
	self.graphicalCube:SetReceiveShadows(false)
	self.graphicalCube:SetVisible(false)

    self.cubeMeltAnim = self.graphicalCube:GetAnimation("melt", true)
	self.cubeMeltAnim:SetLooping(false)
	self.cubeMeltAnim:SetSpeed(0.07)
	self.cubeHitAnim = self.graphicalCube:GetAnimation("hit", true)
	self.cubeHitAnim:SetLooping(false)
end


function SyncedIceCube:UnInitGraphical()

	--First, unfreeze the current player if there is one
	self:DetachCubeFromCurrentPlayer()

	if IsValid(self.graphicalCube) then
		self.graphicalCube:UnInit()
		self.graphicalCube = nil
	end

end


function SyncedIceCube:InitPhysical(detachBehind)

	--The physical entity
	self.physicalCube = BulletBox()
	self.physicalCube:SetName(self.name)
	local params = Parameters()
	local detachPos = WVector3()
	local forwardQuat = WQuaternion()
    if IsValid(self:GetOwner()) then
        detachPos = WVector3(self:GetOwner():GetPosition())
        forwardQuat = WQuaternion(self:GetOwner():GetOrientation())
    end

	--local forwardNormal = forwardQuat:zAxis()
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
	--params:AddParameter(Parameter("Dimensions", WVector3(1.5, 1.5, 1.5)))
	params:AddParameter(Parameter("Dimensions", WVector3(2, 2, 2)))
	params:AddParameter(Parameter("Friction", 0))
	params:AddParameter(Parameter("Restitution", 0))
	params:AddParameter(Parameter("LinearDamping", 0.5))
	params:AddParameter(Parameter("AngularDamping", 0.5))
	params:AddParameter(Parameter("Mass", 100))
	self.physicalCube:Init(params)
	self.physicalCube:SetLinearDamping(0.5)
	self.physicalCube:SetAngularDamping(0.5)
	--Only the server should deal with collisions
	if IsServer() then
		self.physicalCube:GetSignal("StartCollision", true):Connect(self.collisionSlot)
	end

    --Make sure the owner doesn't ice themselves for a period of time
	self.iceSelfPreventionTimer:Reset()

end


function SyncedIceCube:UnInitPhysical()

	if IsValid(self.physicalCube) then
		self.physicalCube:UnInit()
		self.physicalCube = nil
	end

end


function SyncedIceCube:SetICState(newState)

	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
		if self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
			self:InitPhysical(true)
			self:InitGraphical()
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			--Play throw sound
			local sound = "sound/Throw.wav"
			if self.state == self.ICS_DROPPED then
			    sound = "sound/Ice_Block_Drop.wav"
			end
			GetSoundSystem():EmitSound(ASSET_DIR .. sound, throwPos, 7, 1, true, SoundSystem.MEDIUM)
		elseif self.state == self.ICS_START_MELT then
			--No more physical cube once the melt has started
			--print("STARTING MELT ANIMATION!!!")
			--self.cubeMeltAnim:Play()
			self:UnInitPhysical()       
		end
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("IceCubeState_" .. tostring(self:GetID()), self.stateParam)
	end
        if self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
			self.detachClock:Reset()
			--The player no longer has control over this item once it is detached
			self:SetWeaponUsed()
		elseif self.state == self.ICS_START_MELT then
			--No more physical cube once the melt has started
			self:UnInitPhysical()
			self.meltClock:Reset()
		elseif self.state == self.ICS_DONE_MELT then
			--When the ice melts, the weapon is dead
			if IsClient() then
			    --print("DONE MELTING")
	            if IsValid(self.icedClientPlayer) and self.icedClientPlayer:GetControllerValid() then
                    GetParticleSystem():AddEffect("icehit", self.icedClientPlayer:GetController():GetPosition())
	                GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poofw.wav", self.icedClientPlayer:GetController():GetPosition(), 1, 3, true, SoundSystem.MEDIUM)
	            elseif IsValid(self.graphicalCube) then
	                GetParticleSystem():AddEffect("icehit", self.graphicalCube:GetPosition())
	                GetSoundSystem():EmitSound(ASSET_DIR .. "sound/poofw.wav", self.graphicalCube:GetPosition(), 1, 3, true, SoundSystem.MEDIUM)
	            end
			end
			self:SetWeaponDead()
		end
	--end

end


function SyncedIceCube:SetIcedPlayer(newIcedPlayer)

	local playerID = newIcedPlayer:GetParameter(0, true):GetIntData()

	--First, unfreeze the current player if there is one
	--self:DetachCubeFromCurrentPlayer()

	--Next, freeze the player that matches the passed in ID if that ID is valid
	if playerID ~= 0 then
		self.icedClientPlayer = GetPlayerManager():GetPlayerFromID(playerID)
		if IsValid(self.icedClientPlayer) then
			--Attach the ice cube mesh to this player
			--BRIAN TODO: Kinda a HACK, 0.5 units up because the scenenode is not
			--centered on the player
			self.graphicalCube:SetPosition(WVector3(0, 0.5, 0))
			self.graphicalCube:SetOrientation(WQuaternion())
			self.graphicalCube:SetVisible(true)
			self.graphicalCube:SetScale(self.idealScale)
			self.startScale = false
			self.graphicalCube:AttachToParentSceneNode(self.icedClientPlayer:GetController():GetSceneNode())
			--Try without shadows for player in ice
			self.icedClientPlayer:GetController():SetCastShadows(false)

			--self.meltAnimation:Play()

			--Show the ice hit effect
			GetParticleSystem():AddEffect("icehit", self.icedClientPlayer:GetPosition())
			--Play drop sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Freezing_1.wav", self.icedClientPlayer:GetPosition(), 1, 3, true, SoundSystem.MEDIUM)
			
			self.icedClientPlayer:GetController():iced()
		end
	end

end


function SyncedIceCube:DetachCubeFromCurrentPlayer()

	if IsValid(self.icedClientPlayer) then
		if IsValid(self.graphicalCube) then
			--The cube is no longer attached to this player
			--Attach it back to the scene root
			self.graphicalCube:AttachToRootSceneNode()
		end
		--Put the shadows back on for the iced player
		if self.icedClientPlayer:GetControllerValid() then
		    self.icedClientPlayer:GetController():SetCastShadows(true)
		end
	end
	self.icedClientPlayer = nil

end


function SyncedIceCube:DoesWeaponOwn(ownObjectID)

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


function SyncedIceCube:NotifyPositionChange(setPos)

	if IsValid(self.graphicalCube) and not IsValid(self.icedClientPlayer) then
		self.graphicalCube:SetPosition(setPos)
		--Now we know we have valid state
        if not self.graphicalCube:GetVisible() then
            self.graphicalCube:SetVisible(true)
            self.startScale = true
            self.scaleClock:Reset()
        end
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:SetPosition(setPos)
	end

end


function SyncedIceCube:NotifyOrientationChange(setOrien)

	if IsValid(self.graphicalCube) and not IsValid(self.icedClientPlayer) then
		self.graphicalCube:SetOrientation(setOrien)
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:SetOrientation(setOrien)
	end

end


function SyncedIceCube:GetPosition()

	if IsClient() then
		return self.graphicalCube:GetPosition()
	end
	return self.physicalCube:GetPosition()

end


function SyncedIceCube:GetOrientation()

	if IsClient() then
		return self.graphicalCube:GetOrientation()
	end
	return self.physicalCube:GetOrientation()

end


function SyncedIceCube:GetWeaponActive()

    if IsValid(self.physicalCube) then
	    return not self.physicalCube:GetSleeping()
	end
	return false

end


function SyncedIceCube:SetWeaponStateData(stateBuiltTime, setState)

	local pos = setState:ReadWVector3()
	local orien = setState:ReadWQuaternion()
	--local vel = setState:ReadWVector3()
	--local angVel = setState:ReadWVector3()

	if IsValid(self.physicalCube) then
		self.physicalCube:SetPosition(pos)
		self.physicalCube:SetOrientation(orien)
		--self.physicalCube:SetLinearVelocity(vel)
		--self.physicalCube:SetAngularVelocity(angVel)
	end

	--We must update the transform of this object now so the ClientWorld can lerp properly
	self:SetPosition(pos, false)
	self:SetOrientation(orien, false)

end


function SyncedIceCube:GetWeaponStateData(returnState)

	if IsValid(self.physicalCube) then
		returnState:WriteWVector3(self.physicalCube:GetPosition())
		returnState:WriteWQuaternion(self.physicalCube:GetOrientation())
		--returnState:WriteWVector3(self.physicalCube:GetLinearVelocity())
		--returnState:WriteWVector3(self.physicalCube:GetAngularVelocity())
	end

end


function SyncedIceCube:UseItemUp(pressed, extraData)

	if IsServer() and self.state == self.ICS_NOT_USED then
		if pressed then
			self:Throw()
		end
	end

end


function SyncedIceCube:UseItemDown(pressed, extraData)

	if IsServer() and self.state == self.ICS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedIceCube:SetWeaponParameter(param)

end


function SyncedIceCube:EnumerateWeaponParameters(params)

end


function SyncedIceCube:PlayerInvalid(player)

	--Check if the invalid player is the iced player
	if IsClient() then
		if self.icedClientPlayer == player:GetUniqueID() then
			self:DetachCubeFromCurrentPlayer()
		end
	else
	    if self.icedClientPlayer == player:GetUniqueID() then
            --The iced player is invalid, so the ice cube is done
            self:EndMelt()

            self.icedPlayer = nil
        end
	end

	--BRIAN TODO: Handle cases where GetOwner() is called

end


function SyncedIceCube:ProcessSyncedObject(frameTime)

	if self.state == self.ICS_NOT_USED then
	elseif self.state == self.ICS_DETACHED or self.state == self.ICS_DROPPED then
		self:ProcessDetached(frameTime)
	elseif self.state == self.ICS_START_MELT then
		self:ProcessMelting(frameTime)
	end

	if IsValid(self.physicalCube) then
		self.physicalCube:Process(frameTime)
		self:SetPosition(self.physicalCube:GetPosition(), false)
        self:SetOrientation(self.physicalCube:GetOrientation(), false)
        self:SetLinearVelocity(self.physicalCube:GetLinearVelocity(), false)
	end

	if IsValid(self.graphicalCube) then
	    if self.startScale then
	        local lerpAmount = math.min(1, self.scaleClock:GetTimeSeconds() / self.endScaleTime)
	        local lerpedScale = WVector3Lerp(lerpAmount, WVector3(), self.idealScale)
	        self.graphicalCube:SetScale(lerpedScale)
	        if lerpAmount == 1 then
	            self.startScale = false
	        end
        end
	
		self.graphicalCube:Process(frameTime)
	end

end


function SyncedIceCube:ProcessDetached(frameTime)

	--Only the server processes this clock
	if IsServer() then
	
	    if self.detachClock:GetTimeSeconds() < 0.5 then
            -- guide the mine
            local guideForce = self:GetGuideForce(self.physicalCube:GetPosition(), self.physicalCube:GetLinearVelocity(), 30, 50.0, frameTime)
            if IsValid(guideForce) then
                self.physicalCube:ApplyWorldImpulse(guideForce, WVector3())
            end
        end
	    
		if self.detachClock:GetTimeSeconds() > self.detachTimer then
			self:EndMelt()
		end
	end

end


function SyncedIceCube:ProcessMelting(frameTime)

	--Only the server processes this clock
	if IsServer() then
		if self.meltClock:GetTimeSeconds() > self.meltTimer then
			self:EndMelt()
		end
	elseif IsValid(self.cubeMeltAnim) then
	    self.cubeMeltAnim:Process(frameTime)
    end

end


--The ice cube should detach from the controller it is following
function SyncedIceCube:Detach()

	if self.state == self.ICS_NOT_USED then
		self:SetICState(self.ICS_DROPPED)
		self:InitPhysical(true)
	end

end


function SyncedIceCube:Throw()

	if self.state == self.ICS_NOT_USED then
		self:SetICState(self.ICS_DETACHED)
		
		self:InitPhysical(false)
		--First match the velocity of the thrower
		self.physicalCube:SetLinearVelocity(self:GetOwner():GetLinearVelocity())
		--Throw the mine forward now
		--local forwardNormal = self:GetOwner():GetOrientation():zAxis()
		local forwardNormal = self.aimNormal
        local force = forwardNormal * ICE_PLAYER_FORCE
		--Add some upward force
		force = force + WVector3(0, ICE_UP_FORCE, 0)
		self.physicalCube:ApplyWorldImpulse(force, WVector3())
	end

end


function SyncedIceCube:StartMelt(player)

	self:SetICState(self.ICS_START_MELT)

	local icedPlayerID = 0
	if IsValid(player) then
		icedPlayerID = player:GetUniqueID()
		self.icedPlayer = player
		self.savedWheelFriction = self.icedPlayer:GetController():GetWheelFriction()
		self.icedPlayer:GetController():SetWheelFriction(0)
	end

	self.stateParam:SetIntData(icedPlayerID)
	GetServerSystem():GetSendStateTable("Map"):SetState("IcedPlayer_" .. tostring(self:GetID()), self.stateParam)

end


function SyncedIceCube:EndMelt()

	self:SetICState(self.ICS_DONE_MELT)
	--Return to the previous friction value
	if IsValid(self.icedPlayer) then
		--Mark this player as not iced so he can be iced again
		self.icedPlayer.userData.iced = false
		if self.icedPlayer:GetControllerValid() then
			self.icedPlayer:GetController():SetWheelFriction(self.savedWheelFriction)
		end
		self.icedPlayer = nil
	end

end


function SyncedIceCube:IceCubeCollision(collisionParams)
	
    --Collisions are only allowed when the ice cube is detached
	if self.state ~= self.ICS_DETACHED and self.state ~= self.ICS_DROPPED  then
		return
	end

	--Only collide with players for now...

	local emitColl = false

	--Find out what collided with this ice cube
	local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	--Make sure the cube collided with a player and
	--that player isn't the owner if the prevention timer isn't up yet
	if IsValid(hitPlayer) and
       (self.iceSelfPreventionTimer:IsTimerUp() or hitPlayer:GetUniqueID() ~= self:GetOwner():GetUniqueID()) then
		emitColl = true
	end

	if emitColl then
		print("Player " .. hitPlayer:GetName() .. " hit ice cube with ID " .. tostring(self:GetID()))
		--Check if this player is already iced
		if hitPlayer.userData.iced ~= true then
			--Mark this player as iced so he cannot be iced again
			hitPlayer.userData.iced = true
			self:StartMelt(hitPlayer)
		end
	end

end

--SYNCEDICECUBE CLASS END