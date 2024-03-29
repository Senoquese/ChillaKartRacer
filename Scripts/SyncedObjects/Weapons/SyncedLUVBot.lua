UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")
UseModule("AchievementManager", "Scripts/")

local THROW_OBJECT_FORCE = 10000
local THROW_UP_FORCE = 1500
--How much less powerful the drop force is vs throw force
local DROP_FORCE_MOD = 4

--SYNCEDLUVBOT CLASS START

--SyncedLUVBot
class 'SyncedLUVBot' (ISyncedWeapon)

function SyncedLUVBot:__init() super()

    self.updateClock = 0
    self.updateTimer = 1/20

	self.graphicalBot = nil
	self.physicalBot = nil
	self.trackSensor = nil
	self.explosionSensor = nil

	--This is the radius that this mine is effective at
	self.trackRadius = 200
	self.explosionRadius = 40
	self.minExplosionForce = 0
	self.maxExplosionForce = 4000
	self.minUpExplosionForce = 0
	self.maxUpExplosionForce = 5000
	self.minTrackForce = 6000
	self.maxTrackForce = 25000

	self.physicalSize = 0.3

	self.detachHeight = 2

    if IsClient() then
        self.achievements = AchievementManager()
    end

    self.idealScale = WVector3(1, 1, 1)
	self.startScale = false
	self.scaleClock = WTimer()
    self.endScaleTime = 0.2

	--Called when something collides with the bot
	self.collisionSlot = self:CreateSlot("BotCollision", "BotCollision")

	self.detachClock = WTimer()
	--detachTimer is how long the bot will last on it's own
	self.detachTimer = 15
    self.chargeTimer = 11

	self.latchClock = WTimer()
	self.latchTimer = 5

    self.luvTrackClock = WTimer()
    --luvTrackTimer is how long after being deployed before it starts tracking a target
    self.luvTrackTimer = 1.5

    self.explodingClock = WTimer()
    self.explodingTimer = 1

    self.currentTargetID = 0

	--Needed for certain cases
	self.lastKnownBotPos = WVector3()

    self.debugDrawEnabled = false

	--This is how much the graphical bot's y coordinate needs to be adjusted to line up correctly
    self.graphicalBotYPosAdjust = 0.0

	--Not used yet
	self.SLB_NOT_USED = 0
	--Used, thrown
	self.SLB_THROWN = 1
	--Latched onto a player
	self.SLB_LATCHED = 2
	--In the process of exploding
	self.SLB_EXPLODING = 3
	--Done exploding
	self.SLB_EXPLODED = 4
	self.state = self.SLB_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.SLB_NOT_USED] = { SyncedLUVBot.StateChangeNotUsed, SyncedLUVBot.ProcessStateNotUsed }
	self.stateFuncs[self.SLB_THROWN] = { SyncedLUVBot.StateChangeThrown, SyncedLUVBot.ProcessStateThrown }
	self.stateFuncs[self.SLB_LATCHED] = { SyncedLUVBot.StateChangeLatched, SyncedLUVBot.ProcessStateLatched }
	self.stateFuncs[self.SLB_EXPLODING] = { SyncedLUVBot.StateChangeExploding, SyncedLUVBot.ProcessStateExploding }
	self.stateFuncs[self.SLB_EXPLODED] = { SyncedLUVBot.StateChangeExploded, SyncedLUVBot.ProcessStateExploded }

end


function SyncedLUVBot:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedLUVBot", "ISyncedWeapon", "")

end


function SyncedLUVBot:InitWeapon()

	local initBotClock = WTimer()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetBotState", "SetBotState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("BotState_" .. tostring(self:GetServerID()), self.stateSlot)

		self.targetSlot = self:CreateSlot("SetBotTarget", "SetBotTarget")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("BotTarget_" .. tostring(self:GetServerID()), self.targetSlot)
		
		--Persistent luv bot sounds
        local soundParams = Parameters()
        self.chargeSound = SoundSource()
	    self.chargeSound:SetName("luvbotCharge_" .. tostring(self:GetID()))
	    self.chargeSound:Init(soundParams)
	    self.chargeSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/luvbot_charge.wav"))
	    self.chargeSound:SetVolume(11)
	   
        self.runSound = SoundSource()
	    self.runSound:SetName("luvbotRun_" .. tostring(self:GetID()))
	    self.runSound:Init(soundParams)
	    self.runSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/luvbot_run.wav"))
	    self.runSound:SetVolume(11)
	    self.runSound:SetLooping(true)
	    self.runSound:Play()
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("BotState_" .. tostring(self:GetID()))
		self:SetBotState(self.state)

		GetServerSystem():GetSendStateTable("Map"):NewState("BotTarget_" .. tostring(self:GetID()))
		self:SetBotTarget(self.currentTargetID)
	end

	print("SyncedLUVBot Init time: " .. tostring(initBotClock:GetTimeSeconds()))

end


function SyncedLUVBot:UnInitWeapon()

	--UnInitState
	if IsServer() then
		--Make sure the current target isn't marked as luved by us anymore
		local lastTarget = self:GetBotTarget()
		if IsValid(lastTarget) then
			lastTarget.userData.luved = nil
		end
		GetServerSystem():GetSendStateTable("Map"):RemoveState("BotState_" .. tostring(self:GetID()))
		GetServerSystem():GetSendStateTable("Map"):RemoveState("BotTarget_" .. tostring(self:GetID()))
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedLUVBot:InitGraphical()

	self.graphicalBot = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "luvbot.mesh"))
	self.graphicalBot:SetName("LUVBot")
	self.graphicalBot:Init(params)
	self.graphicalBot:SetScale(WVector3(0, 0, 0))
	self.graphicalBot:SetCastShadows(true)
	self.graphicalBot:SetReceiveShadows(false)
	self.graphicalBot:SetPosition(self.physicalBot:GetPosition())
    self.graphicalBot:SetVisible(false)

    self.runAnim = self.graphicalBot:GetAnimation("run", true)
	self.runAnim:Play()

	self.hugAnim = self.graphicalBot:GetAnimation("hug", true)

    self.LUVIndicator = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "heart_indicator.mesh"))
	self.LUVIndicator:SetName("LUVIndicator" .. self:GetID())
	self.LUVIndicator:Init(params)
	self.LUVIndicator:SetCastShadows(false)
	self.LUVIndicator:SetReceiveShadows(false)
	self.LUVIndicator:SetVisible(false)
	self.LUVIndicatorHalfHeight = self.LUVIndicator:GetBoundingBox():GetHeight() / 2
	self.LUVIndicatorIdleAnim = self.LUVIndicator:GetAnimation("idle", true)

	self:InitParticles()
	self:InitDebugDrawing()

end


function SyncedLUVBot:InitParticles()

	self.luvTrail = OGREParticleEffect()
	local particleParams = Parameters()
	particleParams:AddParameter(Parameter("ResourceName", "hearts"))
	particleParams:AddParameter(Parameter("Loop", true))
	particleParams:AddParameter(Parameter("StartOnLoad", false))
	self.luvTrail:SetName("luvTrail" .. tostring(GenerateID()))
	self.luvTrail:Init(particleParams)

	--[[
	self.scrapeTrail = OGREParticleEffect()
	particleParams:GetOrCreateParameter("ResourceName"):SetStringData("scrape")
	self.scrapeTrail:SetName("scrapeTrail" .. tostring(GenerateID()))
	self.scrapeTrail:Init(particleParams)
	--]]

end


function SyncedLUVBot:InitDebugDrawing()

	--BRIAN TODO: For testing only, draw the client and server physical balls
	self.clientRenderer = OGRELines()
	self.clientRenderer:Init(Parameters())
	self.clientRenderer:SetOverlay(true, false)
	self.serverRenderer = OGRELines()
	self.serverRenderer:Init(Parameters())
	self.serverRenderer:SetOverlay(true, false)

	self.clientRenderer:CreateLineBox(WColorValue(1, 0, 0, 0), 1)
	self.serverRenderer:CreateLineBox(WColorValue(1, 1, 1, 0), 1)

	self.clientRenderer:SetVisible(self.debugDrawEnabled)
	self.serverRenderer:SetVisible(self.debugDrawEnabled)

end


function SyncedLUVBot:UnInitGraphical()

	if IsValid(self.graphicalBot) then
		self.graphicalBot:UnInit()
		self.graphicalBot = nil
	end
	self.runAnim = nil
	self.hugAnim = nil

    if IsValid(self.LUVIndicator) then
        self.LUVIndicator:UnInit()
        self.LUVIndicator = nil
    end
    self.LUVIndicatorIdleAnim = nil

	self:UnInitParticles()
	self:UnInitDebugDrawing()

end


function SyncedLUVBot:UnInitParticles()

	if IsValid(self.luvTrail) then
		self.luvTrail:UnInit()
		self.luvTrail = nil
	end
	if IsValid(self.scrapeTrail) then
		self.scrapeTrail:UnInit()
		self.scrapeTrail = nil
	end

end


function SyncedLUVBot:UnInitDebugDrawing()

    if IsValid(self.clientRenderer) then
        self.clientRenderer:UnInit()
        self.clientRenderer = nil
    end
    if IsValid(self.serverRenderer) then
        self.serverRenderer:UnInit()
        self.serverRenderer = nil
    end

end


function SyncedLUVBot:InitPhysical()

	--The physical entity
	self.physicalBot = BulletSphere()
	self.physicalBot:SetName(self.name)
	local params = Parameters()
	--BRIAN TODO: Why does this cause a crash when a LUVBot exists and a new client connects?
	local detachPos = WVector3()
    if IsValid(self:GetOwner()) then
        detachPos = WVector3(self:GetOwner():GetPosition())
    end
	--BRIAN TODO: Account for different gravity
	detachPos.y = detachPos.y + self.detachHeight
	--BRIAN TODO: Is this needed?
	--self:SetPosition(detachPos)
	params:AddParameter(Parameter("PositionX", detachPos.x))
	params:AddParameter(Parameter("PositionY", detachPos.y))
	params:AddParameter(Parameter("PositionZ", detachPos.z))
	params:AddParameter(Parameter("Dimensions", WVector3(self.physicalSize, self.physicalSize, self.physicalSize)))
	params:AddParameter(Parameter("Friction", 0.5))
	params:AddParameter(Parameter("Restitution", 0.05))
	params:AddParameter(Parameter("LinearDamping", 0.25))
	--params:AddParameter(Parameter("AngularDamping", 0.5))
	params:AddParameter(Parameter("Mass", 300))
	self.physicalBot:Init(params)
	self.physicalBot:SetLinearDamping(0.25)
	self.physicalBot:SetDeactivates(false)
	--self.physicalBot:SetAngularDamping(0.5)
	--Only the server should deal with collisions
	if IsServer() then
		self.physicalBot:GetSignal("StartCollision", true):Connect(self.collisionSlot)

		--The sensor is used to determine what is within the bot's field of awareness
		self.trackSensor = BulletSensor()
		self.trackSensor:SetName(self.name .. "TrackSensor")
		local params = Parameters()
		params:AddParameter(Parameter("Shape", "Sphere"))
		params:AddParameter(Parameter("Dimensions", WVector3(self.trackRadius, self.trackRadius, self.trackRadius)))
		self.trackSensor:Init(params)

		--The explosion sensor is used to determine what is in the blast radius
		self.explosionSensor = BulletSensor()
		self.explosionSensor:SetName(self.name .. "ExplosionSensor")
		params:GetOrCreateParameter("Shape"):SetStringData("Sphere")
		params:GetOrCreateParameter("Dimensions"):SetWVector3Data(WVector3(self.explosionRadius, self.explosionRadius, self.explosionRadius))
		self.explosionSensor:Init(params)
	end

end


function SyncedLUVBot:UnInitPhysical()

	if IsValid(self.physicalBot) then
		self.physicalBot:UnInit()
		self.physicalBot = nil
	end
	if IsValid(self.trackSensor) then
		self.trackSensor:UnInit()
		self.trackSensor = nil
	end
	if IsValid(self.explosionSensor) then
		self.explosionSensor:UnInit()
		self.explosionSensor = nil
	end

end


function SyncedLUVBot:SetBotState(newState)

    print("SyncedLUVBot state change from " .. tostring(self.state) .. " to " .. tostring(newState))

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	local lastState = self.state

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("BotState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true, lastState)

end


function SyncedLUVBot:SetBotTarget(newTargetID)

    if self.currentTargetID ~= newTargetID then
        if IsClient() then
            self.currentTargetID = newTargetID:GetParameter(0, true):GetIntData()
            local currentTargetPlayer = self:GetBotTarget()
            if IsValid(currentTargetPlayer) then
				print("New Target is ID " .. tostring(self.currentTargetID) .. " named " .. currentTargetPlayer:GetName())
                local currentTargetController = currentTargetPlayer:GetController()
                self.LUVIndicator:SetVisible(true)
                self.LUVIndicatorIdleAnim:Play()
                if self.state == self.SLB_LATCHED and IsValid(self:GetBotTarget():GetController()) then
                    self.graphicalBot:AttachToParentSceneNode(self:GetBotTarget():GetController():GetSceneNode())
                    --Move it back a bit from the parent
                    self.graphicalBot:SetPosition(WVector3(0, 0, -1))
                    
                end
            else
				print("New Target is nil")
                if IsValid(self.LUVIndicator) then
                    self.LUVIndicator:SetVisible(false)
                    self.LUVIndicatorIdleAnim:Stop()
                end
            end
        else
			--Mark the last target as not luved anymore
			local lastTarget = self:GetBotTarget()
			if IsValid(lastTarget) then
				lastTarget.userData.luved = nil
			end
            self.currentTargetID = newTargetID
            --Mark the new target as luved
            local newTarget = self:GetBotTarget()
			if IsValid(newTarget) then
				newTarget.userData.luved = true
			end
            print("New Target is ID " .. tostring(self.currentTargetID))
            self.stateParam:SetIntData(self.currentTargetID)
            GetServerSystem():GetSendStateTable("Map"):SetState("BotTarget_" .. tostring(self:GetID()), self.stateParam)
        end
    end

end


function SyncedLUVBot:GetBotTarget()

    return GetPlayerManager():GetPlayerFromID(self.currentTargetID)

end


function SyncedLUVBot:DoesWeaponOwn(ownObjectID)

	if self.physicalBot:GetID() == ownObjectID then
		return true
	end
	if IsClient() then
		if self.graphicalBot:GetID() == ownObjectID then
			return true
		end
	end

	return false

end


function SyncedLUVBot:NotifyPositionChange(setPos)

	if IsValid(self.graphicalBot) and (self.state ~= self.SLB_LATCHED) then
	    if not IsValid(self.lastPosition) or not self.lastPosition == setPos then
	        self.lastPosition = WVector3(self.graphicalBot:GetPosition())
	    end
		local realGraphicalPos = WVector3(setPos)
		--The graphicalBot needs to be moved down a bit to line up correctly
		realGraphicalPos.y = realGraphicalPos.y + self.graphicalBotYPosAdjust
		self.graphicalBot:SetPosition(realGraphicalPos)
		--Now we know we have valid state
        if not self.graphicalBot:GetVisible() then
            self.lastPosition = WVector3(realGraphicalPos)
            self.graphicalBot:SetVisible(true)
            self.startScale = true
            self.scaleClock:Reset()
        end
	end

	if IsValid(self.physicalBot) then
		self.physicalBot:SetPosition(setPos)
	end

end


function SyncedLUVBot:NotifyOrientationChange(setOrien)

	--Note: The graphical bot orientation is handled in ProcessGraphicalTransform()

	if IsValid(self.physicalBot) then
		self.physicalBot:SetOrientation(setOrien)
	end

end


function SyncedLUVBot:GetPosition()

	if IsClient() and IsValid(self.graphicalBot) then
		return self.graphicalBot:GetPosition()
	end
	if IsValid(self.physicalBot) then
		return self.physicalBot:GetPosition()
	end
    return WVector3()

end


function SyncedLUVBot:GetOrientation()

	if IsClient() then
		return self.graphicalBot:GetOrientation()
	end
	return self.physicalBot:GetOrientation()

end


function SyncedLUVBot:GetWeaponActive()

    if IsValid(self.physicalBot) then
	    return not self.physicalBot:GetSleeping()
	end
	return false

end


function SyncedLUVBot:SetWeaponStateData(stateBuiltTime, setState)

	local stateWritten = setState:ReadBool()
	if stateWritten == true then
		local pos = setState:ReadWVector3()
		--local orien = setState:ReadWQuaternion()
		--local vel = setState:ReadWVector3()
		--local angVel = setState:ReadWVector3()

		if IsValid(self.physicalBot) then
			local state = BulletWorldObjectState()
			state:SetPosition(pos)
			--state:SetOrientation(orien)
			--state:SetLinearVelocity(vel)
			--state:SetAngularVelocity(angVel)

			GetBulletPhysicsSystem():SetObjectState("Main", self.physicalBot:GetID(), state)
		end

		--We must update the transform of this object now so the ClientWorld can lerp properly
		self:SetPosition(pos, false)
		--self:SetOrientation(orien, false)

		--Sync the server physical renderer to the last update we received from the server
		if IsValid(self.serverRenderer) then
			self.serverRenderer:SetPosition(pos)
			--self.serverRenderer:SetOrientation(orien)
		end
	end

end


function SyncedLUVBot:GetWeaponStateData(returnState)

	if IsValid(self.physicalBot) then
		returnState:WriteBool(true)
		returnState:WriteWVector3(self.physicalBot:GetPosition())
		--returnState:WriteWQuaternion(self.physicalBot:GetOrientation())
		--returnState:WriteWVector3(self.physicalBot:GetLinearVelocity())
		--returnState:WriteWVector3(self.physicalBot:GetAngularVelocity())
	else
		returnState:WriteBool(false)
	end

end


function SyncedLUVBot:UseItemUp(pressed, extraData)

	if IsServer() and self.state == self.SLB_NOT_USED then
		if pressed then
			self:Throw()
		end
	end

end


function SyncedLUVBot:UseItemDown(pressed, extraData)

	if IsServer() and self.state == self.SLB_NOT_USED then
		if pressed then
			self:Drop()
		end
	end

end


function SyncedLUVBot:SetWeaponParameter(param)

end


function SyncedLUVBot:EnumerateWeaponParameters(params)

end


function SyncedLUVBot:Throw()

	if self.state == self.SLB_NOT_USED then
		self:SetBotState(self.SLB_THROWN)
		--First match the velocity of the thrower
		self.physicalBot:SetLinearVelocity(self:GetOwner():GetLinearVelocity())
		--Throw the bot forward now
		local forwardQuat = self:GetOwner():GetOrientation()
		--local forwardNormal = forwardQuat:zAxis()
		local forwardNormal = self.aimNormal
        local force = forwardNormal * THROW_OBJECT_FORCE
		--Add some upward force
		--BRIAN TODO: Account for different gravity
		force = force + WVector3(0, THROW_UP_FORCE, 0)
		self.physicalBot:ApplyWorldImpulse(force, WVector3())
	end

end


function SyncedLUVBot:Drop()

	if self.state == self.SLB_NOT_USED then
		self:SetBotState(self.SLB_THROWN)
		--Throw the bot back now
		local forwardQuat = self:GetOwner():GetOrientation()
		local forwardNormal = forwardQuat:zAxis()
		--Negate to throw back
		forwardNormal:Negate()
		--Divide by self.dropForceMod so it isn't as strong
		local force = forwardNormal * (THROW_OBJECT_FORCE / DROP_FORCE_MOD)
		--Add some upward force
		--BRIAN TODO: Account for different gravity
		force = force + WVector3(0, (THROW_UP_FORCE / DROP_FORCE_MOD), 0)
		self.physicalBot:ApplyWorldImpulse(force, WVector3())
	end

end


--Cause the bot to blow up, pushing any objects away from the explosion
function SyncedLUVBot:KaBoom()

	--Can't blow up twice...
	if self.state ~= self.SLB_THROWN and self.state ~= self.SLB_LATCHED then
		error("KaBoom() called while in state " .. tostring(self.state))
	end

	--Blow up!
	local objectList = self:GetObjectsWithinRadius(self.explosionSensor)
	local numObjects = #objectList
	local i = 1
	--Values needed for explosion
	local explosionEmitPoint = nil
	if self.state == self.SLB_THROWN then
		explosionEmitPoint = WVector3(self.physicalBot:GetPosition())
		--self.physicalBot:GetScale().y should be the height of the bot
		--We divide by 2 to bring the explosion point to the bottom of the bot
		explosionEmitPoint.y = explosionEmitPoint.y - (self.physicalBot:GetScale().y / 2)
	else
		--It is possible the target player became invalid as it was latched onto
		if self:GetBotTarget() ~= nil then
			explosionEmitPoint = WVector3(self:GetBotTarget():GetPosition())
		else
			--No physical bot, no target, use the last known position
			explosionEmitPoint = WVector3(self.lastKnownBotPos)
		end
	end
	while i <= numObjects do
		local currentObject = objectList[i][1]
		local objectDistance = objectList[i][2]
		--Repell the object away from the bomb
		local explosionNormal = currentObject:GetPosition() - explosionEmitPoint
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

	self:SetBotState(self.SLB_EXPLODING)

end


function SyncedLUVBot:GetObjectsWithinRadius(sensor)

	if not IsValid(sensor) then
		error("Passed in sensor to SyncedLUVBot:GetObjectsWithinRadius() is nil")
	end

	local objectList = { }
	local iter = sensor:GetIterator()
	while not iter:IsEnd() do
		local currentObject = iter:Get()
		local distance = sensor:GetPosition():Distance(currentObject:GetPosition())
		if not IsValid(self:GetOwner()) or not self:GetOwner():DoesOwn(currentObject:GetID()) then
            table.insert(objectList, { currentObject, distance })
        end
		iter:Next()
	end

	return objectList

end


function SyncedLUVBot:LatchToPlayer(toPlayer)

    if IsValid(self:GetOwner()) and IsValid(toPlayer) and self:GetOwner():GetUniqueID() ~= toPlayer:GetUniqueID() then
	    self:SetBotTarget(toPlayer:GetUniqueID())
	    self:SetBotState(self.SLB_LATCHED)
	end

end


function SyncedLUVBot:BotCollision(collisionParams)

	--Collisions are only allowed when the bot is detached
	if self.state ~= self.SLB_THROWN then
		return
	end

	--Only check for collisions with players
	local playerColl = false

	--Find out what collided with this bot
	local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	if IsValid(hitPlayer) then
		playerColl = true
	end

	--Latch to the hit object if it is a player and isn't currently being luved by another bot
	if playerColl and (self.currentTargetID == hitPlayer:GetUniqueID() or hitPlayer.userData.luved ~= true) then
		--Somebody hit the bot, latch onto that player
		self:LatchToPlayer(hitPlayer)
	end

end


function SyncedLUVBot:ProcessSyncedObject(frameTime)

    --Process the current state
    self.stateFuncs[self.state][2](self, frameTime)

    if IsValid(self.physicalBot) then
        self.physicalBot:Process(frameTime)
        --Update the ScriptObject transform every process
        self:SetPosition(self.physicalBot:GetPosition(), false)
        self:SetOrientation(self.physicalBot:GetOrientation(), false)
        self:SetLinearVelocity(self.physicalBot:GetLinearVelocity(), false)
        --Always keep track of the last known bot position for when it doesn't physically exist anymore
        self.lastKnownBotPos:Set(self.physicalBot:GetPosition())
    else
        if IsValid(self:GetBotTarget()) then
            --Always keep track of the last known bot position for when it doesn't have a target player
            self.lastKnownBotPos:Set(self:GetBotTarget():GetPosition())
        end
    end

    if IsValid(self.trackSensor) then
        self.trackSensor:Process(frameTime)
    end
    if IsValid(self.explosionSensor) then
        self.explosionSensor:Process(frameTime)
    end

	if IsValid(self.graphicalBot) then
	
	    if self.startScale then
	        local lerpAmount = math.min(1, self.scaleClock:GetTimeSeconds() / self.endScaleTime)
	        local lerpedScale = WVector3Lerp(lerpAmount, WVector3(), self.idealScale)
	        self.graphicalBot:SetScale(lerpedScale)
	        if lerpAmount == 1 then
	            self.startScale = false
	        end
        end
	
	    self:ProcessGraphicalTransform(frameTime)
		self.graphicalBot:Process(frameTime)
		self.runAnim:Process(frameTime)
		self.hugAnim:Process(frameTime)
		self.LUVIndicatorIdleAnim:Process(frameTime)
		
	end

    if IsValid(self.chargeSound) then
        --Update charge sound position
        if self.state == self.SLB_LATCHED then
            if IsValid(self.chargeSound) and IsValid(self:GetBotTarget()) then
                self.chargeSound:SetPosition(self:GetBotTarget():GetPosition())
            end
        elseif IsValid(self.physicalBot) then
            self.chargeSound:SetPosition(self.physicalBot:GetPosition())
        end
        self.chargeSound:Process(frameTime)
    end

    if IsValid(self.runSound) then
        --Update run sound position
        if self.state == self.SLB_THROWN then
            self.runSound:SetPosition(self.physicalBot:GetPosition())
            self.chargeSound:Process(frameTime)
        end
    end

	--Sync the client physical renderer to the client physical current position
	if IsValid(self.clientRenderer) and IsValid(physicalBot) then
		self.clientRenderer:SetPosition(self.physicalBot:GetPosition())
		--self.clientRenderer:SetOrientation(self.physicalBall:GetOrientation())
	end

end


function SyncedLUVBot:ProcessGraphicalTransform(frameTime)

    local currentTarget = self:GetBotTarget()
    local orienNormal = nil

	if self.state == self.SLB_LATCHED then
		orienNormal = WVector3(0, 0, 1)
	else
		if IsValid(currentTarget) then
			--Point towards the currentTarget
			orienNormal = currentTarget:GetPosition() - self.graphicalBot:GetPosition()
		else
			--If there is no target, derive a velocity
			if IsValid(self.lastPosition) then
			    orienNormal = self.graphicalBot:GetPosition() - self.lastPosition
			else
			    orienNormal = WVector3(0, 1, 0)
			end
		end
		
	end

	orienNormal:Normalise()
	local orien = WQuaternion()
	orien:FromNormal(orienNormal)
    self.graphicalBot:SetOrientation(orien)

	self:UpdateLUVTargetTransform()

end


function SyncedLUVBot:UpdateLUVTargetTransform()

    if IsValid(self.graphicalBot) then
        local currentTarget = self:GetBotTarget()

		if IsValid(currentTarget) then
			if currentTarget:GetUniqueID() ~= self.indicatorPlayerID then
				self.indicatorPlayerID = currentTarget:GetUniqueID()
				--self.LUVIndicator:DetachFromParentSceneNode()
				--self.LUVIndicator:AttachToParentSceneNode(currentTarget:GetController():GetSceneNode())

				--BRIAN TODO: Duplicate code that can be generalized, #ModelPositionedOverHead
				local controllerHalfHeight = currentTarget:GetController():GetBoundingBox():GetHeight() / 2
				local addToY = controllerHalfHeight + self.LUVIndicatorHalfHeight
				self.LUVIndicator:SetPosition(WVector3(0, addToY * 2, 0))
			end

			local orien = WQuaternion()
			if self.state ~= self.SLB_LATCHED then
				--Point towards the currentTarget
				local orienNormal = currentTarget:GetPosition() - self.graphicalBot:GetPosition()
				orienNormal:Normalise()
				orien:FromNormal(orienNormal)
			end
			self.LUVIndicator:SetOrientation(orien)
		end
    end

end


--State process functions below
function SyncedLUVBot:ProcessStateNotUsed(frameTime)

end


function SyncedLUVBot:ProcessStateThrown(frameTime)

	--Only the server processes this clock
	if IsServer() then
	    if self.detachClock:GetTimeSeconds() > self.detachTimer then
	        self:KaBoom()
	    else
            if IsValid(self.trackSensor) then
                --Always sync the sensor to the physical bot's position
                self.trackSensor:SetPosition(self.physicalBot:GetPosition())
			end
			if IsValid(self.explosionSensor) then
                self.explosionSensor:SetPosition(self.physicalBot:GetPosition())
            end

            if self:BotTrackingActive() then
                --Limiter
			    self.updateClock = self.updateClock + frameTime
			    while self.updateClock >= self.updateTimer do
			        self.updateClock = self.updateClock - self.updateTimer

                    local luvTarget = self:FindLUVTarget()
                    self:TrackLUVTarget(luvTarget, self.updateTimer)
                end
            end
        end
    else
        -- check to play charge sound
        if self.detachClock:GetTimeSeconds() > self.chargeTimer and self.chargeSound:GetState() ~= SoundSource.PLAYING then
	        self.chargeSound:Play()
	    end
        self.luvTrail:SetPosition(self.graphicalBot:GetPosition())
        if IsValid(self:GetBotTarget()) then
            self.LUVIndicator:SetVisible(true)
            self.LUVIndicator:SetPosition(self:GetBotTarget():GetController():GetPosition()+WVector3(0,1.5,0))
        else
            self.LUVIndicator:SetVisible(false)
        end
        self.luvTrail:Process(frameTime)
	end

end


function SyncedLUVBot:BotTrackingActive()

	return self.luvTrackClock:GetTimeSeconds() > self.luvTrackTimer

end


function SyncedLUVBot:FindLUVTarget()

    local objectList = self:GetObjectsWithinRadius(self.trackSensor)
    local numObjects = #objectList
    local i = 1
    local luvTarget = { nil, 0 }
    while i <= numObjects do
        local currentObject = objectList[i][1]
        local objectDistance = objectList[i][2]
        if (luvTarget[1] == nil or luvTarget[2] > objectDistance) and currentObject:GetID() ~= self.physicalBot:GetID() then
			--Make sure this is a player
			local ensurePlayer = GetPlayerManager():GetPlayerFromObjectID(currentObject:GetID())
			if IsValid(ensurePlayer) then
				--Make sure found target is a player and isn't already being luved by another bot
				if self.currentTargetID == ensurePlayer:GetUniqueID() or ensurePlayer.userData.luved ~= true then
					luvTarget[1] = currentObject
					luvTarget[2] = objectDistance
				end
			end
        end
        i = i + 1
    end

    local targetPlayer = nil
	if IsValid(luvTarget[1]) then
		targetPlayer = GetPlayerManager():GetPlayerFromObjectID(luvTarget[1]:GetID())
	end
    local targetPlayerID = 0
    if IsValid(targetPlayer) then
        targetPlayerID = targetPlayer:GetUniqueID()
    else
        targetPlayerID = 0
    end
    self:SetBotTarget(targetPlayerID)
    return luvTarget

end


--Move closer to the tracked target
function SyncedLUVBot:TrackLUVTarget(luvTarget, frameTime)

    if luvTarget[1] ~= nil then
        local targetNormal = self.physicalBot:GetPosition() - (luvTarget[1]:GetPosition())
        targetNormal:Normalise()
        local trackForcePercent = luvTarget[2] / self.trackRadius
        local force = targetNormal * (frameTime * Lerp(trackForcePercent, self.minTrackForce, self.maxTrackForce))
        force:Negate()
        self.physicalBot:ApplyWorldImpulse(force, WVector3())
    end

end


function SyncedLUVBot:ProcessStateLatched(frameTime)

	if IsClient() then
	    if IsValid(self.luvTrail) then
			if IsValid(self:GetBotTarget()) then
				self.luvTrail:SetPosition(self:GetBotTarget():GetPosition())
			end
            self.luvTrail:Process(frameTime)
        end
        if IsValid(self.scrapeTrail) then
			if IsValid(self:GetBotTarget()) then
				self.scrapeTrail:SetPosition(self:GetBotTarget():GetPosition())
			end
			self.scrapeTrail:Process(frameTime)
		end
	else
		if IsValid(self.explosionSensor) then
			if self:GetBotTarget() ~= nil then
				self.explosionSensor:SetPosition(self:GetBotTarget():GetPosition())
			else
				--No physical bot, no target, use the last known position
				self.explosionSensor:SetPosition(self.lastKnownBotPos)
			end
		end
	    if self.latchClock:GetTimeSeconds() > self.latchTimer then
	        self:KaBoom()
	    end
	end

end


function SyncedLUVBot:ProcessStateExploding(frameTime)

	if IsServer() and self.explodingClock:GetTimeSeconds() > self.explodingTimer then
		self:SetBotState(self.SLB_EXPLODED)
	end

end


function SyncedLUVBot:ProcessStateExploded(frameTime)

end


--State change functions below
function SyncedLUVBot:StateChangeNotUsed(initing, lastState)

end


function SyncedLUVBot:StateChangeThrown(initing, lastState)

	if initing then
		local stateChangeToThrownClock = WTimer()
		self:InitPhysical()
		if IsClient() then
			self:InitGraphical()
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			--Play throw sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Throw.wav", throwPos, 7, 1, true, SoundSystem.MEDIUM)
			--Start trail particle effect
			self.luvTrail:Start()
		else
		    self.luvTrackClock:Reset()
		    self.detachClock:Reset()
			--The player no longer has control over this item once it is thrown
			self:SetWeaponUsed()
		end
		print("SyncedLUVBot state change to thrown time: " .. tostring(stateChangeToThrownClock:GetTimeSeconds()))
    else
        if IsClient() then
            --End trail particle effect
			self.luvTrail:Stop()
        end
	end

end


function SyncedLUVBot:StateChangeLatched(initing, lastState)

	if initing then
		if IsValid(self.physicalBot) then
			self.physicalBot:UnInit()
			self.physicalBot = nil
		end
		if IsClient() then
		    --Stop run sound
		    if IsValid(self.runSound) then
		        self.runSound:Stop()
		    end
		    throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
            --Play latch sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/luvbot_latch.wav", throwPos, 7, 1, true, SoundSystem.MEDIUM)
			--Play charge sound
			if IsValid(self.chargeSound) then
                self.chargeSound:Stop()
                self.chargeSound:Play()
            end
			--Start the trail particle effects
			if IsValid(self.luvTrail) then
			    self.luvTrail:Start()
			end
			if IsValid(self.LUVIndicator) then
			    self.LUVIndicator:SetVisible(false)
			end
			if IsValid(self.scrapeTrail) then
				self.scrapeTrail:Start()
			end
			--Latch the bot onto the player graphically
			print("Bot is latching onto player with ID: " .. tostring(self.currentTargetID) .. " connected to server")
			if IsValid(self:GetBotTarget()) and IsValid(self:GetBotTarget():GetController()) and IsValid(self:GetBotTarget():GetController():GetSceneNode()) then
			    self.graphicalBot:AttachToParentSceneNode(self:GetBotTarget():GetController():GetSceneNode())
                --Move it back a bit from the parent
                self.graphicalBot:SetPosition(WVector3(0, 0, -1))
                
                if not IsValid(self:GetBotTarget().userData.hugs) then
                    self:GetBotTarget().userData.hugs = 0
                end
                self:GetBotTarget().userData.hugs = self:GetBotTarget().userData.hugs + 1
                print("HUGS: "..self:GetBotTarget().userData.hugs)
                
                if self:GetBotTarget().userData.hugs == 3 and self:GetBotTarget() == GetPlayerManager():GetLocalPlayer() then
                    self.achievements:Unlock(self.achievements.AVMT_NEED_LOVE)
                end
                
			end
			if IsValid(self.runAnim) then
			    self.runAnim:Stop()
			end
			if IsValid(self.hugAnim) then
			    self.hugAnim:Play()
			end
		else
			self.latchClock:Reset()
		end
	else
		if IsClient() then
		    if IsValid(self.luvTrail) then
			    self.luvTrail:Stop()
			end
			if IsValid(self.scrapeTrail) then
				self.scrapeTrail:Stop()
			end
		end
	end

end


function SyncedLUVBot:StateChangeExploding(initing, lastState)

	if initing then
		self.explodingClock:Reset()
		--Remove the bot from the physical world
		if IsValid(self.physicalBot) then
			self.physicalBot:UnInit()
			self.physicalBot = nil
		end
		if IsClient() then
			local emitPoint = WVector3()
			if IsValid(self.graphicalBot) then
			    emitPoint = self.graphicalBot:GetPosition()
			end
			if lastState == self.SLB_LATCHED and IsValid(self:GetBotTarget()) then
				emitPoint = self:GetBotTarget():GetPosition()
			end
			--Stop run sound
			if IsValid(self.runSound) then
			    self.runSound:Stop()
			end
            --Play explode sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Mine_Explose.wav", emitPoint, 10, 6, true, SoundSystem.MEDIUM)
			--Show the explode effect
			GetParticleSystem():AddEffect("luvsplosion", emitPoint)
			--Done with the graphical bot
			self:UnInitGraphical()
		end
	end

end


function SyncedLUVBot:StateChangeExploded(initing, lastState)

	if IsServer() then
		--The bot has completely exploded, it is dead
		self:SetWeaponDead()
	end

end


function SyncedLUVBot:PlayerInvalid(player)

	--Check if the invalid player is the latched or target player
	if IsClient() then
	else
		if player:GetUniqueID() == self.currentTargetID then
			--No more target
			self:SetBotTarget(0)
		end
		if self.state == self.SLB_LATCHED then
			 self:KaBoom()
		end
	end

	--BRIAN TODO: Handle cases where GetOwner() is called

end


function SyncedLUVBot:NotifyDebugDrawEnabled(enabled)

	self.debugDrawEnabled = enabled
	if IsValid(self.clientRenderer) then
		self.clientRenderer:SetVisible(enabled)
	end
	if IsValid(self.serverRenderer) then
		self.serverRenderer:SetVisible(enabled)
	end

end


--SYNCEDLUVBOT CLASS END