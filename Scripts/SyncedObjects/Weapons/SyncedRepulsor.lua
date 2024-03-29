UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")
UseModule("AchievementManager", "Scripts/")

--SYNCEDREPULSOR CLASS START

--SyncedRepulsor
class 'SyncedRepulsor' (ISyncedWeapon)

function SyncedRepulsor:__init() super()

    self.achievements = AchievementManager()

	self.graphicalRepulsor = nil
	self.repulsorSensor = nil

	self.objectRepulsorForce = 3000
	self.objectRepulsorUpForce = 1500
	self.repulsorInfluenceDistance = 20

	--Keep track of how long it stays alive
	self.aliveClock = WTimer()
	self.aliveTimer = 6
	self.updateClock = 0
	self.updateTimer = 1/20

    --Audio params
    self.repulsorVolume = 1.0

	--Not used yet
	self.SRS_NOT_USED = 0
	--Used, detached
	self.SRS_DETACHED = 1
	self.state = self.SRS_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.SRS_NOT_USED] = { SyncedRepulsor.StateChangeNotUsed, SyncedRepulsor.ProcessStateNotUsed }
	self.stateFuncs[self.SRS_DETACHED] = { SyncedRepulsor.StateChangeDetached, SyncedRepulsor.ProcessStateDetached }

end


function SyncedRepulsor:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedRepulsor", "ISyncedWeapon", "")

end


function SyncedRepulsor:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetRepulsorState", "SetRepulsorState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("RepulsorState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("RepulsorState_" .. tostring(self:GetID()))
		self:SetRepulsorState(self.state)
	end

end


function SyncedRepulsor:UnInitWeapon()

	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("RepulsorState_" .. tostring(self:GetID()))
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
		self:UnInitSounds()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedRepulsor:InitGraphical()

	self.graphicalRepulsor = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "repulsor.mesh"))
	self.graphicalRepulsor:SetName("RepulsorModel")
	self.graphicalRepulsor:Init(params)
	self.graphicalRepulsor:SetCastShadows(false)
	self.graphicalRepulsor:SetReceiveShadows(false)

    if IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetController()) then
        --Attach the repulsor to the controller
        self.graphicalRepulsor:AttachToParentSceneNode(self:GetOwner():GetController():GetSceneNode())
    end

	--The idle animation for the repulsor model
	self.repulsorIdle = self.graphicalRepulsor:GetAnimation("idle", true)
	self.repulsorIdle:Play()
	
	-- Check for use the force achievement
	local i = 1
	local numAffected = 0
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	while IsValid(self:GetOwner()) and i < (numPlayers + 1) do
	    local player = GetPlayerManager():GetPlayer(i)
	    if (player:GetPosition() - self:GetOwner():GetPosition()):Length() < self.repulsorInfluenceDistance then
             numAffected = numAffected + 1
	    end
	    i = i + 1
    end
    print("Players repulsed: "..numAffected)
    local owner = self:GetOwner()
    if numAffected > 5 and IsValid(owner) and owner == GetPlayerManager():GetLocalPlayer() then
	    self.achievements:Unlock(self.achievements.AVMT_USE_THE_FORCE)
    end

end


function SyncedRepulsor:UnInitGraphical()

	if IsValid(self.graphicalRepulsor) then
		self.graphicalRepulsor:UnInit()
		self.graphicalRepulsor = nil
	end
	self.repulsorIdle = nil

end


function SyncedRepulsor:InitSounds()

	self.repulsorSound = SoundSource()
	self.repulsorSound:SetName(self.name .. "Sound")
	self.repulsorSound:Init(Parameters())
	self.repulsorSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Repulsor_Loop.wav"))
	self.repulsorSound:SetLooping(true)
	self.repulsorSound:SetVolume(self.repulsorVolume)
	self.repulsorSound:SetReferenceDistance(10)

	if IsValid(self:GetOwner()) then
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Repulsor_Start.wav", self:GetOwner():GetPosition(), 10, 1, true, SoundSystem.MEDIUM)
	end

	self.endSoundPlayed = false

end


function SyncedRepulsor:UnInitSounds()

	if IsValid(self.repulsorSound) then
		self.repulsorSound:UnInit()
		self.repulsorSound = nil
	end

end


function SyncedRepulsor:InitPhysical()

	self.repulsorSensor = BulletSensor()
	self.repulsorSensor:SetName(self.name .. "Sensor")
	local params = Parameters()
	local detachPos = WVector3()
	local forwardQuat = WQuaternion()
    if IsValid(self:GetOwner()) then
        detachPos = WVector3(self:GetOwner():GetPosition())
        forwardQuat = WQuaternion(self:GetOwner():GetOrientation())
    end
	params:AddParameter(Parameter("Position", detachPos))
	params:AddParameter(Parameter("Shape", "Sphere"))
	params:AddParameter(Parameter("Dimensions", WVector3(self.repulsorInfluenceDistance, self.repulsorInfluenceDistance, self.repulsorInfluenceDistance)))
	self.repulsorSensor:Init(params)

end


function SyncedRepulsor:UnInitPhysical()

	if IsValid(self.repulsorSensor) then
		self.repulsorSensor:UnInit()
		self.repulsorSensor = nil
	end

end


function SyncedRepulsor:SetRepulsorState(newState)

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("RepulsorState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true)

end


function SyncedRepulsor:GetWeaponActive()

	return self.state == self.SRS_DETACHED

end


function SyncedRepulsor:DoesWeaponOwn(ownObjectID)

	if IsClient() then
		if self.graphicalRepulsor:GetID() == ownObjectID then
			return true
		end
	end

	return false

end


function SyncedRepulsor:SetWeaponStateData(stateBuiltTime, setState)

end


function SyncedRepulsor:GetWeaponStateData(returnState)

end


function SyncedRepulsor:UseItemUp(pressed, extraData)

	if IsServer() and self.state == self.SRS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedRepulsor:UseItemDown(pressed, extraData)

	if IsServer() and self.state == self.SRS_NOT_USED then
		if pressed then
			self:Detach()
		end
	end

end


function SyncedRepulsor:SetWeaponParameter(param)

end


function SyncedRepulsor:EnumerateWeaponParameters(params)

end


--The Repulsor should detach from the kart it is following
function SyncedRepulsor:Detach()

	if self.state == self.SRS_NOT_USED then
		self:SetRepulsorState(self.SRS_DETACHED)
	end

end


function SyncedRepulsor:ProcessSyncedObject(frameTime)

	--Process the current state
	self.stateFuncs[self.state][2](self, frameTime)

	if IsValid(self.repulsorSensor) and IsValid(self:GetOwner()) then
		self.repulsorSensor:SetPosition(self:GetOwner():GetPosition())
		self.repulsorSensor:Process(frameTime)
	end

	if IsValid(self.graphicalRepulsor) then
		self.graphicalRepulsor:Process(frameTime)
		self.repulsorIdle:Process(frameTime)
		if IsValid(self:GetOwner()) then
			self.repulsorSound:SetPosition(self:GetOwner():GetPosition())
		end
		self.repulsorSound:Process(frameTime)
	end

end


--State process functions below
function SyncedRepulsor:ProcessStateNotUsed(frameTime)

end


function SyncedRepulsor:ProcessStateDetached(frameTime)

	if IsServer() then
		if self.aliveClock:GetTimeSeconds() > self.aliveTimer then
			self:SetWeaponDead()
		else
		    --Limiter
            self.updateClock = self.updateClock + frameTime
            while self.updateClock >= self.updateTimer do
                self.updateClock = self.updateClock - self.updateTimer
                self:ProcessRepulse(self.updateTimer)
            end
		end
	else
        self:ProcessScale(frameTime)
	end

end


function SyncedRepulsor:ProcessScale(frameTime)

    local alive = self.aliveClock:GetTimeSeconds()
	local timeLeft = self.aliveTimer - alive
    local ft = 0.5
    if self.aliveClock:GetTimeSeconds() < ft then
        self.graphicalRepulsor:SetScale(WVector3(alive/ft, alive/ft, alive/ft))
        self.repulsorSound:SetVolume(alive/ft*self.repulsorVolume)
    elseif timeLeft <= ft then
        if not self.endSoundPlayed and IsValid(self:GetOwner()) then
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Repulsor_End.wav", self:GetOwner():GetPosition(), 10, 1, true, SoundSystem.MEDIUM)
            self.endSoundPlayed = true
        end
        --print("Scaling twister:"..timeLeft)
        self.graphicalRepulsor:SetScale(WVector3(timeLeft/ft, timeLeft/ft, timeLeft/ft))
        self.repulsorSound:SetVolume(timeLeft/ft*self.repulsorVolume)
    end

end

function SyncedRepulsor:ProcessRepulse(frameTime)

    if IsValid(self.repulsorSensor) then

        local iter = self.repulsorSensor:GetIterator()
        while not iter:IsEnd() do
            local currentObject = iter:Get()
            self:ProcessRepulseOnObject(currentObject, frameTime)
            iter:Next()
        end
	
	end

end


function SyncedRepulsor:ProcessRepulseOnObject(repulseObject, frameTime)

    if not self:GetOwner():DoesOwn(repulseObject:GetID()) then
        
        local distance = repulseObject:GetPosition():Distance(self.repulsorSensor:GetPosition())
        
        if distance < self.repulsorInfluenceDistance then    
            local influencePercent = 1/(distance/self.repulsorInfluenceDistance)
            local direction = repulseObject:GetPosition() - self.repulsorSensor:GetPosition()
            direction:Normalise()

            local currobjectRepulsorForce = self.objectRepulsorForce * (repulseObject:GetMass() / 400)
            local force = direction * ((influencePercent * currobjectRepulsorForce) * frameTime)
            --print("Repulsing "..repulseObject:GetName()..":"..tostring(force))
            --Add some upward force
            local currobjectRepulsorUpForce = self.objectRepulsorUpForce * (repulseObject:GetMass() / 400)
            force = force + WVector3(0, ((influencePercent * currobjectRepulsorUpForce) * frameTime), 0)
            repulseObject:ApplyWorldImpulse(force, WVector3())
        end
    end

end


--State change functions below
function SyncedRepulsor:StateChangeNotUsed(initing)

end


function SyncedRepulsor:StateChangeDetached(initing)

	if initing then
		self:SetWeaponUsed()
		self:InitPhysical()
		if IsClient() then
			self:InitGraphical()
			self:InitSounds()
			self.repulsorSound:Play()
		end
		self.aliveClock:Reset()
	end

end

function SyncedRepulsor:PlayerInvalid(invalidPlayer)

    --Only kill the weapon if it's owner is invalid
	if not IsValid(self:GetOwner()) or self:GetOwner():GetUniqueID() == invalidPlayer:GetUniqueID() then
		self:SetWeaponDead()
	end

end


--SYNCEDREPULSOR CLASS END