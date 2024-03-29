UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")

--SYNCEDTWISTER CLASS START

--SyncedTwister
class 'SyncedTwister' (ISyncedWeapon)

function SyncedTwister:__init() super()

	self.graphicalTwister = nil
	self.graphicalTwisterFX = nil
	self.physicalTwister = nil
	self.twisterSensor = nil

	self.throwTwisterForce = 8000
	self.throwTwisterUpForce = 1500
	self.moveTwisterForce = 2000
	self.objectTwisterForce = 8000
	self.objectTwisterUpForce = 12000
	self.objectTwisterTwistForce = 400
	self.twisterInfluenceDistance = 20

	self.moveDirection = WVector3()
	self.moveClock = WTimer()
	self.moveTimer = 1
    self.updateClock = 0
    self.updateTimer = 1/20
    
	self.active = false
	self.activeClock = WTimer()
	self.activeTimer = 1

    self.idealScale = WVector3(1, 1, 1)
	self.startScale = false
	self.scaleClock = WTimer()
    self.endScaleTime = 0.2

	--Keep track of how long it stays alive
	self.aliveClock = WTimer()
	self.aliveTimer = 6

    --Audio params
    self.twisterVolume = 0.75

	--Not used yet
	self.STS_NOT_USED = 0
	--Used, detached
	self.STS_DETACHED = 1
	self.state = self.STS_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.STS_NOT_USED] = { SyncedTwister.StateChangeNotUsed, SyncedTwister.ProcessStateNotUsed }
	self.stateFuncs[self.STS_DETACHED] = { SyncedTwister.StateChangeDetached, SyncedTwister.ProcessStateDetached }

end


function SyncedTwister:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedTwister", "ISyncedWeapon", "")

end


function SyncedTwister:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetTwisterState", "SetTwisterState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("TwisterState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("TwisterState_" .. tostring(self:GetID()))
		self:SetTwisterState(self.state)
	end

end


function SyncedTwister:UnInitWeapon()

	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("TwisterState_" .. tostring(self:GetID()))
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
		self:UnInitSounds()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedTwister:InitGraphical()

	self.graphicalTwisterFX = OGREParticleEffect()
	local params = Parameters()
	params:AddParameter(Parameter("ResourceName", "tornado"))
	params:AddParameter(Parameter("Loop", true))
	params:AddParameter(Parameter("StartOnLoad", false))
	self.graphicalTwisterFX:SetName("TwisterEffect" .. tostring(GenerateID()))
	self.graphicalTwisterFX:Init(params)
	self.graphicalTwisterFX:SetScale(WVector3(0, 0, 0))

	self.graphicalTwister = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "twister.mesh"))
	self.graphicalTwister:SetName("TwisterModel")
	self.graphicalTwister:Init(params)
	self.graphicalTwister:SetCastShadows(false)
	self.graphicalTwister:SetReceiveShadows(false)
	self.graphicalTwister:SetVisible(false)
	self.graphicalTwister:SetScale(WVector3(0, 0, 0))

	--The idle animation for the twister model indicator
	self.twisterIdle = self.graphicalTwister:GetAnimation("idle", true)
	self.twisterIdle:Play()

end


function SyncedTwister:UnInitGraphical()

	if IsValid(self.graphicalTwisterFX) then
		self.graphicalTwisterFX:UnInit()
		self.graphicalTwisterFX = nil
	end

	if IsValid(self.graphicalTwister) then
		self.graphicalTwister:UnInit()
		self.graphicalTwister = nil
	end
	self.twisterModelIdle = nil

end


function SyncedTwister:InitSounds()

	self.twisterSound = SoundSource()
	self.twisterSound:SetName(self.name .. "Sound")
	self.twisterSound:Init(Parameters())
	self.twisterSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/tornado.wav"))
	self.twisterSound:SetLooping(true)
	self.twisterSound:SetVolume(self.twisterVolume)
	self.twisterSound:SetReferenceDistance(20)

end


function SyncedTwister:UnInitSounds()

	if IsValid(self.twisterSound) then
		self.twisterSound:UnInit()
		self.twisterSound = nil
	end

end


function SyncedTwister:InitPhysical()

	--The physical entity
	self.physicalTwister = BulletSphere()
	self.physicalTwister:SetName(self.name)
	local params = Parameters()
	local detachPos = WVector3()
	local forwardQuat = WQuaternion()
    if IsValid(self:GetOwner()) then
        detachPos = WVector3(self:GetOwner():GetPosition())
        forwardQuat = WQuaternion(self:GetOwner():GetOrientation())
    end
	--local forwardNormal = forwardQuat:zAxis()
	local forwardNormal = self.aimNormal
    if self.thrown then
		detachPos = detachPos + (forwardNormal * 2)
	else
		detachPos = detachPos - (forwardNormal * 2)
	end
	detachPos.y = detachPos.y + 1.5
	params:AddParameter(Parameter("Position", detachPos))
	params:AddParameter(Parameter("Dimensions", WVector3(0.25, 0.25, 0.25)))
	params:AddParameter(Parameter("Friction", 0.25))
	params:AddParameter(Parameter("Restitution", 0))
	params:AddParameter(Parameter("Mass", 300))
	params:AddParameter(Parameter("AngularDamping", 0.75))
	params:AddParameter(Parameter("LinearDamping", 0.25))
	self.physicalTwister:Init(params)

	self.twisterSensor = BulletSensor()
	self.twisterSensor:SetName(self.name .. "Sensor")
	local params = Parameters()
	params:AddParameter(Parameter("Position", detachPos))
	params:AddParameter(Parameter("Shape", "Sphere"))
	params:AddParameter(Parameter("Dimensions", WVector3(self.twisterInfluenceDistance, self.twisterInfluenceDistance, self.twisterInfluenceDistance)))
	self.twisterSensor:Init(params)

end


function SyncedTwister:UnInitPhysical()

	if IsValid(self.physicalTwister) then
		self.physicalTwister:UnInit()
		self.physicalTwister = nil
	end

	if IsValid(self.twisterSensor) then
		self.twisterSensor:UnInit()
		self.twisterSensor = nil
	end

end


function SyncedTwister:SetTwisterState(newState)

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("TwisterState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true)

end


function SyncedTwister:DoesWeaponOwn(ownObjectID)

	if self.physicalTwister:GetID() == ownObjectID then
		return true
	end
	if IsClient() then
		if self.graphicalTwister:GetID() == ownObjectID then
			return true
		end
	end

	return false

end


function SyncedTwister:NotifyPositionChange(setPos)

    if IsValid(self.graphicalTwister) then
		self.graphicalTwister:SetPosition(setPos)
		self.graphicalTwisterFX:SetPosition(setPos)
		self.twisterSound:SetPosition(setPos)
		
		--Now we know we have valid state
        if not self.graphicalTwister:GetVisible() then
            self.graphicalTwister:SetVisible(true)
            self.startScale = true
            self.scaleClock:Reset()
        end
	end

	if IsValid(self.physicalTwister) then
		self.physicalTwister:SetPosition(setPos)
	end

end


function SyncedTwister:NotifyOrientationChange(setOrien)

	--Note: Do not modify the graphical orientation

	if IsValid(self.physicalTwister) then
		self.physicalTwister:SetOrientation(setOrien)
	end

end


function SyncedTwister:GetPosition()

	if IsClient() then
		return self.graphicalTwister:GetPosition()
	end
	return self.physicalTwister:GetPosition()

end


function SyncedTwister:GetOrientation()

	if IsClient() then
		return self.graphicalTwister:GetOrientation()
	end
	return self.physicalTwister:GetOrientation()

end


function SyncedTwister:GetWeaponActive()

	if IsValid(self.physicalTwister) then
	    return not self.physicalTwister:GetSleeping()
	end
	return false

end


function SyncedTwister:SetWeaponStateData(stateBuiltTime, setState)

	local pos = setState:ReadWVector3()
	--local vel = setState:ReadWVector3()

	if IsValid(self.physicalTwister) then
		self.physicalTwister:SetPosition(pos)
		--self.physicalTwister:SetLinearVelocity(vel)
	end

	--We must update the transform of this object now so the ClientWorld can lerp properly
	self:SetPosition(pos, false)

end


function SyncedTwister:GetWeaponStateData(returnState)

	if IsValid(self.physicalTwister) then
		returnState:WriteWVector3(self.physicalTwister:GetPosition())
		--returnState:WriteWVector3(self.physicalTwister:GetLinearVelocity())
	end

end


function SyncedTwister:UseItemUp(pressed, extraData)

	if IsServer() and self.state == self.STS_NOT_USED then
		if pressed then
			self:Throw()
		end
	end

end


function SyncedTwister:UseItemDown(pressed, extraData)

	if IsServer() and self.state == self.STS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedTwister:SetWeaponParameter(param)

end


function SyncedTwister:EnumerateWeaponParameters(params)

end


--The Twister should detach from the kart it is following
function SyncedTwister:Detach()

	if self.state == self.STS_NOT_USED then
		self.thrown = false
		self:SetTwisterState(self.STS_DETACHED)
	end

end


function SyncedTwister:Throw()

	if self.state == self.STS_NOT_USED then
		self.thrown = true
		self:SetTwisterState(self.STS_DETACHED)
		--First match the velocity of the thrower
		self.physicalTwister:SetLinearVelocity(self:GetOwner():GetLinearVelocity())
		--Throw the Twister forward now
		local forwardQuat = self:GetOwner():GetOrientation()
		--local forwardNormal = forwardQuat:zAxis()
		local forwardNormal = self.aimNormal
        local force = forwardNormal * self.throwTwisterForce
		--Add some upward force
		--BRIAN TODO: Account for different gravity
		force = force + WVector3(0, self.throwTwisterUpForce, 0)
		self.physicalTwister:ApplyWorldImpulse(force, WVector3())
	end

end


function SyncedTwister:ProcessSyncedObject(frameTime)

	--Process the current state
	self.stateFuncs[self.state][2](self, frameTime)

	if IsValid(self.physicalTwister) then
		self.physicalTwister:Process(frameTime)
		self:SetPosition(self.physicalTwister:GetPosition(), false)
        self:SetOrientation(self.physicalTwister:GetOrientation(), false)
        self:SetLinearVelocity(self.physicalTwister:GetLinearVelocity(), false)
	end

	if IsValid(self.graphicalTwister) then
		self.graphicalTwister:Process(frameTime)
		self.graphicalTwisterFX:Process(frameTime)
		self.twisterIdle:Process(frameTime)
		self.twisterSound:Process(frameTime)

		if self.startScale then
	        local lerpAmount = math.min(1, self.scaleClock:GetTimeSeconds() / self.endScaleTime)
	        local lerpedScale = WVector3Lerp(lerpAmount, WVector3(), self.idealScale)
	        self.graphicalTwister:SetScale(lerpedScale)
	        self.graphicalTwisterFX:SetScale(lerpedScale)
	        if lerpAmount == 1 then
	            self.startScale = false
	        end
        end
	end

end


--State process functions below
function SyncedTwister:ProcessStateNotUsed(frameTime)

end


function SyncedTwister:ProcessStateDetached(frameTime)

	if IsServer() then
		if self.aliveClock:GetTimeSeconds() > self.aliveTimer then
			self:SetWeaponDead()
		else
			if not self.active then
				if self.activeClock:GetTimeSeconds() > self.activeTimer then
					self.active = true
				end
			end
			if self.active then
			    --Limiter
			    self.updateClock = self.updateClock + frameTime
			    while self.updateClock >= self.updateTimer do
			        self.updateClock = self.updateClock - self.updateTimer
			        if IsValid(self.twisterSensor) then
		                self.twisterSensor:SetPosition(self.physicalTwister:GetPosition())
		                self.twisterSensor:Process(self.updateTimer)
                	end

				    self:ProcessMove(self.updateTimer)
				    self:ProcessSuck(self.updateTimer)
				end
			end
		end
	else
        self:ProcessScale(frameTime)
	end

end


function SyncedTwister:ProcessMove(frameTime)

	--BRIAN TODO: Only works with default UP vector 0, 1, 0
	if self.moveClock:GetTimeSeconds() > self.moveTimer then
		self.moveClock:Reset()
		--Add a random inpulse
		self.moveDirection.x = self.physicalTwister:GetPosition().x + (math.random() - 0.5)
		self.moveDirection.z = self.physicalTwister:GetPosition().z + (math.random() - 0.5)
		local force = (self.moveDirection - self.physicalTwister:GetPosition())
		force.y = 0
		force:Normalise()
		force = force * self.moveTwisterForce
		self.physicalTwister:ApplyWorldImpulse(force, WVector3())
	end

end


function SyncedTwister:ProcessScale(frameTime)

	local timeLeft = self.aliveTimer - self.aliveClock:GetTimeSeconds()
    local ft = 2.5
    if timeLeft <= ft then
        self.graphicalTwister:SetScale(WVector3(timeLeft/ft, timeLeft/ft, timeLeft/ft))
        self.twisterSound:SetVolume(timeLeft/ft*self.twisterVolume)
    end

end


function SyncedTwister:ProcessSuck(frameTime)

	local iter = self.twisterSensor:GetIterator()
	while not iter:IsEnd() do
		local currentObject = iter:Get()
		self:ProcessSuckOnObject(currentObject, frameTime)
		iter:Next()
	end

end


function SyncedTwister:ProcessSuckOnObject(suckObject, frameTime)

	--Dont suck this twister
	if suckObject:GetID() ~= self.physicalTwister:GetID() then
		local distance = suckObject:GetPosition():Distance(self.twisterSensor:GetPosition())
		local influencePercent = 1 - (distance / self.twisterInfluenceDistance)
		local direction = self.twisterSensor:GetPosition() - suckObject:GetPosition()
		direction:Normalise()

		local currObjectTwisterForce = self.objectTwisterForce * (suckObject:GetMass() / 400)
		local force = direction * ((influencePercent * currObjectTwisterForce) * frameTime)
		--Add some upward force
		local currObjectTwisterUpForce = self.objectTwisterUpForce * (suckObject:GetMass() / 400)
		force = force + WVector3(0, ((influencePercent * currObjectTwisterUpForce) * frameTime), 0)
		suckObject:ApplyWorldImpulse(force, WVector3())

		--Add some torque because it is a TWISTER!
		local up = self.physicalTwister:GetGravity()
		up:Negate()
		up:Normalise()
		suckObject:ApplyWorldTorqueImpulse(up * ((influencePercent * self.objectTwisterTwistForce) * frameTime))
	end

end


--State change functions below
function SyncedTwister:StateChangeNotUsed(initing)

end


function SyncedTwister:StateChangeDetached(initing)

	if initing then
		self:SetWeaponUsed()
		self:InitPhysical()
		if IsClient() then
			self:InitGraphical()
			self:InitSounds()
			self.graphicalTwisterFX:Start()
			self.twisterSound:Play()
			local throwPos = WVector3()
			throwPos = WVector3()
            if IsValid(self:GetOwner()) then
                throwPos = self:GetOwner():GetPosition()
            end
			--Play throw sound
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Throw.wav", throwPos, 7, 1, true, SoundSystem.MEDIUM)
		end
		self.moveClock:Reset()
		self.activeClock:Reset()
		self.aliveClock:Reset()
	end

end


--SYNCEDTWISTER CLASS END