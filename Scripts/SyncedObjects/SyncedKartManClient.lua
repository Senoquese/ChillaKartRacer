
UseModule("IKart", "Scripts/")
UseModule("AchievementManager", "Scripts/")

--SYNCEDKARTMANCLIENT CLASS START

--BRIAN TODO: Don't use IKart anymore probably...
class 'SyncedKartManClient' (IKart)

function SyncedKartManClient:__init(setKartObject, setPhysicalKart) super()

	self.kartObject = setKartObject
    self.physicalKart = setPhysicalKart

    self.achievements = AchievementManager()

	--The engine sound state variables
	self.engineSound = nil
	self.soundsMuted = false
	self.engineOffVol = 0.3
	self.engineOnVol = 0.7
	--How much the engine volume will change per second
	self.engineVolStep = 2
	self.currentEngineVol = self.engineOffVol
	self.engineVolClock = WTimer()

	--The handbrake skid sound state variables
	--self.handbrakeIntroSound = nil
	self.handbrakeSound = nil

	--This is true when the server kart is currently being boosted
	self.boostEnabled = false

    self.draftSound = nil

	self:InitBoostParticles()
    self:InitDraftModel()
    
    self.isLocalPlayer = false

end


function SyncedKartManClient:UnInitIBase()

	IKart.UnInitIBase(self)

	self:UnInitBoostParticles()
	self:UnInitDraftModel()
	self:UnInitSounds()

end


function SyncedKartManClient:InitBoostParticles()

	self.boostParticles = { OGREParticleEffect(), OGREParticleEffect() }
	local boostParams = Parameters()
	boostParams:AddParameter(Parameter("ResourceName", "boost"))
	boostParams:AddParameter(Parameter("Loop", true))
	boostParams:AddParameter(Parameter("StartOnLoad", false))

	self.boostParticles[1]:SetName("wheel1BoostParticle" .. tostring(GenerateID()))
	self.boostParticles[1]:Init(boostParams)
	self.boostParticles[2]:SetName("wheel2BoostParticle" .. tostring(GenerateID()))
	self.boostParticles[2]:Init(boostParams)

end


function SyncedKartManClient:UnInitBoostParticles()

	if IsValid(self.boostParticles[1]) then
		self.boostParticles[1]:UnInit()
		self.boostParticles[1] = nil
	end

	if IsValid(self.boostParticles[2]) then
		self.boostParticles[2]:UnInit()
		self.boostParticles[2] = nil
	end

end


function SyncedKartManClient:InitDraftModel()

	self.graphicalDraft = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "draft.mesh"))
	self.graphicalDraft:SetName("DraftModel_" .. tostring(GenerateID()))
	self.graphicalDraft:Init(params)
	self.graphicalDraft:SetCastShadows(false)
	self.graphicalDraft:SetReceiveShadows(false)

    if IsValid(self.kartObject:GetSceneNode()) then
        --Attach the draft model to the kart
        self.graphicalDraft:AttachToParentSceneNode(self.kartObject:GetSceneNode())
    end

	self.draftIdle = self.graphicalDraft:GetAnimation("idle", true)
	self.graphicalDraft:SetVisible(false)
    --self.draftIdle:Play()
	
end


function SyncedKartManClient:UnInitDraftModel()

    if IsValid(self.graphicalDraft) then
		self.graphicalDraft:UnInit()
		self.graphicalDraft = nil
	end
	self.draftIdle = nil

end


function SyncedKartManClient:EnableDraft(draft)

    if draft > 0 then
        if IsValid(self.graphicalDraft) then
            if not self.graphicalDraft:GetVisible() then
                self.graphicalDraft:SetVisible(true)
                if IsValid(self.draftIdle) and IsValid(self.draftSound) then
                    self.draftIdle:Play()
                    self.draftSound:Play()
                end
            end

			--Note: The value below needs to be changed if the draft process rate changes on the server, eewww
            local d = draft*100
            if IsValid(self.draftSound) then
                self.draftSound:SetVolume(d)
            end
            self.graphicalDraft:GetMaterial():SetDiffuse(WColorValue(d,d,d,1))
        end
    else
        if IsValid(self.graphicalDraft) then
            self.graphicalDraft:SetVisible(false)
            if IsValid(self.draftIdle) and IsValid(self.draftSound) then
                self.draftIdle:Stop()
                self.draftSound:Stop()
            end
        end
    end

end


function SyncedKartManClient:ProcessDraft(frameTime)

    if IsValid(self.graphicalDraft) and self.graphicalDraft:GetVisible() then
        self.draftIdle:Process(frameTime)
    end

end


function SyncedKartManClient:InitSounds(isLocalPlayer)

    self.isLocalPlayer = isLocalPlayer

	--Engine Sound
	local soundParams = Parameters()
	self.engineSound = SoundSource()
	self.engineSound:SetName("engineSound" .. self.kartObject:GetName())
	if isLocalPlayer then
        self.engineSound:SetPriority(SoundSystem.HIGHEST)
	else
	    self.engineSound:SetPriority(SoundSystem.HIGH)
	end
    self.engineSound:Init(soundParams)
	self.engineSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Engine_1.wav"))
	self.engineSound:SetLooping(true)
	--Start off with no volume, the volume will be set during processing
	self.engineSound:SetVolume(0)
	self.engineSound:SetMute(self.soundsMuted)
	self.engineSound:Play()

	--Handbrake Skid Sound
	self.handbrakeSound = SoundSource()
	self.handbrakeSound:SetName("handbrakeSound" .. self.kartObject:GetName())
	self.handbrakeSound:SetPriority(SoundSystem.LOW)
	self.handbrakeSound:Init(soundParams)
	self.handbrakeSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Screech_1.wav"))
	self.handbrakeSound:SetLooping(false)
	self.handbrakeSound:SetVolume(1)
	self.handbrakeSound:SetMute(self.soundsMuted)

	--Boost Start Sound
	self.boostStartSound = SoundSource()
	self.boostStartSound:SetName("boostStartSound" .. self.kartObject:GetName())
	if isLocalPlayer then
        self.boostStartSound:SetPriority(SoundSystem.HIGH)
	else
	    self.boostStartSound:SetPriority(SoundSystem.MEDIUM)
	end
	self.boostStartSound:Init(soundParams)
	self.boostStartSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Boost_Start.wav"))
	self.boostStartSound:SetLooping(false)
	self.boostStartSound:SetVolume(1)
	self.boostStartSound:SetMute(self.soundsMuted)

	--Boost Loop Sound
	self.boostLoopSound = SoundSource()
	self.boostLoopSound:SetName("boostLoopSound" .. self.kartObject:GetName())
	if isLocalPlayer then
        self.boostLoopSound:SetPriority(SoundSystem.HIGH)
	else
	    self.boostLoopSound:SetPriority(SoundSystem.MEDIUM)
	end
	self.boostLoopSound:Init(soundParams)
	self.boostLoopSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Boost_Cont.wav"))
	self.boostLoopSound:SetLooping(true)
	self.boostLoopSound:SetVolume(1)
    self.boostLoopSound:SetMute(self.soundsMuted)

    --Draft Loop Sound
    self.draftSound = SoundSource()
	self.draftSound:SetName("draftSound" .. self.kartObject:GetName())
	if self.isLocalPlayer then
        self.draftSound:SetPriority(SoundSystem.HIGH)
	else
	    self.draftSound:SetPriority(SoundSystem.MEDIUM)
	end
	self.draftSound:Init(soundParams)
	self.draftSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Draft.wav"))
	self.draftSound:SetLooping(true)
	self.draftSound:SetVolume(1)
	self.draftSound:SetMute(self.soundsMuted)

	--Attach the sounds to the kart
	self.kartObject:GetSignal("SetTransform", true):Connect(self.engineSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.handbrakeSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.boostStartSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.boostLoopSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.draftSound:GetSlot("SetTransform", true))
		
	self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")
	self.physicalKart:GetSignal("StartCollision", true):Connect(self.collisionStartSlot)

end


function SyncedKartManClient:UnInitSounds()

	if IsValid(self.engineSound) then
		self.engineSound:UnInit()
		self.engineSound = nil
	end

	if IsValid(self.handbrakeSound) then
		self.handbrakeSound:UnInit()
		self.handbrakeSound = nil
	end

	if IsValid(self.boostStartSound) then
		self.boostStartSound:UnInit()
		self.boostStartSound = nil
	end

	if IsValid(self.boostLoopSound) then
		self.boostLoopSound:UnInit()
		self.boostLoopSound = nil
	end

    if IsValid(self.draftSound) then
		self.draftSound:UnInit()
		self.draftSound = nil
	end

end


function SyncedKartManClient:SetMuteSounds(setMute)

	self.soundsMuted = setMute

    if IsValid(self.engineSound) then
	    self.engineSound:SetMute(self.soundsMuted)
	end
	if IsValid(self.handbrakeSound) then
	    self.handbrakeSound:SetMute(self.soundsMuted)
	end
	if IsValid(self.boostStartSound) then
	    self.boostStartSound:SetMute(self.soundsMuted)
	end
	if IsValid(self.boostLoopSound) then
	    self.boostLoopSound:SetMute(self.soundsMuted)
	end
	if IsValid(self.draftSound) then
	    self.draftSound:SetMute(self.soundsMuted)
	end

end


function SyncedKartManClient:GetMuteSounds()

	return self.soundsMuted

end


function SyncedKartManClient:LandEvent(speed)
    --Play the poof sound and particle effect at the old position
    local pos = self.kartObject:GetPosition()
    --EmitSound(filename, position, volume, referenceDistance, global, priority)
   
    local wavFile = GetClientManager():GetCollisionSoundName()
    --print(wavFile)
    GetSoundSystem():EmitSound(wavFile, pos, speed/10, 10, true, SoundSystem.MEDIUM)
    if speed > 8 then
        GetParticleSystem():AddEffect("poof", pos)
    end

end

function SyncedKartManClient:GetCollisionSoundName()
    local collisionWavName = ASSET_DIR .. "sound/"
	local wavFiles = { "Kart_to_wall_1.wav", "Kart_to_wall_2.wav", "Kart_to_wall_3.wav" }
	local wavChoice = math.random(1, #wavFiles)
	collisionWavName = collisionWavName .. wavFiles[wavChoice]
	return tostring(collisionWavName)
end

function SyncedKartManClient:GetKartCollisionSoundName()
    local collisionWavName = ASSET_DIR .. "sound/"
	local wavFiles = {"Kart_to_kart_1.wav", "Kart_to_kart_2.wav", "Kart_to_kart_3.wav" }
	local wavChoice = math.random(1, #wavFiles)
	collisionWavName = collisionWavName .. wavFiles[wavChoice]
	return tostring(collisionWavName)
end

function SyncedKartManClient:BulletCollisionStart(collParams)

	local collidePosition = WVector3()
	collidePosition.x = collParams:GetParameter("ImpactX", true):GetFloatData()
	collidePosition.y = collParams:GetParameter("ImpactY", true):GetFloatData()
	collidePosition.z = collParams:GetParameter("ImpactZ", true):GetFloatData()
	local appliedImpulse = collParams:GetParameter("AppliedImpulse", true):GetFloatData()

	if appliedImpulse > 50 then
		    
        local collisionWavName = self:GetKartCollisionSoundName()
		local volume = appliedImpulse/500
		if appliedImpulse > 200 then
		    GetParticleSystem():AddEffect("impact", collidePosition)
		end
		
		GetSoundSystem():EmitSound(collisionWavName, collidePosition, volume, 10, true, SoundSystem.LOW)
	end

end

function SyncedKartManClient:GetName()

	return self.kartObject:GetName()

end


function SyncedKartManClient:ControlAccel(accelOn)

	self.accelOn = accelOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlAccel(self.accelOn)
	end

end


function SyncedKartManClient:ControlMouseLook(handbrakeOn)

	self.handbrakeOn = handbrakeOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlMouseLook(self.handbrakeOn)
	end

end


function SyncedKartManClient:GetHandbrakeEnabled()

	return self.handbrakeOn

end


function SyncedKartManClient:ControlReverse(reverseOn)

	self.reverseOn = reverseOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlReverse(self.reverseOn)
	end

end


function SyncedKartManClient:ControlRight(rightOn)

	self.rightOn = rightOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlRight(self.rightOn)
	end

end


function SyncedKartManClient:ControlLeft(leftOn)

	self.leftOn = leftOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlLeft(self.leftOn)
	end

end


function SyncedKartManClient:ControlReset()

	if IsValid(self.kartObject) then
		self.kartObject:ControlReset()
	end

end


function SyncedKartManClient:ControlLookBack(lookBackOn)

	self.lookBackOn = lookBackOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlLookBack(self.lookBackOn)
	end

end


--This is called when the user wants to boost
function SyncedKartManClient:ControlBoost(boostOn)

	self.boostOn = boostOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlBoost(self.boostOn)
	end

end


--The boost is enabled when the server kart is actually being boosted
function SyncedKartManClient:SetBoostEnabled(setBoostEnabled)

	self.boostEnabled = setBoostEnabled
	if self.boostEnabled then
	
	    if not IsValid(self.boostStart) then
	        self.boostStart = GetClientSystem():GetTime()
	    end
	
		self.boostParticles[1]:Start()
		self.boostParticles[2]:Start()
		if IsValid(self.boostLoopSound) then
		    self.boostLoopSound:Play()
		end
		if IsValid(self.boostStartSound) then
		    self.boostStartSound:Play()
		end
	else
	    if IsValid(self.boostStart) then
	        if self.isLocalPlayer then
	            local boostDuration = GetClientSystem():GetTime()-self.boostStart
	            print("BoostDuration: "..boostDuration)
	            if boostDuration > 30 then
	                self.achievements:Unlock(self.achievements.AVMT_ROCKET_SAUCE)
	            end
	        end
	        self.boostStart = nil
	    end
	
		self.boostParticles[1]:Stop()
		self.boostParticles[2]:Stop()
		if IsValid(self.boostStartSound) then
		    self.boostStartSound:Stop()
		end
		if IsValid(self.boostLoopSound) then
		    self.boostLoopSound:Stop()
		end
	end

end


function SyncedKartManClient:GetBoostEnabled()

	return self.boostEnabled

end


function SyncedKartManClient:Process(frameTime)

	if IsValid(self.kartObject) then
		self.kartObject:Process(frameTime)

		local engineTimeStep = self.engineVolStep * frameTime

		if self.accelOn or self.reverseOn then
			if self.currentEngineVol < self.engineOnVol then
				self.currentEngineVol = self.currentEngineVol + engineTimeStep
				if self.currentEngineVol > self.engineOnVol then
					self.currentEngineVol = self.engineOnVol
				end
			end
		else
			if self.currentEngineVol > self.engineOffVol then
				self.currentEngineVol = self.currentEngineVol - engineTimeStep
				if self.currentEngineVol < self.engineOffVol then
					self.currentEngineVol = self.engineOffVol
				end
			end
		end

		--If boost is currently enabled, increase the volume of the engine sound
		if IsValid(self.engineSound) then
            if self.boostEnabled then
                self.engineSound:SetVolume(self.currentEngineVol * 3)
            else
                self.engineSound:SetVolume(self.currentEngineVol)
            end
        end

		--Pitch based on current speed
		--Pitch scales between 0.5 and 2.0
		if IsValid(self.engineSound) then
		    self.engineSound:SetPitch(0.5 + (1.35 * math.abs(self.kartObject:GetSpeedPercent())))
		end

		--Change the sound's velocity based on the kart's velocity
		--BRIAN TODO: I don't think this works anymore since the kartObject is
		--a OGREPlayerKart and nowhere is the OGREPlayerKarts velocity set :(
		if IsValid(self.engineSound) and IsValid(self.handbrakeSound) and IsValid(self.boostStartSound) and IsValid(self.boostLoopSound) and IsValid(self.draftSound) then
            self.engineSound:SetVelocity(self.kartObject:GetLinearVelocity())
		    self.handbrakeSound:SetVelocity(self.kartObject:GetLinearVelocity())
		    self.boostStartSound:SetVelocity(self.kartObject:GetLinearVelocity())
		    self.boostLoopSound:SetVelocity(self.kartObject:GetLinearVelocity())
            self.draftSound:SetVelocity(self.kartObject:GetLinearVelocity())
        end

		self:ProcessSounds(frameTime)
		self:ProcessBoostEffects(frameTime)
		self:ProcessDraft(frameTime)
	end

end


function SyncedKartManClient:doTireSqueal(speed)

    --Play the poof sound and particle effect at the old position
    local pos = self.kartObject:GetPosition()
    --EmitSound(filename, position, volume, referenceDistance, global, priority)

    local wavFile = GetClientManager():GetTireSquealSoundName()
    --print(wavFile)
    GetSoundSystem():EmitSound(wavFile, pos, speed / 100, 10, true, SoundSystem.MEDIUM)

end


function SyncedKartManClient:ProcessSounds(frameTime)

	--Handbrake sounds
		--[[
	if self.handbrakeOn then
		if math.abs(self.kartObject:GetCurrentSpeed()) < self.kartObject:GetWheelEffectSpeedThres() then
			--self.handbrakeIntroSound:Pause()
			self.handbrakeSound:Pause()
		else
			if self.handbrakeSound:GetState() ~= SoundSource.PLAYING then
				--self.handbrakeIntroSound:Play()
				self.handbrakeSound:Play()
			end
		end
		--The skid sound will be louder the faster the kart is going
		--self.handbrakeIntroSound:SetVolume(0.5 + (1.5 * math.abs(self.kartObject:GetSpeedPercent())))
		self.handbrakeSound:SetVolume(0.5 + (1.5 * math.abs(self.kartObject:GetSpeedPercent())))
	else
		--self.handbrakeIntroSound:Pause()
		self.handbrakeSound:Pause()
	end
    --]]
    if IsValid(self.engineSound) then
	    self.engineSound:Process(frameTime)
	end
	if IsValid(self.handbrakeSound) then
	    self.handbrakeSound:Process(frameTime)
	end
	if IsValid(self.boostStartSound) then
	    self.boostStartSound:Process(frameTime)
	end
	if IsValid(self.boostLoopSound) then
	    self.boostLoopSound:Process(frameTime)
	end
	if IsValid(self.draftSound) then
        self.draftSound:Process(frameTime)
        self.draftSound:SetPosition(self.kartObject:GetPosition())
    end

end


function SyncedKartManClient:ProcessBoostEffects(frameTime)

	self.boostParticles[1]:Process(frameTime)
	self.boostParticles[2]:Process(frameTime)

	if self.boostEnabled then
		if IsValid(self:GetObject()) then
			self.boostParticles[1]:SetPosition(self:GetObject():GetWheelWorldPosition(WheelID.LEFT_BACK_WHEEL))
			self.boostParticles[2]:SetPosition(self:GetObject():GetWheelWorldPosition(WheelID.RIGHT_BACK_WHEEL))

			local up = self:GetObject():GetUpNormal()
			--Set the first wheel's orientation
			local wheelOrien = self:GetObject():GetWheelWorldOrientation(WheelID.LEFT_BACK_WHEEL)
			local side = wheelOrien:xAxis()
			side:Normalise()
			local forward = up:CrossProduct(side)
			forward:Normalise()
			self.boostParticles[1]:SetOrientation(WQuaternion(side, up, forward))
			--Set the second wheel's orientation
			wheelOrien = self:GetObject():GetWheelWorldOrientation(WheelID.RIGHT_BACK_WHEEL)
			side = wheelOrien:xAxis()
			side:Negate()
			side:Normalise()
			forward = up:CrossProduct(side)
			forward:Normalise()
			self.boostParticles[2]:SetOrientation(WQuaternion(side, up, forward))
		end
		self.boostParticles[1]:SetEnableEmission(true)
		self.boostParticles[2]:SetEnableEmission(true)
	else
		self.boostParticles[1]:SetEnableEmission(false)
		self.boostParticles[2]:SetEnableEmission(false)
	end

end


function SyncedKartManClient:GetObject()

	return self.kartObject

end


function SyncedKartManClient:SetVisible(setVis)

	self.kartObject:SetVisible(setVis)

	self.graphicalDraft:SetVisible(setVis)

	self.boostParticles[1]:SetVisible(setVis)
	self.boostParticles[2]:SetVisible(setVis)

end


function SyncedKartManClient:GetVisible()

	return self.kartObject:GetVisible()

end


function SyncedKartManClient:GetPosition()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetPosition()
	end

	return WVector3()

end


function SyncedKartManClient:GetOrientation()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetOrientation()
	end

	return WQuaternion()

end


function SyncedKartManClient:GetSpeedPercent()

	if IsValid(self.kartObject) then
		return self.kartObject:GetSpeedPercent()
	end
	return 0

end


function SyncedKartManClient:GetLinearVelocity()

	if IsValid(self.kartObject) then
		return self.kartObject:GetLinearVelocity()
	end
	return WVector3()

end


function SyncedKartManClient:GetUpNormal()

	if IsValid(self.kartObject) then
		return self.kartObject:GetUpNormal()
	end
	return WVector3()

end


--Respawning the kart will instantly snap it to the spawn position
function SyncedKartManClient:NotifyRespawned(respawnPos, respawnOrien)

	self.kartObject:Respawn(respawnPos, respawnOrien)

end


function SyncedKartManClient:DoesOwn(ownObjectID)

	if IsValid(self.kartObject) and (ownObjectID == self.kartObject:GetID()) then
		return true
	end

	return false

end

--SYNCEDKARTMANCLIENT CLASS END