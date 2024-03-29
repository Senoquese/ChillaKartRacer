
UseModule("IKart", "Scripts/")

--KARTCLIENT CLASS START

class 'KartClient' (IKart)

function KartClient:__init(setKartObject, setIsLocalPlayer) super()

	self.kartObject = setKartObject
	self.isLocalPlayer = setIsLocalPlayer

	--Grab some processing time
	self.processSlot = self:CreateSlot("Process", "Process")
	--We need to process after the kart object has processed
	self.kartObject:GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--The engine sound state variables
	self.engineSound = nil
	self.soundsMuted = false
	self.engineOffVol = 0.3
	self.engineOnVol = 0.7
	--How much the engine volume will change per second
	self.engineVolStep = 2
	self.currentEngineVol = self.engineOffVol
	self.engineVolClock = WClock()

	--The handbrake skid sound state variables
	--self.handbrakeIntroSound = nil
	self.handbrakeSound = nil

	--The slide model animation
	self.slideModel = nil
	self.slideCenterLow = nil
	self.slideCenterHigh = nil
	self.slideRightLow = nil
	self.slideRightHigh = nil
	self.slideLeftLow = nil
	self.slideLeftHigh = nil

	--This is true when the server kart is currently being boosted
	self.boostEnabled = false

	self:InitBoostParticles()
	self:InitSounds()
	self:InitSlide()

end


function KartClient:UnInitImp()

	IKart.UnInitImp(self)

	self:UnInitBoostParticles()
	self:UnInitSounds()
	self:UnInitSlide()

end


function KartClient:InitBoostParticles()

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


function KartClient:UnInitBoostParticles()

	if IsValid(self.boostParticles[1]) then
		self.boostParticles[1]:UnInit()
		self.boostParticles[1] = nil
	end

	if IsValid(self.boostParticles[2]) then
		self.boostParticles[2]:UnInit()
		self.boostParticles[2] = nil
	end

end


function KartClient:InitSounds()

	--Engine Sound
	local soundParams = Parameters()
	self.engineSound = SoundSource()
	self.engineSound:SetName("engineSound" .. self.kartObject:GetName())
	self.engineSound:Init(soundParams)
	self.engineSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Engine_1.wav"))
	self.engineSound:SetLooping(true)
	--Start off with no volume, the volume will be set during processing
	self.engineSound:SetVolume(0)
	self.engineSound:Play()

	--Handbrake Skid Sound
	self.handbrakeSound = SoundSource()
	self.handbrakeSound:SetName("handbrakeSound" .. self.kartObject:GetName())
	self.handbrakeSound:Init(soundParams)
	self.handbrakeSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Screeching_long.wav"))
	self.handbrakeSound:SetLooping(true)

	--Boost Start Sound
	self.boostStartSound = SoundSource()
	self.boostStartSound:SetName("boostStartSound" .. self.kartObject:GetName())
	self.boostStartSound:Init(soundParams)
	self.boostStartSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Boost_Start.wav"))
	self.boostStartSound:SetLooping(false)
	self.boostStartSound:SetVolume(1)

	--Boost Loop Sound
	self.boostLoopSound = SoundSource()
	self.boostLoopSound:SetName("boostLoopSound" .. self.kartObject:GetName())
	self.boostLoopSound:Init(soundParams)
	self.boostLoopSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/Boost_Cont.wav"))
	self.boostLoopSound:SetLooping(true)
	self.boostLoopSound:SetVolume(1)

	--Attach the sounds to the kart
	self.kartObject:GetSignal("SetTransform", true):Connect(self.engineSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.handbrakeSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.boostStartSound:GetSlot("SetTransform", true))
	self.kartObject:GetSignal("SetTransform", true):Connect(self.boostLoopSound:GetSlot("SetTransform", true))

end


function KartClient:UnInitSounds()

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

end


function KartClient:SetMuteSounds(setMute)

	self.soundsMuted = setMute

	self.engineSound:SetMute(self.soundsMuted)
	self.handbrakeSound:SetMute(self.soundsMuted)
	self.boostStartSound:SetMute(self.soundsMuted)
	self.boostLoopSound:SetMute(self.soundsMuted)

end


function KartClient:GetMuteSounds()

	return self.soundsMuted

end


function KartClient:InitSlide()

	--[[
	self.slideModel = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "slide.mesh"))
	self.slideModel:SetName("slide")
	self.slideModel:Init(params)
	self.slideModel:SetCastShadows(false)
	self.slideModel:SetReceiveShadows(false)
	--Not using right now
	self.slideModel:SetVisible(false)

	--Grab animations
	self.slideCenterLow = self.slideModel:GetAnimation("center_low", true)
	self.slideCenterHigh = self.slideModel:GetAnimation("center_high", true)
	self.slideRightLow = self.slideModel:GetAnimation("right_low", true)
	self.slideLeftLow = self.slideModel:GetAnimation("left_low", true)
	self.slideRightHigh = self.slideModel:GetAnimation("right_high", true)
	self.slideLeftHigh = self.slideModel:GetAnimation("left_high", true)

	self.slideCenterLow:Play()
	self.slideCenterHigh:Play()
	self.slideRightLow:Play()
	self.slideLeftLow:Play()
	self.slideRightHigh:Play()
	self.slideLeftHigh:Play()

	--Attach the slide to the kart
	self.slideModel:AttachToParentSceneNode(self.kartObject:GetSceneNode())

	--The slide material we need for transparency, etc
	self.slideMat = self.slideModel:GetMaterial()
	self.transparencyStep = 3
	self.slideTransClock = WClock()
	--]]

end


function KartClient:UnInitSlide()

	--[[
	if IsValid(self.slideModel) then
		self.slideModel:UnInit()
		self.slideModel = nil
	end
	--]]

end


function KartClient:GetName()

	return self.kartObject:GetName()

end


function KartClient:ControlAccel(accelOn)

	self.accelOn = accelOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlAccel(self.accelOn)
	end

end


function KartClient:ControlBrake(brakeOn)

	self.brakeOn = brakeOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlBrake(self.brakeOn)
	end

end


function KartClient:ControlHandbrake(handbrakeOn)

	self.handbrakeOn = handbrakeOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlHandbrake(self.handbrakeOn)
	end

end


function KartClient:GetHandbrakeEnabled()

	return self.handbrakeOn

end


function KartClient:ControlReverse(reverseOn)

	self.reverseOn = reverseOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlReverse(self.reverseOn)
	end

end


function KartClient:ControlRight(rightOn)

	self.rightOn = rightOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlRight(self.rightOn)
	end

end


function KartClient:ControlLeft(leftOn)

	self.leftOn = leftOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlLeft(self.leftOn)
	end

end


function KartClient:ControlReset()

	if IsValid(self.kartObject) then
		self.kartObject:ControlReset()
	end

end


function KartClient:ControlLookBack(lookBackOn)

	self.lookBackOn = lookBackOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlLookBack(self.lookBackOn)
	end

end


--This is called when the user wants to boost
function KartClient:ControlBoost(boostOn)

	self.boostOn = boostOn
	if IsValid(self.kartObject) then
		self.kartObject:ControlBoost(self.boostOn)
	end

end


--The boost is enabled when the server kart is actually being boosted
function KartClient:SetBoostEnabled(setBoostEnabled)

	self.boostEnabled = setBoostEnabled
	if self.boostEnabled then
		self.boostParticles[1]:Start()
		self.boostParticles[2]:Start()
		self.boostLoopSound:Play()
		self.boostStartSound:Play()
	else
		self.boostParticles[1]:Stop()
		self.boostParticles[2]:Stop()
		self.boostStartSound:Stop()
		self.boostLoopSound:Stop()
	end

end


function KartClient:GetBoostEnabled()

	return self.boostEnabled

end


function KartClient:Process(processParams)

	if not IsValid(self.kartObject) then
		return
	end

	local timeDiff = self.engineVolClock:GetTimeDifference()
	local engineTimeStep = self.engineVolStep * timeDiff

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
	if self.boostEnabled then
		self.engineSound:SetVolume(self.currentEngineVol * 3)
	else
		self.engineSound:SetVolume(self.currentEngineVol)
	end

	--Pitch based on current speed
	--Pitch scales between 0.5 and 2.0
	self.engineSound:SetPitch(0.5 + (1.35 * math.abs(self.kartObject:GetSpeedPercent())))

	--Change the sound's velocity based on the kart's velocity
	self.engineSound:SetVelocity(self.kartObject:GetWorldVelocity())
	self.handbrakeSound:SetVelocity(self.kartObject:GetWorldVelocity())
	self.boostStartSound:SetVelocity(self.kartObject:GetWorldVelocity())
	self.boostLoopSound:SetVelocity(self.kartObject:GetWorldVelocity())

	self:ProcessSounds()
	self:ProcessHandbrakeAnimations()
	self:ProcessBoostEffects()

end


function KartClient:ProcessHandbrakeAnimations()

	--[[
	local timeDiff = self.slideTransClock:GetTimeDifference()

	--Slide mesh animation
	if self.handbrakeOn then
		--Not using right now
		--self.slideModel:SetVisible(true)
		if self.slideMat:GetTransparency() < 1 then
			self.slideMat:SetTransparency(self.slideMat:GetTransparency() + (self.transparencyStep * timeDiff))
			if self.slideMat:GetTransparency() > 1 then
				self.slideMat:SetTransparency(1)
			end
		end

		if self:GetObject():GetHandbrakeTurnState() == VehicleTurnState.TURN_RIGHT then
			self.slideCenterLow:SetWeight(0)
			self.slideCenterHigh:SetWeight(0)
			self.slideRightLow:SetWeight(0)
			self.slideLeftLow:SetWeight(0)
			self.slideRightHigh:SetWeight(1)
			self.slideLeftHigh:SetWeight(0)
		elseif self:GetObject():GetHandbrakeTurnState() == VehicleTurnState.TURN_LEFT then
			self.slideCenterLow:SetWeight(0)
			self.slideCenterHigh:SetWeight(0)
			self.slideRightLow:SetWeight(0)
			self.slideLeftLow:SetWeight(0)
			self.slideRightHigh:SetWeight(0)
			self.slideLeftHigh:SetWeight(1)
		elseif self:GetObject():GetHandbrakeTurnState() == VehicleTurnState.TURN_NONE then
			self.slideCenterLow:SetWeight(1)
			self.slideCenterHigh:SetWeight(0)
			self.slideRightLow:SetWeight(0)
			self.slideLeftLow:SetWeight(0)
			self.slideRightHigh:SetWeight(0)
			self.slideLeftHigh:SetWeight(0)
		end

		--Process all the animations
		self.slideCenterLow:Process()
		self.slideCenterHigh:Process()
		self.slideRightLow:Process()
		self.slideLeftLow:Process()
		self.slideRightHigh:Process()
		self.slideLeftHigh:Process()
	else
		--self.slideModel:SetVisible(false)
		if self.slideMat:GetTransparency() > 0 then
			self.slideMat:SetTransparency(self.slideMat:GetTransparency() - (self.transparencyStep * timeDiff))
			if self.slideMat:GetTransparency() < 0 then
				self.slideMat:SetTransparency(0)
			end
		end
	end
	--]]

end


function KartClient:ProcessSounds()

	--Handbrake sounds
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

	self.engineSound:Process()
	self.handbrakeSound:Process()
	self.boostStartSound:Process()
	self.boostLoopSound:Process()

end


function KartClient:ProcessBoostEffects()

	self.boostParticles[1]:Process()
	self.boostParticles[2]:Process()

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


function KartClient:GetObject()

	return self.kartObject

end


function KartClient:SetVisible(setVis)

	self.kartObject:SetVisible(setVis)

end


function KartClient:GetVisible()

	return self.kartObject:GetVisible()

end


function KartClient:GetPosition()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetPosition()
	end

	return WVector3()

end


function KartClient:GetOrientation()

	if IsValid(self:GetObject()) then
		return self:GetObject():GetOrientation()
	end

	return WQuaternion()

end


function KartClient:GetSpeedPercent()

	if IsValid(self.kartObject) then
		return self.kartObject:GetSpeedPercent()
	end
	return 0

end


function KartClient:GetWorldVelocity()

	if IsValid(self.kartObject) then
		return self.kartObject:GetWorldVelocity()
	end
	return WVector3()

end


function KartClient:GetUpNormal()

	if IsValid(self.kartObject) then
		return self.kartObject:GetUpNormal()
	end
	return WVector3()

end


--Respawning the kart will instantly snap it to the spawn position
function KartClient:Respawn(respawnPos)

	self.kartObject:Respawn(respawnPos)

end


function KartClient:DoesOwn(ownObject)

	local ownObjectName = ""
	if type(ownObject) == "string" then
		ownObjectName = ownObject
	else
		ownObjectName = ownObject:GetName()
	end

	if IsValid(self.kartObject) and (ownObjectName == self.kartObject:GetName()) then
		return true
	end

	return false

end


function KartClient:RemoveOwnedObject(object)

	if IsValid(object) and IsValid(self.kartObject) then
		local ownObjectName = ""
		if type(object) == "string" then
			ownObjectName = object
		else
			ownObjectName = object:GetName()
		end

		if ownObjectName == self.kartObject:GetName() then
			self.kartObject = nil
		end
	end

end

--KARTCLIENT CLASS END