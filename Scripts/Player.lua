UseModule("IBase", "Scripts/")

--PLAYER CLASS START

--BRIAN TODO: Change name to IPlayer since it is an interface
class 'Player' (IBase)

function Player:__init(setName, setUniqueID, setPeer) super()

	if setUniqueID == 0 then
		error("Player ID is 0 in Player()")
	end
	self.name = setName
	self.uniqueID = setUniqueID
	self.peer = setPeer
	self.controllerObject = nil
	--Controller is assumed enabled from the start
	self.controllerEnabled = true

	--userData can be used for anything, keeping track of score, etc
	self.userData = { }

	self.controllerSetParam = Parameter()

end


function Player:BuildInterfaceDefIBase()

	self:AddClassDef("Player", "IBase", "The base Player class handles common tasks that specialized Player classes must derive from")
	self:AddFuncDef("Player", self.InitPlayer, self.I_REQUIRED_FUNC, "InitPlayer", "Will be called to notify the child it should init")
	self:AddFuncDef("Player", self.UnInitPlayer, self.I_REQUIRED_FUNC, "UnInitPlayer", "Will be called to notify the child it should uninit")
	self:AddFuncDef("Player", self.NotifyControllerActive, self.I_REQUIRED_FUNC, "NotifyControllerActive", "Will be called to notify the child class that a controller has been activated")
	self:AddFuncDef("Player", self.NotifyControllerDeactive, self.I_REQUIRED_FUNC, "NotifyControllerDeactive", "Will be called to notify the child class that a controller has been deactivated")

end


function Player:InitIBase()

	self:InitPlayer()

	--Must create state after InitPlayer() is called
	if IsClient() then
		self.controllerSetSlot = self:CreateSlot("ControllerSet", "ControllerSetSlot")
		GetClientSystem():GetReceiveStateTable("General"):WatchState(tostring(self:GetUniqueID()) .. "ControllerSet", self.controllerSetSlot)
	else
		GetServerSystem():GetSendStateTable("General"):NewState(tostring(self:GetUniqueID()) .. "ControllerSet")
		self.controllerSetParam:SetIntData(0)
		GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ControllerSet", self.controllerSetParam)
	end

end


function Player:UnInitIBase()

	if IsServer() then
		GetServerSystem():GetSendStateTable("General"):RemoveState(tostring(self:GetUniqueID()) .. "ControllerSet")
	end

	self:UnInitPlayer()

end


function Player:Process()

end


function Player:GetName()

	if IsValid(self.peer) then
		return self.peer:GetName()
	end

	return self.name

end


function Player:GetUniqueID()

	if IsValid(self.peer) then
		return self.peer:GetUniqueID()
	end

	return self.uniqueID

end


function Player:GetPing()

	if self:GetUniqueID() == 0 then
		error("Player ID is 0 in Player:GetPing()")
	end
	return GetNetworkSystem():GetClientState(self:GetUniqueID()):GetPing()

end


--Returns true if this player is controlled by a bot
function Player:GetBot()

	if self:GetUniqueID() == 0 then
		error("Player ID is 0 in Player:GetBot()")
	end
	return GetNetworkSystem():GetClientState(self:GetUniqueID()):GetBot()

end


function Player:GetNetworkPeer()

	return self.peer

end


--Set the Controller object that this player is in control of
--Pass in the IObject
function Player:SetController(setControllerObject)

	if self:GetUniqueID() == 0 then
		error("Player ID is 0 in Player:SetController()")
	end

	if IsValid(setControllerObject) then
		--Convert to the script object
		self.controllerObject = ToScriptObject(setControllerObject):Get()

		--Tell the controller who the boss is
		self:GetController():SetOwnerID(self:GetUniqueID())
	else
		self:NotifyControllerDeactive()
		--Only set self.controllerObject to nil at the end after the controller functions have been called
		self.controllerObject = nil
	end

	self:SetControllerEnabled(self:GetControllerEnabled())

	if self:GetControllerValid() then
		--Notify any child object that cares
		self:NotifyControllerActive()
	end

	if IsServer() then
		if IsValid(self.controllerObject) then
			self.controllerSetParam:SetIntData(self.controllerObject:GetID())
		else
			self.controllerSetParam:SetIntData(0)
		end
		GetServerSystem():GetSendStateTable("General"):SetState(tostring(self:GetUniqueID()) .. "ControllerSet", self.controllerSetParam)
	end

end


function Player:ControllerSetSlot(controllerParams)

	local controllerID = controllerParams:GetParameter(0, true):GetIntData()

	print("Controller with ID " .. tostring(controllerID) .. " set in ControllerSetSlot() for player with ID " .. tostring(self:GetUniqueID()) .. " named " .. self:GetName())

	local controllerObj = GetClientWorld():GetServerObject(controllerID)
	if (controllerID ~= 0) and (not IsValid(controllerObj)) then
		error("Controller Invalid in Player:ControllerSetSlot()")
	end
	self:SetController(controllerObj)

end


--This is provided so that the child class doesn't need to provide
--it if it doesn't care.
function Player:NotifyControllerSet()

end


--Return the Controller object that this player is in control of.
function Player:GetController()

	return self.controllerObject

end


--Return true if the Controller object is valid, false otherwise.
function Player:GetControllerValid()

	if IsValid(self:GetController()) then
		return true
	end

	return false

end


function Player:SetControllerEnabled(setEnabled)

    self.controllerEnabled = setEnabled

	if self:GetControllerValid() then
		self:GetController():SetEnabled(setEnabled)
	end

	--Notify the Player child
	self:NotifyControllerEnabled(self.controllerEnabled)

end


function Player:GetControllerEnabled()

	return self.controllerEnabled

end


--Return the position of the Controller which is the position of the player
function Player:GetPosition()

	if IsValid(self.controllerObject) then
		return self.controllerObject:GetPosition()
	end

	return WVector3()

end


--Return the orientation of the Controller which is the orientation of the player
function Player:GetOrientation()

	if IsValid(self.controllerObject) then
		return self.controllerObject:GetOrientation()
	end

	return WQuaternion()

end


function Player:GetLinearVelocity()

	if IsValid(self.controllerObject) then
		return self.controllerObject:GetLinearVelocity()
	end

	return WVector3()

end


function Player:GetBoundingBox()

	if self:GetControllerValid() then
		return self:GetController():GetBoundingBox()
	end
	return WAxisAlignedBox()

end


function Player:DoesOwn(objectID)

	if type(objectID) ~= "number" then
		error("Passed in object ID is not a number, it is of type: " .. type(objectID))
	end

	if IsValid(self.controllerObject) then
		return self.controllerObject:DoesOwn(objectID)
	end
	return false

end


function Player:ResetUserData()

	self.userData = { }

end

--PLAYER CLASS END