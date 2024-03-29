UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")
UseModule("AchievementManager", "Scripts/")

--SYNCEDPUNCHER CLASS START

--SyncedPuncher
class 'SyncedPuncher' (ISyncedWeapon)

function SyncedPuncher:__init() super()

    self.achievements = AchievementManager()

    self.punchingClock = WTimer()
    self.punchingTimer = 0.75

    self.punchForce = 11000

	self.graphicalPuncher = nil

	self.puncherSensor = nil

	self.attachedToParentSceneNode = false

	--This ensures the player can't use the use up button to deploy the puncher
	--and then the down button to punch, it will lock to either key when first deployed
	self.usingUp = true

	--Not used yet
	self.SPS_NOT_USED = 0
	--Used, attached
	self.SPS_ATTACHED = 1
	self.SPS_ATTACHED_REAR = -1
	--Used, punching
	self.SPS_PUNCHING = 2
	self.state = self.SPS_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.SPS_NOT_USED] = { SyncedPuncher.StateChangeNotUsed, SyncedPuncher.ProcessStateNotUsed }
	self.stateFuncs[self.SPS_ATTACHED] = { SyncedPuncher.StateChangeAttached, SyncedPuncher.ProcessStateAttached }
	self.stateFuncs[self.SPS_ATTACHED_REAR] = { SyncedPuncher.StateChangeAttached, SyncedPuncher.ProcessStateAttached }
	self.stateFuncs[self.SPS_PUNCHING] = { SyncedPuncher.StateChangePunching, SyncedPuncher.ProcessStatePunching }

end


function SyncedPuncher:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedPuncher", "ISyncedWeapon", "")

end


function SyncedPuncher:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetPuncherState", "SetPuncherState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("PuncherState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("PuncherState_" .. tostring(self:GetID()))
		self:SetPuncherState(self.state)
	end

end


function SyncedPuncher:UnInitWeapon()

    print("UnInitWeapon()")
	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("PuncherState_" .. tostring(self:GetID()))
		self:UnInitPhysical()
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end

end


function SyncedPuncher:InitGraphical()

	self.graphicalPuncher = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "pow.mesh"))
	self.graphicalPuncher:SetName("puncher")
	self.graphicalPuncher:Init(params)
	self.graphicalPuncher:SetCastShadows(true)
	self.graphicalPuncher:SetReceiveShadows(false)
	if IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetController()) then
        --Attach the puncher to the controller
        if self:GetOwner():GetControllerValid() and IsValid(self:GetOwner():GetController():GetSceneNode()) then
            self.graphicalPuncher:AttachToParentSceneNode(self:GetOwner():GetController():GetSceneNode())
        end
        self.attachedToParentSceneNode = true
        if self.state == self.SPS_ATTACHED_REAR then
            self.graphicalPuncher:SetOrientation(WQuaternion(0,180,0))
        end
    end

	--Grab animations
	self.puncherCharge = self.graphicalPuncher:GetAnimation("charge", true)
	self.puncherCharge:SetLooping(false)
	self.puncherHit = self.graphicalPuncher:GetAnimation("hit", true)
	self.puncherHit:SetLooping(false)

	--Pow! particle effect
	self.powEffect = OGREParticleEffect()
	params:Clear()
	params:AddParameter(Parameter("ResourceName", "pow"))
	params:AddParameter(Parameter("Loop", false))
	params:AddParameter(Parameter("StartOnLoad", false))
	self.powEffect:SetName("pow" .. GenerateName())
	self.powEffect:Init(params)
	self.particleClock = WTimer()

end


function SyncedPuncher:UnInitGraphical()

	if IsValid(self.graphicalPuncher) then
		self.graphicalPuncher:UnInit()
		self.graphicalPuncher = nil
	end
	self.puncherCharge = nil
	self.puncherHit = nil
	if IsValid(powEffect) then
	    powEffect:UnInit()
	    powEffect = nil
	end

end


function SyncedPuncher:InitPhysical()

    self.puncherSensor = BulletSensor()
    self.puncherSensor:SetName(self.name .. "Sensor")
    local params = Parameters()
    params:AddParameter(Parameter("Shape", "Cube"))
    params:AddParameter(Parameter("Dimensions", WVector3(4, 4, 6)))
    self.puncherSensor:Init(params)

end


function SyncedPuncher:UnInitPhysical()

    if IsValid(self.puncherSensor) then
        self.puncherSensor:UnInit()
        self.puncherSensor = nil
    end

end


function SyncedPuncher:SetPuncherState(newState)

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("PuncherState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true)

end


function SyncedPuncher:DoesWeaponOwn(ownObjectID)

	if IsClient() then
		if self.graphicalPuncher:GetID() == ownObjectID then
			return true
		end
	end
	return false

end


function SyncedPuncher:NotifyPositionChange(setPos)

end


function SyncedPuncher:NotifyOrientationChange(setOrien)

end


function SyncedPuncher:GetPosition()

	if IsClient() then
		return self.graphicalPuncher:GetPosition()
	end
	return WVector3()

end


function SyncedPuncher:GetOrientation()

	if IsClient() then
		return self.graphicalPuncher:GetOrientation()
	end
	return WQuaternion()

end


function SyncedPuncher:GetWeaponActive()

	return false

end


function SyncedPuncher:SetWeaponStateData(stateBuiltTime, setState)

end


function SyncedPuncher:GetWeaponStateData(returnState)

end


function SyncedPuncher:UseItemUp(pressed, extraData)

	if IsServer() then
        if self.state == self.SPS_NOT_USED then
            if pressed then
				self.usingUp = true
                self:Attach()
            end
        elseif self.state == self.SPS_ATTACHED and self.usingUp then
            if not pressed then
                self:Punch()
            end
        end
    end

end


function SyncedPuncher:UseItemDown(pressed, extraData)

    if IsServer() then
        if self.state == self.SPS_NOT_USED then
            if pressed then
				self.usingUp = false
                self:Attach()
            end
        elseif self.state == self.SPS_ATTACHED_REAR and not self.usingUp then
            if not pressed then
                self:Punch()
            end
        end
    end

end


function SyncedPuncher:SetWeaponParameter(param)

end


function SyncedPuncher:EnumerateWeaponParameters(params)

end


function SyncedPuncher:Attach()

    if self.state == self.SPS_NOT_USED then
        if self.usingUp then
            self:SetPuncherState(self.SPS_ATTACHED)
        else
		    self:SetPuncherState(self.SPS_ATTACHED_REAR)
	    end
	end

end


--The Puncher should detach from the kart it is following
function SyncedPuncher:Punch()

    if math.abs(self.state) == self.SPS_ATTACHED then
	    self:SetPuncherState(self.SPS_PUNCHING)
    end

end


function SyncedPuncher:ProcessSyncedObject(frameTime)

	--Process the current state
	self.stateFuncs[self.state][2](self, frameTime)

	if IsValid(self.graphicalPuncher) then
		self.graphicalPuncher:Process(frameTime)
	end
	if IsValid(self.puncherCharge) then
		self.puncherCharge:Process(frameTime)
	end
	if IsValid(self.puncherHit) then
		self.puncherHit:Process(frameTime)
	end
	if IsValid(self.powEffect) and IsValid(self:GetOwner()) then
		--Set the position of the effect
		local emitPos = self:GetOwner():GetPosition() + (self:GetOwner():GetOrientation():zAxis() * 2) + WVector3(0, 0.5, 0)
		if self.state == self.SPS_ATTACHED_REAR then
            emitPos = self:GetOwner():GetPosition() + (self:GetOwner():GetOrientation():zAxis() * 6) + WVector3(0, 0.5, 0)
        end 
		self.powEffect:SetPosition(emitPos)
		self.powEffect:Process(frameTime)
	end
	if IsValid(self.puncherSensor) then
		self.puncherSensor:Process(frameTime)
	end

end


--State process functions below
function SyncedPuncher:ProcessStateNotUsed(frameTime)

end


function SyncedPuncher:ProcessStateAttached(frameTime)

    if IsValid(self.puncherSensor) then
		local ownerForward = self:GetOwner():GetOrientation():zAxis()

		if self.state == self.SPS_ATTACHED_REAR then
            ownerForward = ownerForward * -1
        end

		local ownerUp = self:GetOwner():GetOrientation():yAxis()
        --Always sync the sensor to the physical puncher's position
        local sensorPos = WVector3(self:GetOwner():GetPosition())
        sensorPos = sensorPos + (ownerForward * ((self.puncherSensor:GetDimensions().z / 2) + (self:GetOwner():GetBoundingBox():GetDepth() / 2)))
        sensorPos = sensorPos + (ownerUp * (self.puncherSensor:GetDimensions().y / 2))
		self.puncherSensor:SetPosition(sensorPos)
		self.puncherSensor:SetOrientation(self:GetOwner():GetOrientation())
    end

    if IsClient() then
        if (not self.attachedToParentSceneNode) then
            if IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetController()) then
                --Attach the puncher to the controller
                self.graphicalPuncher:AttachToParentSceneNode(self:GetOwner():GetController():GetSceneNode())
                self.attachedToParentSceneNode = true
                if self.state == self.SPS_ATTACHED_REAR then
                    self.graphicalPuncher:SetOrientation(WQuaternion(0,180,0))
                end
            end
	    end
	end

end


function SyncedPuncher:ProcessStatePunching(frameTime)

    if self.punchingClock:GetTimeSeconds() > self.punchingTimer then
        self:SetWeaponDead()
    end

end


--State change functions below
function SyncedPuncher:StateChangeNotUsed(initing)

end


function SyncedPuncher:StateChangeAttached(initing)

	if initing then
	    self:SetWeaponUsed()
		if IsClient() then
			self:InitGraphical()
			--BRIAN TODO: Test code only
			--self:InitPhysical()
		else
		    self:InitPhysical()
		end
	end

end


function SyncedPuncher:StateChangePunching(initing)

    if initing then
        self.punchingClock:Reset()
        if IsClient() then
            if IsValid(self.puncherHit) then
                self.puncherHit:SetSpeed(0.5)
                self.puncherHit:Play()
            end
            local ownerPos = WVector3()
			ownerPos = WVector3()
            if IsValid(self:GetOwner()) then
                ownerPos = self:GetOwner():GetPosition()
            end
            --Play punch sound
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Glove_Hit.wav", ownerPos, 5, 1, true, SoundSystem.MEDIUM)
            --Show the pow effect
            if IsValid(self.powEffect) then
                self.powEffect:Restart()
                local emitPos = self:GetOwner():GetPosition() + (self:GetOwner():GetOrientation():zAxis() * 2) + WVector3(0, 0.5, 0)
		        if self.state == self.SPS_ATTACHED_REAR then
                    emitPos = self:GetOwner():GetPosition() + (self:GetOwner():GetOrientation():zAxis() * 6) + WVector3(0, 0.5, 0)
                end 
		        self.powEffect:SetPosition(emitPos)
		        
                -- Check for K.O. achievement
			    local i = 1
			    local numAffected = 0
	            local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	            while i < (numPlayers + 1) do
		            local player = GetPlayerManager():GetPlayer(i)
		            if (emitPos - player:GetPosition()):Length() < 2 then
                       numAffected = numAffected + 1
		            end
		            i = i + 1
	            end
	            print("Players hit by glove: "..numAffected)
	            local owner = self:GetOwner()
	            if numAffected > 1 and IsValid(owner) and owner == GetPlayerManager():GetLocalPlayer() then
	                self.achievements:Unlock(self.achievements.AVMT_KO)
	            end
                
            end
        else
            self:DoPhysicsPunch()
	    end
    end

end


function SyncedPuncher:DoPhysicsPunch()

    local objectList = self:GetObjectsWithinSensor()
    local numObjects = #objectList
	local i = 1
	--Values needed for punch
	--Start the punch from the center of the player doing the punch, otherwise
	--the punch start point might end up on the other side of the object being
	--punched and cause it to be punched into the player doing the punch
	local punchEmitPoint = WVector3(self:GetOwner():GetPosition())
	while i <= numObjects do
		local currentObject = objectList[i]
		--Repell the object away from the puncher
		local punchNormal = currentObject:GetPosition() - punchEmitPoint
		punchNormal:Normalise()
		local force = punchNormal * self.punchForce
		--Add some upward force
		force = force + WVector3(0, self.punchForce / 2, 0)
		currentObject:ApplyWorldImpulse(force, WVector3())
		--Random torque
		local randomNormalVec = WVector3(0, 1, 0):Random(0.5, WVector3(0, 1, 0))
		randomNormalVec = randomNormalVec:Random(0.5, WVector3(1, 0, 0))
		randomNormalVec = randomNormalVec:Random(0.5, WVector3(0, 0, 1))
		randomNormalVec:Normalise()
		currentObject:ApplyWorldTorqueImpulse(randomNormalVec * 1500)

		i = i + 1
	end

end


function SyncedPuncher:GetObjectsWithinSensor()

	local objectList = { }
	local iter = self.puncherSensor:GetIterator()
	while not iter:IsEnd() do
		local currentObject = iter:Get()
		--Make sure not to punch the owner of the puncher
		if not self:GetOwner():DoesOwn(currentObject:GetID()) then
			table.insert(objectList, currentObject)
		end
		iter:Next()
	end

	return objectList

end


function SyncedPuncher:PlayerInvalid(invalidPlayer)

	--Only kill the weapon if it's owner is invalid
	if not IsValid(self:GetOwner()) or self:GetOwner():GetUniqueID() == invalidPlayer:GetUniqueID() then
		self:SetWeaponDead()
	end

end


--SYNCEDPUNCHER CLASS END