UseModule("ISyncedWeapon", "Scripts/SyncedObjects/Weapons/")

--SyncedSpring CLASS START

--SyncedSpring
class 'SyncedSpring' (ISyncedWeapon)

function SyncedSpring:__init() super()

    self.achievements = AchievementManager()

	self.springClock = WTimer()

    self.springForce = 5000

	self.graphicalSpring = nil

	self.attachedToParentSceneNode = false

	--This ensures the player can't use the use up button to deploy the puncher
	--and then the down button to punch, it will lock to either key when first deployed
	self.usingUp = true

	--Not used yet
	self.SS_NOT_USED = 0
	--Used, sprung
	self.SS_SPRUNG = 1
	self.state = self.SS_NOT_USED
	self.stateParam = Parameter()
	--The state change functions init and uninit state
	self.stateFuncs = { }
	self.stateFuncs[self.SS_NOT_USED] = { SyncedSpring.StateChangeNotUsed, SyncedSpring.ProcessStateNotUsed }
	self.stateFuncs[self.SS_SPRUNG] = { SyncedSpring.StateChangeSprung, SyncedSpring.ProcessStateSprung }

end


function SyncedSpring:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedSpring", "ISyncedWeapon", "")

end


function SyncedSpring:InitWeapon()

	if IsClient() then
		self.stateSlot = self:CreateSlot("SetSpringState", "SetSpringState")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("SpringState_" .. tostring(self:GetServerID()), self.stateSlot)
	else
		GetServerSystem():GetSendStateTable("Map"):NewState("SpringState_" .. tostring(self:GetID()))
		self:SetSpringState(self.state)
	end

end


function SyncedSpring:UnInitWeapon()

    print("UnInitWeapon()")
	--UnInitState
	if IsServer() then
		GetServerSystem():GetSendStateTable("Map"):RemoveState("SpringState_" .. tostring(self:GetID()))
		self:UnInitPhysical()
	end

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end

end


function SyncedSpring:InitGraphical()

	self.graphicalSpring = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "spring.mesh"))
	self.graphicalSpring:SetName("spring")
	self.graphicalSpring:Init(params)
	self.graphicalSpring:SetCastShadows(false)
	self.graphicalSpring:SetReceiveShadows(false)
	if IsValid(self:GetOwner()) and IsValid(self:GetOwner():GetController()) then
        --Attach the puncher to the controller
        self.graphicalSpring:AttachToParentSceneNode(self:GetOwner():GetController():GetSceneNode())
        self.attachedToParentSceneNode = true
    end

	--Grab animations
	self.springAnim = self.graphicalSpring:GetAnimation("launch", true)
	self.springAnim:SetLooping(false)

end


function SyncedSpring:UnInitGraphical()

	if IsValid(self.graphicalSpring) then
		self.graphicalSpring:UnInit()
		self.graphicalSpring = nil
	end
	self.springAnim = nil

end


function SyncedSpring:InitPhysical()

end


function SyncedSpring:UnInitPhysical()

end


function SyncedSpring:SetSpringState(newState)

	--First, UnInit old state
	self.stateFuncs[self.state][1](self, false)

	--Apply the new state
	if IsClient() then
		self.state = newState:GetParameter(0, true):GetIntData()
	else
		self.state = newState
		self.stateParam:SetIntData(self.state)
		GetServerSystem():GetSendStateTable("Map"):SetState("SpringState_" .. tostring(self:GetID()), self.stateParam)
	end

	--Finally, Init the new state
	self.stateFuncs[self.state][1](self, true)

end


function SyncedSpring:DoesWeaponOwn(ownObjectID)

	if IsClient() then
		if self.graphicalSpring:GetID() == ownObjectID then
			return true
		end
	end
	return false

end


function SyncedSpring:NotifyPositionChange(setPos)

end


function SyncedSpring:NotifyOrientationChange(setOrien)

end


function SyncedSpring:GetPosition()

	if IsClient() then
		return self.graphicalSpring:GetPosition()
	end
	return WVector3()

end


function SyncedSpring:GetOrientation()

	if IsClient() then
		return self.graphicalSpring:GetOrientation()
	end
	return WQuaternion()

end


function SyncedSpring:GetWeaponActive()

	return false

end


function SyncedSpring:SetWeaponStateData(stateBuiltTime, setState)

end


function SyncedSpring:GetWeaponStateData(returnState)

end

function SyncedSpring:RecordUse()
    
    self.achievements:UpdateStat(self.achievements.STAT_SPRING_COUNT, 1)
    
end

function SyncedSpring:UseItemUp(pressed, extraData)

	if IsServer() then
        if self.state == self.SS_NOT_USED then
            if pressed then
				self.usingUp = true
                self:Attach()
                local p = self:GetOwner():GetController()
                if not p:GetAllWheelsNotInContact() then
                    -- Spring forward
                    local kforward = p:GetOrientation():zAxis()
                    local kup = p:GetOrientation():yAxis()
                    p:ApplyWorldImpulse((kup+kforward)*self.springForce, WVector3())
                end
            end
        end
    end
    self:SetWeaponUsed()
end


function SyncedSpring:UseItemDown(pressed, extraData)

    if IsServer() then
        if self.state == self.SS_NOT_USED then
            if pressed then
				self.usingUp = false
                self:Attach()
                local p = self:GetOwner():GetController()
                if not p:GetAllWheelsNotInContact() then
                    -- Spring up
                    local kup = p:GetOrientation():yAxis()
                    p:ApplyWorldImpulse(kup*self.springForce, WVector3())
                end
            end
        end
    end
    self:SetWeaponUsed()
end


function SyncedSpring:SetWeaponParameter(param)

end


function SyncedSpring:EnumerateWeaponParameters(params)

end


function SyncedSpring:Attach()

    if self.state == self.SS_NOT_USED then
		self:SetSpringState(self.SS_SPRUNG)
	end

end


function SyncedSpring:ProcessSyncedObject(frameTime)

	--Process the current state
	self.stateFuncs[self.state][2](self, frameTime)

	if IsValid(self.graphicalSpring) then
		self.graphicalSpring:Process(frameTime)
	end
	if IsValid(self.springAnim) then
		self.springAnim:Process(frameTime)
	end

end


--State process functions below
function SyncedSpring:ProcessStateNotUsed(frameTime)

end


function SyncedSpring:ProcessStateSprung(frameTime)

end


function SyncedSpring:ProcessStateSprung(frameTime)

    if IsServer() and self.springClock:GetTimeSeconds() > 0.5 then
        local p = self:GetOwner():GetController()
        if p:GetAllWheelsInContact() then
            self:SetWeaponDead()
        end
    end

end


--State change functions below
function SyncedSpring:StateChangeNotUsed(initing)

end


function SyncedSpring:StateChangeSprung(initing)

    if initing then
    
        self.springClock:Reset()
        self:SetWeaponUsed()
        if IsClient() then
            self:InitGraphical()
            if IsValid(self.springAnim) then
                self.springAnim:SetSpeed(0.5)
                self.springAnim:Play()
            end
            local ownerPos = WVector3()
			ownerPos = WVector3()
            if IsValid(self:GetOwner()) then
                ownerPos = self:GetOwner():GetPosition()
                if self:GetOwner() == GetPlayerManager():GetLocalPlayer() then
                    self:RecordUse()
                end
            end
            --Play spring sound
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/spring.wav", ownerPos, 5, 1, true, SoundSystem.MEDIUM)
            --Show the pow effect
            GetParticleSystem():AddEffect("poof", ownerPos)
        else
            --self:DoPhysicsPunch()
	    end
    end

end


function SyncedSpring:PlayerInvalid(invalidPlayer)

	--Only kill the weapon if it's owner is invalid
	if not IsValid(self:GetOwner()) or self:GetOwner():GetUniqueID() == invalidPlayer:GetUniqueID() then
		self:SetWeaponDead()
	end

end


--SyncedSpring CLASS END