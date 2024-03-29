UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")
UseModule("AchievementManager", "Scripts/")
local THROW_OBJECT_FORCE = 50

local THROW_UP_FORCE = 0

--SyncedFakeItem CLASS START

--SyncedFakeItem
class 'SyncedFakeItem' (ISyncedWeapon)

function SyncedFakeItem:__init() super(20)

	self.graphicalMine = nil
	self.physicalMine = nil
	self.mineSensor = nil

    self.achievements = AchievementManager()

	--Called when something collides with the mine
	self.collisionSlot = self:CreateSlot("MineCollision", "MineCollision")

	self.detachClock = WTimer()
	--detachTimer is how long the mine will last on it's own
	self.detachTimer = 9999999

	--The mine isn't ready to blow up until it is active
	self.activeClock = WTimer()
	self.activeTimer = 0

	--This is the countdown from the armed state to the KABOOM
	self.armedClock = WTimer()
	self.armedTimer = 0.25

	--The mine remains in the world for a small period of time after
	--exploding to give clients time to display effects and play sounds
	self.explodingClock = WTimer()
	self.explodingTimer = 0.5

	--This is the radius that this mine is effective at
	self.proximityRadius = 3
    self.explosionRadius = 20
	self.minExplosionForce = 0
	self.maxExplosionForce = 9990
	self.minUpExplosionForce = 1
	self.maxUpExplosionForce = 5999

	self.idealScale = WVector3(1, 1, 1)
	self.startScale = false
	self.scaleClock = WTimer()
    self.endScaleTime = 0.2

	--Not used yet
	self.SMS_NOT_USED = 0
	--Used, detached
	self.SMS_DETACHED = 1
	--Used, thrown
	self.SMS_THROWN = 2
	--Armed and ready to blow
	self.SMS_ARMED = 3
	--In the process of exploding
	self.SMS_EXPLODING = 4
	--Done exploding
	self.SMS_EXPLODED = 5
	self.state = self.SMS_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.SMS_NOT_USED] = { SyncedFakeItem.StateChangeNotUsed, SyncedFakeItem.ProcessStateNotUsed }
	self.stateFuncs[self.SMS_DETACHED] = { SyncedFakeItem.StateChangeDetached, SyncedFakeItem.ProcessStateDetached }
	self.stateFuncs[self.SMS_THROWN] = { SyncedFakeItem.StateChangeThrown, SyncedFakeItem.ProcessStateThrown }
	self.stateFuncs[self.SMS_ARMED] = { SyncedFakeItem.StateChangeArmed, SyncedFakeItem.ProcessStateArmed }
	self.stateFuncs[self.SMS_EXPLODING] = { SyncedFakeItem.StateChangeExploding, SyncedFakeItem.ProcessStateExploding }
	self.stateFuncs[self.SMS_EXPLODED] = { SyncedFakeItem.StateChangeExploded, SyncedFakeItem.ProcessStateExploded }

end


function SyncedFakeItem:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedFakeItem", "ISyncedWeapon", "")

end


function SyncedFakeItem:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetMineState", "SetMineState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("MineState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("MineState_" .. tostring(self:GetID()))
		self:SetMineState(self.state)
	end

end


function SyncedFakeItem:UnInitWeapon()

	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("MineState_" .. tostring(self:GetID()))
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedFakeItem:InitGraphical()

	self.graphicalMine = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "itembox.mesh"))
	self.graphicalMine:SetName("seaMine")
	self.graphicalMine:Init(params)
	self.graphicalMine:SetScale(WVector3(0, 0, 0))
	self.graphicalMine:SetCastShadows(true)
	self.graphicalMine:SetReceiveShadows(false)
	--Do not show the mine until we have state for it
	self.graphicalMine:SetVisible(false)

end


function SyncedFakeItem:UnInitGraphical()

	if IsValid(self.graphicalMine) then
		self.graphicalMine:UnInit()
		self.graphicalMine = nil
	end

end


function SyncedFakeItem:InitPhysical(detachBehind)

	--The physical entity
	self.physicalMine = BulletSphere()
	self.physicalMine:SetName(self.name)
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
		detachPos = detachPos - (forwardQuat:zAxis() * 2)
	else
		detachPos = detachPos + (forwardNormal * 3)
	end
	detachPos.y = detachPos.y + 1.5
	params:AddParameter(Parameter("PositionX", detachPos.x))
	params:AddParameter(Parameter("PositionY", detachPos.y))
	params:AddParameter(Parameter("PositionZ", detachPos.z))
	params:AddParameter(Parameter("ScaleX", 1))
	params:AddParameter(Parameter("ScaleY", 1))
	params:AddParameter(Parameter("ScaleZ", 1))
	params:AddParameter(Parameter("Dimensions", WVector3(1.5, 1.5, 1.5)))
	params:AddParameter(Parameter("Friction", 2))
	params:AddParameter(Parameter("Restitution", 0))
	params:AddParameter(Parameter("LinearDamping", 0.25))
	params:AddParameter(Parameter("AngularDamping", 0.75))
	params:AddParameter(Parameter("Mass", 100))
	self.physicalMine:Init(params)
	self.physicalMine:SetLinearDamping(0.25)
	--self.physicalMine:SetAngularDamping(1)
	--Only the server should deal with collisions
	if IsServer() then
		self.physicalMine:GetSignal("StartCollision", true):Connect(self.collisionSlot)

		--The sensor is used to determine what is within the blast radius
		self.mineSensor = BulletSensor()
		self.mineSensor:SetName(self.name .. "_Sensor")
		local params = Parameters()
		params:AddParameter(Parameter("Shape", "Sphere"))
		params:AddParameter(Parameter("Dimensions", WVector3(self.explosionRadius, self.explosionRadius, self.explosionRadius)))
		self.mineSensor:Init(params)

		--The mine won't blow up until it is active
		self.activeClock:Reset()
	end

end


function SyncedFakeItem:UnInitPhysical()

	if IsValid(self.physicalMine) then
		self.physicalMine:UnInit()
		self.physicalMine = nil
	end

	if IsValid(self.mineSensor) then
		self.mineSensor:UnInit()
		self.mineSensor = nil
	end

end


function SyncedFakeItem:SetMineState(newState)

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("MineState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true)

end


function SyncedFakeItem:DoesWeaponOwn(ownObjectID)

	if self.physicalMine:GetID() == ownObjectID then
		return true
	end
	if IsClient() then
		if self.graphicalMine:GetID() == ownObjectID then
			return true
		end
	end

	return false

end


function SyncedFakeItem:NotifyPositionChange(setPos)

    if IsValid(self.graphicalMine) then
		self.graphicalMine:SetPosition(setPos)
		--Now we know we have valid state
        if not self.graphicalMine:GetVisible() then
        	self.boxAnim = self.graphicalMine:GetAnimation("idle", true)
		self.boxAnim:Play()
            self.graphicalMine:SetVisible(true)
            self.startScale = true
            self.scaleClock:Reset()
        end
	end

	if IsValid(self.physicalMine) then
		self.physicalMine:SetPosition(setPos)
	end

end


function SyncedFakeItem:NotifyOrientationChange(setOrien)

    if IsValid(self.graphicalMine) then
		self.graphicalMine:SetOrientation(setOrien)
	end

	if IsValid(self.physicalMine) then
		self.physicalMine:SetOrientation(setOrien)
	end

end


function SyncedFakeItem:GetPosition()

	if IsClient() then
		return self.graphicalMine:GetPosition()
	end
	return self.physicalMine:GetPosition()

end


function SyncedFakeItem:GetOrientation()

	if IsClient() then
		return self.graphicalMine:GetOrientation()
	end
	return self.physicalMine:GetOrientation()

end


function SyncedFakeItem:GetWeaponActive()

	if IsValid(self.physicalMine) then
	    return not self.physicalMine:GetSleeping()
	end
	return false

end


function SyncedFakeItem:SetWeaponStateData(stateBuiltTime, setState)

	local pos = setState:ReadWVector3()
	local orien = setState:ReadWQuaternion()
	--local vel = setState:ReadWVector3()
	--local angVel = setState:ReadWVector3()

	if IsValid(self.physicalMine) then
		self.physicalMine:SetPosition(pos)
		self.physicalMine:SetOrientation(orien)
		--self.physicalMine:SetLinearVelocity(vel)
		--self.physicalMine:SetAngularVelocity(angVel)
	end

	--We must update the transform of this object now so the ClientWorld can lerp properly
	self:SetPosition(pos, false)
	self:SetOrientation(orien, false)

end


function SyncedFakeItem:GetWeaponStateData(returnState)

	if IsValid(self.physicalMine) then
		returnState:WriteWVector3(self.physicalMine:GetPosition())
		returnState:WriteWQuaternion(self.physicalMine:GetOrientation())
		--returnState:WriteWVector3(self.physicalMine:GetLinearVelocity())
		--returnState:WriteWVector3(self.physicalMine:GetAngularVelocity())
	end

end


function SyncedFakeItem:UseItemUp(pressed, extraData)

	if IsServer() and self.state == self.SMS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedFakeItem:UseItemDown(pressed, extraData)

	if IsServer() and self.state == self.SMS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedFakeItem:SetWeaponParameter(param)

end


function SyncedFakeItem:EnumerateWeaponParameters(params)

end


--The mine should detach from the kart it is following
function SyncedFakeItem:Detach()

	if self.state == self.SMS_NOT_USED then
		self:SetMineState(self.SMS_DETACHED)
	end

end


function SyncedFakeItem:Throw()

	if self.state == self.SMS_NOT_USED then
		self:SetMineState(self.SMS_THROWN)
		--First match the velocity of the thrower
		self.physicalMine:SetLinearVelocity(self:GetOwner():GetLinearVelocity())
		--Throw the mine in the aimed direction
        local force = self.aimNormal * THROW_OBJECT_FORCE
		--Add some upward force
		force = force + WVector3(0, THROW_UP_FORCE, 0)
		self.physicalMine:ApplyWorldImpulse(force, WVector3())
	end

end


function SyncedFakeItem:Arm()

	self:SetMineState(self.SMS_ARMED)

end


--Cause the mine to blow up, pushing any objects away from the explosion
function SyncedFakeItem:KaBoom()

	--Can't blow up twice...
	if self.state ~= self.SMS_ARMED then
		return
	end

	--Blow up!
	local objectList = self:GetObjectsWithinRadius()
	local numObjects = #objectList
	local i = 1
	--Values needed for explosion
	local explosionEmitPoint = WVector3(self.physicalMine:GetPosition())
	--self.physicalMine:GetScale().y should be the height of the mine
	--We divide by 2 to bring the explosion point to the bottom of the mine
	explosionEmitPoint.y = explosionEmitPoint.y - (self.physicalMine:GetScale().y / 2)
	while i <= numObjects do
		local currentObject = objectList[i][1]
		local objectDistance = objectList[i][2]
		--BRIAN TODO: Test code only
		print("Blowing up object: " .. currentObject:GetName())
		--Repell the object away from the bomb
		local explosionNormal = currentObject:GetPosition() - self.physicalMine:GetPosition()
		explosionNormal:Normalise()
		local explosionPercent = 1 - (objectDistance / self.explosionRadius)
		local force = explosionNormal * Lerp(explosionPercent, self.minExplosionForce, self.maxExplosionForce)
		--Add some upward force
		force = force + WVector3(0, Lerp(explosionPercent, self.minUpExplosionForce, self.maxUpExplosionForce), 0)
		currentObject:ApplyWorldImpulse(force, WVector3())
		--Random torque
		local randomNormalVec = WVector3(0, 1, 0):Random(0.5, WVector3(0, 1, 0))
		randomNormalVec = randomNormalVec:Random(0.5, WVector3(1, 0, 0))
		randomNormalVec = randomNormalVec:Random(0.5, WVector3(0, 0, 1))
		randomNormalVec:Normalise()
		currentObject:ApplyWorldTorqueImpulse(randomNormalVec * 500)

		i = i + 1
	end

	self:SetMineState(self.SMS_EXPLODING)

end


function SyncedFakeItem:GetObjectsWithinRadius()

	local objectList = { }
	local iter = self.mineSensor:GetIterator()
	while not iter:IsEnd() do
		local currentObject = iter:Get()
		--BRIAN TODO: Test code only
		--print("Object within blast radius: " .. currentObject:GetName())
		local distance = self.mineSensor:GetPosition():Distance(currentObject:GetPosition())
		if distance > 0.1 and not(IsValid(self:GetOwner()) and self:GetOwner():DoesOwn(currentObject:GetID())) then
		    table.insert(objectList, { currentObject, distance })
		end
		iter:Next()
	end

	return objectList

end


function SyncedFakeItem:MineCollision(collisionParams)

	--BRIAN TODO: Collision test code
	--print("SyncedFakeItem:MineCollision() called")

	--Collisions are only allowed when the mine is detached
	if (self.state ~= self.SMS_DETACHED) and (self.state ~= self.SMS_THROWN) then
		return
	end

	--Only check for collisions with players
	local playerColl = false

	--Find out what collided with this mine
	local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	if IsValid(hitPlayer) then
		playerColl = true
	end

	--Only allow the mine to blow up if it is active
	if playerColl and self.activeClock:GetTimeSeconds() >= self.activeTimer then
		--Somebody hit the mine, arm it
		self:Arm()
	end

end


function SyncedFakeItem:ProcessSyncedObject(frameTime)

	--Process the current state
	self.stateFuncs[self.state][2](self, frameTime)

	if IsValid(self.physicalMine) then
		self.physicalMine:Process(frameTime)
		self:SetPosition(self.physicalMine:GetPosition(), false)
        self:SetOrientation(self.physicalMine:GetOrientation(), false)
        self:SetLinearVelocity(self.physicalMine:GetLinearVelocity(), false)
	end

	if IsValid(self.mineSensor) then
		self.mineSensor:Process(frameTime)
	end

	if IsValid(self.graphicalMine) then
	    if self.startScale then
	        local lerpAmount = math.min(1, self.scaleClock:GetTimeSeconds() / self.endScaleTime)
	        local lerpedScale = WVector3Lerp(lerpAmount, WVector3(), self.idealScale)
	        self.graphicalMine:SetScale(lerpedScale)
	        if lerpAmount == 1 then
	            self.startScale = false
	        end
        end

		self.graphicalMine:Process(frameTime)
	end

end


--State process functions below
function SyncedFakeItem:ProcessStateNotUsed(frameTime)

end


function SyncedFakeItem:ProcessStateDetached(frameTime)

	--Only the server processes this clock
	if IsServer() then
		--After a period of time, the mine explodes on it's own
		if self.detachClock:GetTimeSeconds() > self.detachTimer then
			self:Arm()
		end

		--Always sync the sensor to the physical mine's position
		self.mineSensor:SetPosition(self.physicalMine:GetPosition())
		
		-- Check for player proximity
		local objectList = self:GetObjectsWithinRadius()
	    local numObjects = #objectList
	    local i = 1
	    while i <= numObjects do
            local currentObject = objectList[i][1]
            local objectDistance = objectList[i][2]
            
            if objectDistance < self.proximityRadius then
                self:Arm()
                i = numObjects+1
            end
            
            i = i + 1
        end
	end

end


function SyncedFakeItem:ProcessStateThrown(frameTime)
    
    if IsServer() and self.detachClock:GetTimeSeconds() < 0.5 then
        -- guide the mine
        local guideForce = self:GetGuideForce(self.physicalMine:GetPosition(), self.physicalMine:GetLinearVelocity(), 30, 50.0, frameTime)
        if IsValid(guideForce) then
            self.physicalMine:ApplyWorldImpulse(guideForce, WVector3())
        end
	end
    
    self:ProcessStateDetached(frameTime)

end


function SyncedFakeItem:ProcessStateArmed(frameTime)

	if IsServer() and self.armedClock:GetTimeSeconds() > self.armedTimer then
		self:KaBoom()
	end

end


function SyncedFakeItem:ProcessStateExploding(frameTime)

	if IsServer() and self.explodingClock:GetTimeSeconds() > self.explodingTimer then
		self:SetMineState(self.SMS_EXPLODED)
	end

end


function SyncedFakeItem:ProcessStateExploded(frameTime)

end


--State change functions below
function SyncedFakeItem:StateChangeNotUsed(initing)

end


function SyncedFakeItem:StateChangeDetached(initing)

	if initing then
		--true for detach behind
		self:InitPhysical(true)
		if IsClient() then
			self:InitGraphical()
			--Play drop sound
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Mine_Drop.wav", throwPos, 7, 1, true, SoundSystem.MEDIUM)
		else
			self.detachClock:Reset()
			--The player no longer has control over this item once it is detached
			self:SetWeaponUsed()
		end
	end

end


function SyncedFakeItem:StateChangeThrown(initing)

	if initing then
		--false, for throw ahead
		self:InitPhysical(false)
		if IsClient() then
			self:InitGraphical()
			local throwPos = WVector3()
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			--Play throw sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Throw.wav", throwPos, 7, 1, true, SoundSystem.MEDIUM)
		else
			self.detachClock:Reset()
			--The player no longer has control over this item once it is detached
			self:SetWeaponUsed()
		end
	end

end


function SyncedFakeItem:StateChangeArmed(initing)

	if initing then
		if IsClient() and IsValid(self.graphicalMine) then
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Mine_Impact.wav", self.graphicalMine:GetPosition(), 7, 1, true, SoundSystem.MEDIUM)
		else
			--Once the mine is fully armed, KABOOM!
			self.armedClock:Reset()
		end
	end

end


function SyncedFakeItem:StateChangeExploding(initing)

	if initing then
		self.explodingClock:Reset()
		--Remove the mine from the physical world
		if IsClient() and IsValid(self.graphicalMine) then
			--Play explode sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/roblox.wav", self.graphicalMine:GetPosition(), 10, 6, true, SoundSystem.MEDIUM)
			--Show the explode effect
			GetParticleSystem():AddEffect("boom", self.graphicalMine:GetPosition())
			
			-- Check for deep six achievement
			local i = 1
			local numAffected = 0
	        local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	        local wager = true
	        while i < (numPlayers + 1) do
		        local player = GetPlayerManager():GetPlayer(i)
		        if (player:GetPosition() - self.graphicalMine:GetPosition()):Length() < self.explosionRadius then
                    numAffected = numAffected + 1
		        end
		        i = i + 1
	        end
	        print("Players hit by mine: "..numAffected)
	        local owner = self:GetOwner()
	        if numAffected > 5 and IsValid(owner) and owner == GetPlayerManager():GetLocalPlayer() then
	            self.achievements:Unlock(self.achievements.AVMT_DEEP_6)
	        end
	        --Done with the graphical mine
			self:UnInitGraphical()
		end
	end

end


function SyncedFakeItem:StateChangeExploded(initing)

	if IsServer() then
		--The mine has completely exploded, it is dead
		self:SetWeaponDead()
	end

end


--SyncedFakeItem CLASS END