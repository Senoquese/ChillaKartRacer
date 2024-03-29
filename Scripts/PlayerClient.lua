UseModule("PlayerManagerClient", "Scripts/")
UseModule("GUIBoost", "Scripts\\GUI\\")
UseModule("GUIWeaponBox", "Scripts\\GUI\\")
UseModule("GUISignal", "Scripts\\GUI\\")

--PLAYERCLIENT CLASS START

class 'PlayerClient' (Player)

function PlayerClient:__init(setName, setUniqueID, isLocalPlayer) super(setName, setUniqueID, nil)

	self.boostEnabledSlot = self:CreateSlot("BoostEnabled", "BoostEnabledSlot")
	self.boostPercentSlot = self:CreateSlot("BoostPercent", "BoostPercentSlot")
	
	self.isLocalPlayer = isLocalPlayer

	self.weaponInQueue = false
	self.weaponInAltQueue = false
	--This is the weapon type name that is in queue to be used by the player
	self.queuedWeaponTypeName = ""
	self.queuedAltWeaponTypeName = ""
	--This is the current weapon that can be used by the player
	self.activeWeapon = nil

	self.currBoostPercent = 0

end


function PlayerClient:InitPlayer()

	self:InitState()

	--Only init if this is the local player
	if self:IsLocalPlayer() then
		--GUI elements such as the weapon display, etc
		self:InitGUI()
	end

end


function PlayerClient:UnInitPlayer()

	self.weaponInQueue = false
	self.weaponInAltQueue = false
	self.queuedWeaponTypeName = ""
	self.queuedAltWeaponTypeName = ""
	self.activeWeapon = nil

	if self:IsLocalPlayer() then
		self:UnInitGUI()
	end

end


function PlayerClient:InitState()

	--Is this player's controller currently enabled?
	self.controllerEnabledSlot = self:CreateSlot("ControllerEnabled", "ControllerEnabledSlot")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(tostring(self:GetUniqueID()) .. "ControllerEnabled", self.controllerEnabledSlot)

	self.activeWeaponSlot = self:CreateSlot("ActiveWeapon", "ActiveWeapon")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(tostring(self:GetUniqueID()) .. "ActiveWeapon", self.activeWeaponSlot)

	self.queuedWeaponSlot = self:CreateSlot("QueuedWeapon", "QueuedWeapon")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(tostring(self:GetUniqueID()) .. "QueuedWeapon", self.queuedWeaponSlot)

	self.queuedAltWeaponSlot = self:CreateSlot("QueuedAltWeapon", "QueuedAltWeapon")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(tostring(self:GetUniqueID()) .. "QueuedAltWeapon", self.queuedAltWeaponSlot)
end


function PlayerClient:InitGUI()

    self.guiVisible = true

	self.guiBoost = GUIBoost()
    self.guiWeapon = GUIWeaponBox()
    self.guiSignal = GUISignal()
    self.guiResetting = GetMyGUISystem():LoadLayout("resetting.layout", "Resetting_")
    self.guiResetting:SetVisible(false)
    self.guiCrosshairs = GetMyGUISystem():LoadLayout("crosshair.layout", "Crosshair_")
    self.guiCrosshairs:SetVisible(false)
    
end


function PlayerClient:UnInitGUI()
	if IsValid(self.guiBoost) then
		self.guiBoost:UnInit()
		self.guiBoost = nil
	end

    if IsValid(self.guiWeapon) then
		self.guiWeapon:UnInit()
		self.guiWeapon = nil
	end

    if IsValid(self.guiSignal) then
		self.guiSignal:UnInit()
		self.guiSignal = nil
	end
	
	if IsValid(self.guiResetting) then
		GetMyGUISystem():UnloadLayout(self.guiResetting)
		self.guiResetting = nil
	end
	
	if IsValid(self.guiCrosshairs) then
		GetMyGUISystem():UnloadLayout(self.guiCrosshairs)
		self.guiCrosshairs = nil
	end

end


function PlayerClient:SetGUIVisible(setVis)

    self.guiVisible = setVis
    self.guiBoost:SetVisible(setVis)
    self.guiWeapon:SetVisible(setVis)
    self.guiSignal:SetVisible(setVis)
    self.guiResetting:SetVisible(false)
    self.guiCrosshairs:SetVisible(false)

end


function PlayerClient:GetGUIVisible()

    return self.guiVisible

end


function PlayerClient:Process()

	self:ProcessGUI()

end


function PlayerClient:ProcessGUI()

	if GetCameraManager():IsFollowObject(self:GetController()) then
		--Kinda a hack :( only the local player has this GUI object
		if IsValid(self.guiBoost) then
			self.guiBoost:SetBoostPercent(self.currBoostPercent)
		else
			GetPlayerManager():GetLocalPlayer().guiBoost:SetBoostPercent(self.currBoostPercent)
		end
		
		if not IsValid(self.guiWeapon) then
			local weaponIconPath = ""
            if self.weaponInQueue and IsValid(self.queuedWeaponTypeName) then
                weaponIconPath = self.queuedWeaponTypeName..".png"
            end
            GetPlayerManager():GetLocalPlayer().guiWeapon:SetWeapon(weaponIconPath)
		end
	end
	
	if IsValid(self.guiSignal) then
        self.guiSignal:SetQuality((GetClientSystem():GetServerPing() * 1000))
    end
    
    if IsValid(self.guiBoost) then
        self.guiBoost:Process()
    end

end


function PlayerClient:GetGraphicalPosition()

	if self:GetControllerValid() then
		return self:GetController():GetGraphicalPosition()
	end
	return WVector3()

end


function PlayerClient:GetGraphicalOrientation()

	if self:GetControllerValid() then
		return self:GetController():GetGraphicalOrientation()
	end
	return WQuaternion()

end


function PlayerClient:ControllerEnabledSlot(controllerEnabledParams)

	self:SetControllerEnabled(controllerEnabledParams:GetParameterAtIndex(0, true):GetBoolData())

end


function PlayerClient:NotifyControllerEnabled(setEnabled)

	--Hide the name tag for this player if their controller is disabled
	print(self:GetName().." PlayerClient:NotifyControllerEnabled:"..tostring(setEnabled))
	GetMenuManager():GetNameTagManager():SetForceInvisible(self:GetUniqueID(), not setEnabled)

end


function PlayerClient:BoostEnabledSlot(boostParams)

end


function PlayerClient:BoostPercentSlot(boostParams)

	self.currBoostPercent = boostParams:GetParameterAtIndex(0, true):GetFloatData()

end

function PlayerClient:ShowResettingGui(visible)
    
    if IsValid(self.guiResetting) then
        self.guiResetting:SetVisible(visible)
    end

end

function PlayerClient:ShowCrosshairs(visible)
    
    if IsValid(self.guiCrosshairs) then
        self.guiCrosshairs:SetVisible(visible)
    end

end

--This will be called by the parent Player class when the IController is activated
function PlayerClient:NotifyControllerActive()

	print(self:GetName() .. " Controller Active")

	--We want to know when the controller changes boost
	self:GetController():GetSignal("BoostEnabled", true):Connect(self.boostEnabledSlot)
	self:GetController():GetSignal("BoostPercent", true):Connect(self.boostPercentSlot)

	--Activate the camera controller for this character controller if this is the local player
	if self:IsLocalPlayer() then
		--Tell the controller to activate its camera
		self:GetController():ActivateCamController()
		self.guiBoost:SetBoostPercent(0)
		self.currBoostPercent = 0
	end

end


function PlayerClient:NotifyControllerDeactive()

	self.boostEnabledSlot:DisconnectAll()
	self.boostPercentSlot:DisconnectAll()

	--Deactivate the camera controller for this character controller if this is the local player
	if self:IsLocalPlayer() and self:GetControllerValid() then
		--Tell the controller to activate its camera
		self:GetController():DeactivateCamController()
	end

end


--Is this player the local player?
function PlayerClient:IsLocalPlayer()

	return self.isLocalPlayer

end


--This is called when the player gets a new weapon in queue
function PlayerClient:QueuedWeapon(setWeaponParams)
	local possibleWeapon = setWeaponParams:GetParameter(0, true):GetStringData()

	print("queue weapon -> processing - "..possibleWeapon)

	print(self.weaponInQueue)
	print(self.queuedWeaponTypeName)
	print(self.weaponInAltQueue)
	print(self.queuedAltWeaponTypeName)
	
	if self.weaponInQueue and string.len(self.queuedWeaponTypeName) > 0 and string.len(possibleWeapon) > 0 then
		print("queued weapon -> go to alt queue")
		self:QueuedAltWeapon(setWeaponParams)
	else
		self.queuedWeaponTypeName = possibleWeapon
		if string.len(self.queuedWeaponTypeName) > 0 then
			self.weaponInQueue = true
			print("queue weapon -> equipped")
		else
			if self.weaponInAltQueue then
				print("queue weapon -> traded with alt")
				self.queuedWeaponTypeName = self.queuedAltWeaponTypeName
				self.queuedAltWeaponTypeName = ""

				self.weaponInQueue = true
				self.weaponInAltQueue = false
			else
				print("queue weapon -> emptied both")
				self.queuedWeaponTypeName = ""
				self.queuedAltWeaponTypeName = ""
				
				self.weaponInQueue = false
				self.weaponInAltQueue = false
			end
		end
	end

	self:SetWeaponIcons()
end

function PlayerClient:QueuedAltWeapon(setWeaponParams)
	local possibleWeapon = setWeaponParams:GetParameter(0, true):GetStringData()
	
	print("queue alt weapon -> processing "..possibleWeapon)

	if string.len(possibleWeapon) > 0 then
		if self.weaponInQueue and string.len(self.queuedWeaponTypeName) > 0 then
			print("queued alt weapon -> equipped")
			self.queuedAltWeaponTypeName = possibleWeapon
			self.weaponInAltQueue = true
		else
			print("queued alt weapon -> go to primary queue")
			self:QueuedWeapon(setWeaponParams)
		end
	else
		if self.weaponInQueue and string.len(self.queuedWeaponTypeName) > 0 then
			print("queued alt weapon -> traded with primary")
			self.queuedWeaponTypeName = self.queuedAltWeaponTypeName
			self.queuedAltWeaponTypeName = ""

			self.weaponInQueue = true
			self.weaponInAltQueue = false
		else
			print("queued alt weapon -> emptied")
			self.queuedAltWeaponTypeName = possibleWeapon
			self.weaponInAltQueue = false
		end
	end

	self:SetWeaponIcons()
end

function PlayerClient:SetWeaponIcons()
	if self:IsLocalPlayer() then
		local weaponIconPath = ""
		local altWeaponIconPath = ""

		if self.weaponInQueue then
			weaponIconPath = self.queuedWeaponTypeName..".png"
		end

		if self.weaponInAltQueue then
			altWeaponIconPath = self.queuedAltWeaponTypeName..".png"
		end

		self.guiWeapon:SetWeapon(weaponIconPath)
		self.guiWeapon:SetAltWeapon(altWeaponIconPath)
	end
end

--This is called when the player gets a new weapon
function PlayerClient:ActiveWeapon(setWeaponParams)

	local weaponID = setWeaponParams:GetParameter(0, true):GetIntData()
	if weaponID ~= 0 then
		self.activeWeapon = GetClientWorld():GetServerObject(weaponID)
	else
		self.activeWeapon = nil
	end

end

--PLAYERCLIENT CLASS END