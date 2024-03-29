UseModule("Player", "Scripts/")

--PLAYERSERVER CLASS START

class 'PlayerServer' (Player)

function PlayerServer:__init(setName, setUniqueID, setPeer) super(setName, setUniqueID, setPeer)

	self.respawning = false

	self.stateParam = Parameter()
	self:InitState()

	self.weaponInQueue = false
	self.weaponInAltQueue = false
	self.queuedWeaponIsActive = false
	--This is the weapon type name that is in queue to be used by the player
	self.queuedWeaponTypeName = ""
	self.queuedAltWeaponTypeName = ""
	--This is the current weapon that can be used by the player
	self.activeWeapon = nil

	--
	self.playerResettingSlot = self:CreateSlot("Resetting", "Resetting")
	self.playerResettingSignal = self:CreateSignal("Resetting")

	--The NetworkPeer will notify us of any input events
	self.inputEventSignal = self:CreateSignal("InputEvent")
	self.inputEventSlot = self:CreateSlot("InputEvent", "InputEvent")
	self:GetNetworkPeer():GetSignal("InputEvent", true):Connect(self.inputEventSlot)

end


function PlayerServer:InitPlayer()

end


function PlayerServer:UnInitPlayer()

	self:_RemoveWeapons()

	self:UnInitState()

end


function PlayerServer:InitState()

	GetServerSystem():GetSendStateTable("General"):NewState(tostring(self:GetUniqueID()) .. "ControllerEnabled")
	self.stateParam:SetBoolData(self:GetControllerEnabled())
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ControllerEnabled", self.stateParam)

	GetServerSystem():GetSendStateTable("General"):NewState(tostring(self:GetUniqueID()) .. "ActiveWeapon")
	self.stateParam:SetIntData(0)
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ActiveWeapon", self.stateParam)

	GetServerSystem():GetSendStateTable("General"):NewState(tostring(self:GetUniqueID()) .. "QueuedWeapon")
	self.stateParam:SetStringData("")
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedWeapon", self.stateParam)

	GetServerSystem():GetSendStateTable("General"):NewState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon")
	self.stateParam:SetStringData("")
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon", self.stateParam)
end


function PlayerServer:UnInitState()

	GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(self:GetUniqueID()) .. "ControllerEnabled")
	GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(self:GetUniqueID()) .. "ActiveWeapon")
	GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(self:GetUniqueID()) .. "QueuedWeapon")
	GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon")

end


function PlayerServer:Process()

end


function PlayerServer:Reset()

    print("PlayerServer:Reset()")

	--Player loses weapons and boost on reset
	if self:GetControllerValid() then
		self:GetController():Reset()
	end
	GetWeaponManagerServer():RemoveWeapons(self)

end


function PlayerServer:GetName()

	--Forward the request to the parent
	return Player.GetName(self)

end


function PlayerServer:GetLinearVelocity()

	if IsValid(self:GetController()) then
		return self:GetController():GetLinearVelocity()
	end

	return WVector3()

end


function PlayerServer:NotifyControllerEnabled(setEnabled)

	self.stateParam:SetBoolData(setEnabled)
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ControllerEnabled", self.stateParam)

end


--BRIAN TODO: Should this be in Player.lua?
--This will be called by the parent Player class when the
--Controller is initialized
function PlayerServer:NotifyControllerActive()

	--Connect the Controller's Resetting signal to this player's reset slot
	local resetSignal = self:GetController():GetSignal("Resetting", false)
	if IsValid(resetSignal) then
		resetSignal:Connect(self.playerResettingSlot)
	end

end


function PlayerServer:NotifyControllerDeactive()

	self.playerResettingSlot:DisconnectAll()

end


function PlayerServer:SetRespawning(setRespawning)

	self.respawning = setRespawning

end


function PlayerServer:GetRespawning()

	return self.respawning

end


--The PlayerResetting slot simply forwards the signal
function PlayerServer:Resetting(resettingParams)

	--If nothing is doing something about a vehicle reset, just default to Reset()
	if self.playerResettingSignal:GetNumberOfConnections() > 0 then
		--This is the override
		self.playerResettingSignal:Emit(resettingParams)
	else
		GetServerManager():RespawnPlayer(self:GetUniqueID())
	end

end


function PlayerServer:SetQueuedWeapon(setQueuedWeaponTypeName)

	local possibleWeapon = setQueuedWeaponTypeName

	if self.weaponInQueue and IsValid(self.queuedWeaponTypeName) and IsValid(possibleWeapon) then
		self:SetQueuedAltWeapon(setQueuedWeaponTypeName)
	else
		self.queuedWeaponTypeName = possibleWeapon
		if IsValid(self.queuedWeaponTypeName) then
			self.weaponInQueue = true

			self.stateParam:SetStringData(self.queuedWeaponTypeName)
			GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedWeapon", self.stateParam)
		else
			if self.weaponInAltQueue and IsValid(self.queuedAltWeaponTypeName) then
				self.queuedWeaponTypeName = self.queuedAltWeaponTypeName
				self.queuedAltWeaponTypeName = ""

				self.weaponInQueue = true
				self.weaponInAltQueue = false
			else
				self.weaponInQueue = false
				self.queuedWeaponTypeName = ""
				self.weaponInAltQueue = false
				self.queuedAltWeaponTypeName = ""
			end
			
			self.stateParam:SetStringData(self.queuedWeaponTypeName)
			GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedWeapon", self.stateParam)

			self.stateParam:SetStringData(self.queuedAltWeaponTypeName)
			GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon", self.stateParam)
		end
	end
end

function PlayerServer:SetQueuedAltWeapon(setQueuedWeaponTypeName)

	if IsValid(setQueuedWeaponTypeName) then
		if self.weaponInQueue and IsValid(self.queuedWeaponTypeName) then
			self.queuedAltWeaponTypeName = setQueuedWeaponTypeName
			self.weaponInAltQueue = true
		end
	else
		self.queuedAltWeaponTypeName = ""
		self.weaponInAltQueue = false
	end

	self.stateParam:SetStringData(self.queuedAltWeaponTypeName)
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon", self.stateParam)
end

--Called when the player gets a new weapon, such as running into a weapon box or
--when they use their active weapon and have another weapon in queue
function PlayerServer:SetActiveWeapon(weapon)

	local weaponID = 0
	if IsValid(weapon) then
		--Don't allow a new weapon if there is already an active weapon
		if IsValid(self:GetActiveWeapon()) then
			return
		end

		self.activeWeapon = weapon

		weaponID = self.activeWeapon:GetID()
	else
		self.activeWeapon = nil
		weaponID = 0
	end

	self.stateParam:SetIntData(weaponID)
	GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ActiveWeapon", self.stateParam)

end


function PlayerServer:_RemoveWeapons()
	self:SetQueuedWeapon(nil)
	self:SetQueuedAltWeapon(nil)
	self:SetQueuedWeapon(nil)
	self:SetActiveWeapon(nil)
end


function PlayerServer:GetWeaponInQueue()

	return self.weaponInQueue

end


function PlayerServer:GetQueuedWeaponTypeName()

	return self.queuedWeaponTypeName

end


--The player may have only one active weapon at a time.
--This is the weapon which the player has control over.
function PlayerServer:GetActiveWeapon()

	return self.activeWeapon

end


function PlayerServer:InputEvent(eventParams)

	self.inputEventSignal:Emit(eventParams)

end

--PLAYERSERVER CLASS END