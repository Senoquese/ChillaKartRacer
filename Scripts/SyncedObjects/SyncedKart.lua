--SyncedKart is a player controller
UseModule("IController", "Scripts/")
UseModule("AchievementManager", "Scripts/")
UseModule("SyncedKartManClient", "Scripts/SyncedObjects/")
UseModule("SyncedKartManServer", "Scripts/SyncedObjects/")
UseModule("ServerSettingsManager", "Scripts/")

--How much the boost grows per second for the person in last place
local KART_BOOST_AMOUNT = 5700
local setBoost = function (value) KART_BOOST_AMOUNT = value end
local getBoost = function () return KART_BOOST_AMOUNT end
DefineVar("KART_BOOST_AMOUNT", setBoost, getBoost)

--How much boost is used (burned) per second
local KART_BOOST_PERCENT_BPS = 0.15
local setBPS = function (value) KART_BOOST_PERCENT_BPS = value end
local getBPS = function () return KART_BOOST_PERCENT_BPS end
DefineVar("KART_BOOST_PERCENT_BPS", setBPS, getBPS)

KART_JETPACK_AMOUNT = 5000
JETPACKS_ENABLED = false

-- Suspension vars
GROUND_SUSPENSION_STIFFNESS = 180
GROUND_SUSPENSION_DAMPENING = 10
GROUND_SUSPENSION_COMPRESSION = 10
GROUND_SUSPENSION_REST_LENGTH = 0.35
GROUND_SUSPENSION_MAX_TRAVEL = 50
GROUND_ANGULAR_DAMPENING = 0.99
--
AIR_SUSPENSION_STIFFNESS = 200
AIR_SUSPENSION_DAMPENING = 50
AIR_SUSPENSION_COMPRESSION = 10
AIR_SUSPENSION_REST_LENGTH = 0.7
AIR_SUSPENSION_MAX_TRAVEL = 50
AIR_ANGULAR_DAMPENING = 0.990
SUSPENSION_EASE_TIME = 1

BASE_ANGULAR_DAMPENING = 0.95
MAX_ANGULAR_DAMPENING = 0.995

--How much air steering
local KART_AIRSTEER_AMOUNT = 19*2.1
local KART_HOP_TURN_FORCE = 4.75*0.6

local KART_DRIFTSTEER_AMOUNT = (19*2.1)*1.5
local KART_DRIFTSTEER_PERCENTAGE = 0.5

--SYNCEDKART CLASS START

--SyncedKart
class 'SyncedKart' (IController)

function SyncedKart:__init() super()

	--Input tracking
	self.keyMap = { }
	self.axisMap = { }
	self.jsPosX = 0
	self.jsPosY = 0
	self.axisMovedThres = 0.3
	self.axisMovedCameraThres = 0.6
	self:ResetKeyMap(false)
	self.controlRightDown = false
	self.controlLeftDown = false
	self.controlAccelDown = false
	self.controlReverseDown = false
	self.inAir = false
	self.hopping = false
	self.lastVelocity = WVector3(0, 0, 0)
	self.airClock = WTimer()
	self.airClock:Reset()
	self.airClock:Stop()
	self.airTime = 0
	self.boostBurned = 0
	self.iceCount = 0
	self.weaponsUsed = false
	self.airPitch = 0
	self.airRoll = 0
	self.lastPitch = 180
	self.lastRoll = 180
	self.look = WQuaternion()
	self.lastOrientation = WQuaternion()
	self.draftAmount = 0
	self.driftingDirection = 0
	self.driftingLerp = 0
	self.driftingTurbo = 0

	self.cameraMoveResetTime = 0.75

	self.achievements = AchievementManager()
	
	--self.processClock = WTimer()

	self.odometer = 0
	self.lastPos = nil

	--BRIAN TODO: Test code only
	self.forceClientToServerSync = true

	self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")

	self.kartResettingSlot = self:CreateSlot("Resetting", "Resetting")
	self.kartResettingSignal = self:CreateSignal("Resetting")

	self.kartStuntSignal = self:CreateSignal("Stunt")
	self.kartStuntParams = Parameters()

	self.camController = nil
	
	self.mouseLooking = false

	--Keeps track of what needs to be loaded later
	self.deferredLoad = { }
	--Colors need to be set after the items are loaded
	self.deferredColorLoad = { }

	if IsClient() then
		self.loadingAllowedSlot = self:CreateSlot("LoadingAllowedSlot", "LoadingAllowedSlot")
		GetClientManager():GetSignal("LoadingAllowed", true):Connect(self.loadingAllowedSlot)
	end

end

function SyncedKart:iced()

	self.iceCount = self.iceCount + 1
	print("iceCount = "..self.iceCount)
	if self.isLocalPlayer and self.iceCount == 5 then
		self.achievements:Unlock(self.achievements.AVMT_CLIMATE_CHANGE)
	end

end

function SyncedKart:BuildInterfaceDefIController()

	self:AddClassDef("SyncedKart", "IController", "A SyncedKart allows a player to control a kart")

end

function SyncedKart:BulletCollisionStart()

	self.airRoll = 0
	self.airPitch = 0

end

function SyncedKart:ActivateCamController()

	if not IsValid(self.camController) then
		self.camController = CamControllerKartCombiner(self, GetCamera())
		self.camController:Init()
		self.camController.camera:SetPosition(self:GetPosition())
	end
	--Character camera controllers are always priority 1
	GetCameraManager():AddController(self.camController, 1)

end


function SyncedKart:DeactivateCamController()

	GetCameraManager():RemoveController(self.camController)

end


function SyncedKart:InitController()

	local syncedKartInitControllerClock = WTimer()

	if IsClient() then
		--Init the wheel friction state
		self.wheelFrictionSlot = self:CreateSlot("SetWheelFrictionSlot", "SetWheelFrictionSlot")
		GetClientSystem():GetReceiveStateTable("Map"):WatchState("KartWF" .. tostring(GetClientWorld():GetServerObjectID(self:GetID())), self.wheelFrictionSlot)

		--Only the client has a graphical object
		local initGrapClock = WTimer()
		self:InitGraphical()
		print("SyncedKart:InitController() InitGraphical() RunTime: " .. tostring(initGrapClock:GetTimeSeconds()))
		self:InitSounds()
		
		--Recieve mouse events
		self.mouseMovedSlot = self:CreateSlot("MouseMoved", "MouseMoved")
		GetClientInputManager():GetSignal("MouseMoved", true):Connect(self.mouseMovedSlot)

		--self.jsMovedSlot = self:CreateSlot("JSMoved", "JSMoved")
		--GetClientInputManager():GetSignal("JSMoved", true):Connect(self.jsMovedSlot)
	else
		--Init the wheel friction state
		GetServerSystem():GetSendStateTable("Map"):NewState("KartWF" .. tostring(self:GetID()))
		self.kartWFParam = Parameter()
		--Set gravity
		GetBulletPhysicsSystem():SetGravity(Tags(Tags.ANY), WVector3(0, -15, 0))
	end

	--Both the client and server simulate a physical object
	local initPhyClock = WTimer()
	self:InitPhysical()
	print("SyncedKart:InitController() InitPhysical() RunTime: " .. tostring(initPhyClock:GetTimeSeconds()))

	--The UpdateMaterial signal/slot is for the material the kart is currently on
	--The graphicalKart displays a particle effect based on this material
	if IsValid(self.physicalKart) then
		--self.physicalKart:GetSignal("StartCollision", true):Connect(self.collisionStartSlot)
		if IsClient() then
		
			self.kartManClient = SyncedKartManClient(self.graphicalKart, self.physicalKart)
		
			self.physicalKart:GetSignal("UpdateMaterial", true):Connect(self.graphicalKart:GetSlot("UpdateMaterial", true))
		else
			self.physicalKart:GetSignal("Resetting", true):Connect(self.kartResettingSlot)
		end

		--init look
		self.look = self:GetGraphicalOrientation()
	end

	print("SyncedKart:InitController() RunTime: " .. tostring(syncedKartInitControllerClock:GetTimeSeconds()))

end


function SyncedKart:ResetKeyMap(pressed)

	print("RESETTING KEYMAP")
	self.keyMap = { }
	for keyName, keyCode in pairs(InputMap) do
		self.keyMap[keyCode] = { pressed, 0 }
	end

end


function SyncedKart:SetKeyMap(keyCode, pressed, powerLevel)

	self.keyMap[keyCode][1] = pressed
	self.keyMap[keyCode][2] = powerLevel

	if IsServer() and keyCode == InputMap.Hop then
	   self.kartManServer.hopKeyDown = pressed
	end

end


function SyncedKart:GetKeyPressed(keyCode)

	if #self.keyMap == 0 then
		--error("KeyMap is empty.")
	end
	return self.keyMap[keyCode][1]

end


function SyncedKart:GetKeyPowerLevel(keyCode)

	return self.keyMap[keyCode][2]

end


function SyncedKart:InitCustomSettingsState()

	--Kart
	local slotName = tostring(self:GetOwnerID()) .. "KartName"
	if IsValid(self.setKartSlot) then
		self:DestroySlot(self.setKartSlot)
	end
	self.setKartSlot = self:CreateSlot(slotName, "SetKartSlot")

	print("Watching for kart name in slot named: " .. slotName .. " for owner ID: " .. tostring(self:GetOwnerID()))

	GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setKartSlot)

	if IsValid(self.setKartColorSlots) then
		local ds = 1
		while ds <= 4 do
			self:DestroySlot(self.setKartColorSlots[ds])
		end
	end
	self.setKartColorSlots = { }
	local kartColorFuncs = { "SetKartColor1Slot", "SetKartColor2Slot", "SetKartColor3Slot", "SetKartColor4Slot" }
	local c = 1
	--Max of 4 colors allowed
	while c <= 4 do
		slotName = tostring(self:GetOwnerID()) .. "KartColor" .. tostring(c)
		self.setKartColorSlots[c] = self:CreateSlot(slotName, kartColorFuncs[c])
		GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setKartColorSlots[c])
		c = c + 1
	end

	--Character
	slotName = tostring(self:GetOwnerID()) .. "CharacterName"
	if IsValid(self.setCharacterSlot) then
		self:DestroySlot(self.setCharacterSlot)
	end
	self.setCharacterSlot = self:CreateSlot(slotName, "SetCharacterSlot")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setCharacterSlot)

	if IsValid(self.setCharacterColorSlots) then
		local ds = 1
		while ds <= 4 do
			self:DestroySlot(self.setCharacterColorSlots[ds])
		end
	end
	self.setCharacterColorSlots = { }
	local characterColorFuncs = { "SetCharacterColor1Slot", "SetCharacterColor2Slot", "SetCharacterColor3Slot", "SetCharacterColor4Slot" }
	c = 1
	--Max of 4 colors allowed
	while c <= 4 do
		slotName = tostring(self:GetOwnerID()) .. "CharacterColor" .. tostring(c)
		self.setCharacterColorSlots[c] = self:CreateSlot(slotName, characterColorFuncs[c])
		GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setCharacterColorSlots[c])
		c = c + 1
	end

	--Wheel
	slotName = tostring(self:GetOwnerID()) .. "WheelName"
	if IsValid(self.setWheelSlot) then
		self:DestroySlot(self.setWheelSlot)
	end
	self.setWheelSlot = self:CreateSlot(slotName, "SetWheelSlot")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setWheelSlot)

	if IsValid(self.setWheelColorSlots) then
		local ds = 1
		while ds <= 4 do
			self:DestroySlot(self.setWheelColorSlots[ds])
		end
	end
	self.setWheelColorSlots = { }
	local wheelColorFuncs = { "SetWheelColor1Slot", "SetWheelColor2Slot", "SetWheelColor3Slot", "SetWheelColor4Slot" }
	c = 1
	--Max of 4 colors allowed
	while c <= 4 do
		slotName = tostring(self:GetOwnerID()) .. "WheelColor" .. tostring(c)
		self.setWheelColorSlots[c] = self:CreateSlot(slotName, wheelColorFuncs[c])
		GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setWheelColorSlots[c])
		c = c + 1
	end

	--Hat
	slotName = tostring(self:GetOwnerID()) .. "HatName"
	if IsValid(self.setHatSlot) then
		self:DestroySlot(self.setHatSlot)
	end
	self.setHatSlot = self:CreateSlot(slotName, "SetHatSlot")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setHatSlot)

	if IsValid(self.setHatColorSlots) then
		local ds = 1
		while ds <= 4 do
			self:DestroySlot(self.setHatColorSlots[ds])
		end
	end
	self.setHatColorSlots = { }
	local hatColorFuncs = { "SetHatColor1Slot", "SetHatColor2Slot", "SetHatColor3Slot", "SetHatColor4Slot" }
	c = 1
	--Max of 4 colors allowed
	while c <= 4 do
		slotName = tostring(self:GetOwnerID()) .. "HatColor" .. tostring(c)
		self.setHatColorSlots[c] = self:CreateSlot(slotName, hatColorFuncs[c])
		GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setHatColorSlots[c])
		c = c + 1
	end

	--Accessory
	slotName = tostring(self:GetOwnerID()) .. "AccessoryName"
	if IsValid(self.setAccessorySlot) then
		self:DestroySlot(self.setAccessorySlot)
	end
	self.setAccessorySlot = self:CreateSlot(slotName, "SetAccessorySlot")
	GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setAccessorySlot)

	if IsValid(self.setAccessoryColorSlots) then
		local ds = 1
		while ds <= 4 do
			self:DestroySlot(self.setAccessoryColorSlots[ds])
		end
	end
	self.setAccessoryColorSlots = { }
	local accessoryColorFuncs = { "SetAccessoryColor1Slot", "SetAccessoryColor2Slot", "SetAccessoryColor3Slot", "SetAccessoryColor4Slot" }
	c = 1
	--Max of 4 colors allowed
	while c <= 4 do
		slotName = tostring(self:GetOwnerID()) .. "AccessoryColor" .. tostring(c)
		self.setAccessoryColorSlots[c] = self:CreateSlot(slotName, accessoryColorFuncs[c])
		GetClientSystem():GetReceiveStateTable("General"):WatchState(slotName, self.setAccessoryColorSlots[c])
		c = c + 1
	end
end


function SyncedKart:UnInitController()

	print("SyncedKart UnInitController() " .. tostring(self:GetID()))

	if IsServer() then
		--UnInit the wheel friction state
		GetServerSystem():GetSendStateTable("Map"):RemoveState("KartWF" .. tostring(self:GetID()))
	end

	--Only the client has a graphical object
	if IsClient() then
	
		self:UnInitGraphical()
		self:UnInitSounds()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

	--No character controller set anymore, destroy the camera
	if IsValid(self.camController) then
		self.camController:UnInit()
		self.camController = nil
	end

end


function SyncedKart:InitGraphical()

	self.settingsSerializer = SavedItemsSerializer()

	local spawnParams = Parameters()
	for settingName, settingValue in pairs(self.settingsSerializer:GetSettings()) do
		spawnParams:AddParameter(Parameter(settingName .. "Name", settingValue.Name))
	end

	spawnParams:AddParameter(Parameter("Position", self:GetPosition()))
	spawnParams:AddParameter(Parameter("Orientation", self:GetOrientation()))
	spawnParams:AddParameter(Parameter("Scale", WVector3(1.5, 1.5, 1.5)))
	--Extra params
	spawnParams:AddParameter(Parameter("WheelConnectionX", 0.354*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionY", 0.12*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZFront", 0.282*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZBack", -0.3*1.5))
	--How fast the graphical wheel spins, should look like it matches us based on the speed if
	--the value is right
	spawnParams:AddParameter(Parameter("WheelSpinStep", 3000))
	spawnParams:AddParameter(Parameter("CastShadows", true))
	spawnParams:AddParameter(Parameter("ReceiveShadows", false))

	self.graphicalKart = OGREPlayerKart()
	self.graphicalKart:SetName(self.name .. "G")
	self.graphicalKart:Init(spawnParams)

	--Just use the local clients kart settings for now until we have the real customization settings
	self:ApplyKartCustomSettings()

	--BRIAN TODO: For testing only, draw the client and server physical karts
	self.clientRenderer = OGRELines()
	self.clientRenderer:Init(Parameters())
	self.serverRenderer = OGRELines()
	self.serverRenderer:Init(Parameters())

	self.clientRenderer:CreateLineBox(WColorValue(1, 0, 0, 0), 0.5)
	self.serverRenderer:CreateLineBox(WColorValue(1, 1, 1, 0), 0.5)

	--Assume not visible by default
	self.clientRenderer:SetVisible(false)
	self.serverRenderer:SetVisible(false)
end


--Pull the customized settings out of the setting table
--and apply them to this kart
function SyncedKart:ApplyKartCustomSettings()

	local categories = { { "Kart", self.SetKart, self.SetKartColor },
						 { "Character", self.SetCharacter, self.SetCharacterColor },
						 { "Wheel", self.SetWheel, self.SetWheelColor },
						 { "Hat", self.SetHat, self.SetHatColor },
						 { "Accessory", self.SetAccessory, self.SetAccessoryColor } }
	local i = 1
	while i <= #categories do
		local catName = categories[i][1]
		local catSetFunc = categories[i][2]
		local catSetColorFunc = categories[i][3]
		local currentSetting = GetSettingTable():GetSetting("Custom" .. catName .. "Name", "Shared", false)
		if IsValid(currentSetting) then
			catSetFunc(self, currentSetting:GetStringData())
		end
		local c = 1
		while c <= CustomItem.MAX_NUM_COLORS do
			local currentColorSetting = GetSettingTable():GetSetting("Custom" .. catName .. "Color" .. tostring(c), "Shared", false)
			if IsValid(currentColorSetting) then
				local colorStr = currentColorSetting:GetStringData()
				if string.len(colorStr) > 0 then
					local red = CustomItemParseColor(currentColorSetting:GetStringData(), CustomItem.RED)
					local green = CustomItemParseColor(currentColorSetting:GetStringData(), CustomItem.GREEN)
					local blue = CustomItemParseColor(currentColorSetting:GetStringData(), CustomItem.BLUE)
					catSetColorFunc(self, "Color" .. tostring(c), red, green, blue, 1)
				end
			end
			c = c + 1
		end
		i = i + 1
	end

end


function SyncedKart:UnInitGraphical()

	if IsValid(self.graphicalKart) then
		self.graphicalKart:UnInit()
		self.graphicalKart = nil
	end

	if IsValid(self.kartManClient) then
		self.kartManClient:UnInit()
		self.kartManClient = nil
	end

	if IsValid(self.clientRenderer) then
		self.clientRenderer:UnInit()
		self.clientRenderer = nil
	end

	if IsValid(self.serverRenderer) then
		self.serverRenderer:UnInit()
		self.serverRenderer = nil
	end

end


function SyncedKart:InitSounds()

	self.currentSurfaceSound = SoundSource()
	self.currentSurfaceSound:SetName("surfaceSound_" .. self.name)
	self.currentSurfaceSound:Init(Parameters())
	self.currentSurfaceSound:SetLooping(true)
	self.currentSurfaceSound:SetVolume(1)
	self.currentSurfaceSound:SetReferenceDistance(10)

	self.graphicalKart:GetSignal("SetTransform", true):Connect(self.currentSurfaceSound:GetSlot("SetTransform", true))

end


function SyncedKart:UnInitSounds()

	if IsValid(self.currentSurfaceSound) then
		self.currentSurfaceSound:UnInit()
		self.currentSurfaceSound = nil
	end

end

KART_CC = ServerSettingsManager().kartCC

function SyncedKart:InitPhysical()

	local kartParams = Parameters()
	kartParams:AddParameter(Parameter("Position", self:GetPosition()))
	kartParams:AddParameter(Parameter("Orientation", self:GetOrientation()))
	kartParams:AddParameter(Parameter("Scale", WVector3(1.5, 1.5, 1.5)))
	kartParams:AddParameter(Parameter("Mass", 460))
	kartParams:AddParameter(Parameter("LinearDamping", 0.18))
	kartParams:AddParameter(Parameter("AngularDamping", 0.995))

	kartParams:AddParameter(Parameter("MaxSpeed", 120*(KART_CC+100)/200))
	-- kartParams:AddParameter(Parameter("MaxSpeed", 175))

	kartParams:AddParameter(Parameter("ReverseForceScale", 0.5))
	kartParams:AddParameter(Parameter("AccelTime", 4*(KART_CC/100)))

	-- kartParams:AddParameter(Parameter("MaxEngineForce", 1500))
	kartParams:AddParameter(Parameter("MaxEngineForce", 1230*(KART_CC+100)/200))

	-- kartParams:AddParameter(Parameter("MinEngineForce", 1000))
	kartParams:AddParameter(Parameter("MinEngineForce", 820*(KART_CC+100)/200))

	kartParams:AddParameter(Parameter("MaxBrakeForce", 25*(KART_CC/100)))
	kartParams:AddParameter(Parameter("MinBrakeForce", 2.5))
	kartParams:AddParameter(Parameter("SteeringAcceleration", 0.7*2))
	kartParams:AddParameter(Parameter("SteeringMinClamp", (0.0365/2)*1.5))

	kartParams:AddParameter(Parameter("SteeringMaxClamp", 0.2*0.75*(100/KART_CC)*1.5))

	-- kartParams:AddParameter(Parameter("SteeringMaxClamp", 0.13))
	-- original 0.13
	kartParams:AddParameter(Parameter("WheelRadius", 0.24*1.5*1.4))
	if not IsValid(self.wheelInitFriction) then
		self.wheelInitFriction = 5
	end
	kartParams:AddParameter(Parameter("WheelFriction", self.wheelInitFriction))
	kartParams:AddParameter(Parameter("WheelConnectionX", 0.5*1.5))
	kartParams:AddParameter(Parameter("WheelConnectionY", 0.535*1.5))
	kartParams:AddParameter(Parameter("WheelConnectionZFront", 0.38*1.5))
	kartParams:AddParameter(Parameter("WheelConnectionZBack", -0.38*1.5))

	-- how much force is required to compress the suspension
	kartParams:AddParameter(Parameter("SuspensionStiffness", GROUND_SUSPENSION_STIFFNESS))

	-- how much force pushes back in the opposite direction
	kartParams:AddParameter(Parameter("SuspensionDamping", GROUND_SUSPENSION_DAMPENING))

	-- how far the suspension will compress (making this higher increases skid out)
	kartParams:AddParameter(Parameter("SuspensionCompression", GROUND_SUSPENSION_COMPRESSION))

	kartParams:AddParameter(Parameter("SuspensionRestLength", GROUND_SUSPENSION_REST_LENGTH))
	kartParams:AddParameter(Parameter("MaxSuspensionTravelCm", GROUND_SUSPENSION_MAX_TRAVEL))
	kartParams:AddParameter(Parameter("RollInfluence", 0))
	kartParams:AddParameter(Parameter("HandbrakeWheelClampStep", 2))
	kartParams:AddParameter(Parameter("HandbrakeWheelClampUpperLimit", 2))
	kartParams:AddParameter(Parameter("HandbrakeWheelClampLowerLimit", 0.1))
	kartParams:AddParameter(Parameter("ChassisWidth", 1))
	kartParams:AddParameter(Parameter("ChassisHeight", 0.4))
	kartParams:AddParameter(Parameter("ChassisDepth", 1.25))
	kartParams:AddParameter(Parameter("CenterOfMassX", 0))
	kartParams:AddParameter(Parameter("CenterOfMassY", 0.4))
	kartParams:AddParameter(Parameter("CenterOfMassZ", 0))
	kartParams:AddParameter(Parameter("BoostMaxSpeedIncrease", 1.00))
	kartParams:AddParameter(Parameter("BoostMaxSpeedChangePerSecond", 0.4))
	kartParams:AddParameter(Parameter("Friction", 0))
	kartParams:AddParameter(Parameter("Restitution", 0))
	kartParams:AddParameter(Parameter("Static", false))

	self.physicalKart = BulletVehicle()
	self.physicalKart:SetName(self.name .. "P")
	self.physicalKart:Init(kartParams)
	self.physicalKart:SetInWorld(self:GetEnabled())

	--Default to ALL_WHEEL_DRIVE
	self:SetWheelDriveMode(BulletVehicle.ALL_WHEEL_DRIVE)

	--Default to TWO_WHEEL_GRIP
	self:SetWheelGripMode(BulletVehicle.TWO_WHEEL_GRIP)

	--The SyncedKartManServer
	self.kartManServer = SyncedKartManServer(self.physicalKart)

	if IsValid(self.wheelInitFriction) then
		self:SetWheelFriction(self.wheelInitFriction)
	end
end


function SyncedKart:UnInitPhysical()

	if IsValid(self.physicalKart) then
		self.physicalKart:UnInit()
		self.physicalKart = nil
	end

	if IsValid(self.kartManServer) then
		self.kartManServer:UnInit()
		self.kartManServer = nil
	end

end


function SyncedKart:DoesOwn(ownObjectID)

	local owned = self.kartManServer:DoesOwn(ownObjectID)
	if not owned and IsClient() then
		owned = self.kartManClient:DoesOwn(ownObjectID)
	end

	return owned

end


function SyncedKart:NotifyRespawnedImp(respawnPos, respawnOrien)

	if IsClient() then
		print("NotifyRespawn curPos: "..tostring(self:GetPosition()).." respawnPos: "..tostring(respawnPos))
	
		if GetClientManager():GetCurrentMapName() == "Fallout" then
			--Check for far out achievement
			local curPos = WVector3(self:GetPosition().x, 0, self:GetPosition().z) 
			--curPos.y = 0
			local platformRadius = 183
			local dist = curPos:Length()-platformRadius
			if dist > 0 then
				print("Distance from platform: "..dist)
				if dist > 100 and self.isLocalPlayer then
					self.achievements:Unlock(self.achievements.AVMT_DEEP_SPACE)
				end
			end
		end
	
		self.kartManClient:NotifyRespawned(respawnPos, respawnOrien)
		self.graphicalKart:SetPosition(respawnPos)
		self.graphicalKart:SetOrientation(respawnOrien)
		
		self.airClock:Reset()
		self.airClock:Stop()
		
		local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
		if IsValid(player.guiResetting) then
			if  player.guiResetting:GetVisible() then
				self.achievements:UpdateStat(self.achievements.STAT_RESET_COUNT, 1)
			end
			player:ShowResettingGui(false)
		end
	else
		
	end
	
	self.airPitch = 0
	self.airRoll = 0

end


--This slot simply forwards the signal
function SyncedKart:Resetting(resettingParams)

	self.kartResettingSignal:Emit(resettingParams)
	self.airClock:Reset()
	self.airClock:Stop()
	self.airPitch = 0
	self.airRoll = 0

end


function SyncedKart:NotifyControllerPositionChange(setPos)

	if IsValid(self.physicalKart) and self:GetAllWheelsInContact() and self:GetEnableControls() and self:GetEnabled() then
		self.odometer = self.odometer + (--[[meters--]] (self.physicalKart:GetPosition()-setPos):Length()/3 )
		--print("odo: "..self.odometer)
		
		-- update odometer
		if self.isLocalPlayer and self.odometer > 1000 then
			-- convert from meters to miles
			self.achievements:UpdateStat(self.achievements.STAT_MILES_DRIVEN, self.odometer * 0.000621371192)           
			self.odometer = 0
		end
	end

	--Don't change the transform if force is enabled on client
	if IsServer() or (IsClient() and self.forceClientToServerSync) then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetPosition(setPos)
		end

		if IsValid(self.physicalKart) then
			self.physicalKart:SetPosition(setPos)
		end
	end

end


function SyncedKart:NotifyControllerOrientationChange(setOrien)

	--Don't change the physical transform if force is enabled on client
	if IsServer() or (IsClient() and self.forceClientToServerSync) then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetOrientation(setOrien*WQuaternion(0,self.driftingLerp*50,0))
		end

		if IsValid(self.physicalKart) then
			self.physicalKart:SetOrientation(setOrien)
		end
	end

end


function SyncedKart:NotifyControllerSetMass(setMass)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetMass(setMass)
	end

end


function SyncedKart:GetMass()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetMass()
	end
	return 0

end


function SyncedKart:NotifyControllerSetLinearDamping(setDamping)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetLinearDamping(setDamping)
	end

end


function SyncedKart:NotifyControllerSetAngularDamping(setDamping)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetAngularDamping(setDamping)
	end

end


function SyncedKart:GetGraphicalPosition()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetPosition()
	end
	return WVector3()

end


function SyncedKart:GetLookForward()

	if IsValid(self.graphicalKart) then
		return self.look:zAxis()
	end
	return WVector3()

end


function SyncedKart:IsMouseLooking()
	return self.mouseLooking
end


function SyncedKart:IsHopping()
	return self.hopping
end


function SyncedKart:GetLookOrientation()

	if IsValid(self.graphicalKart) then
		return self.look
	end
	return WQuaternion()

end


function SyncedKart:GetGraphicalOrientation()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetOrientation()
	end
	return WQuaternion()

end


function SyncedKart:Reset()

	if IsValid(self.physicalKart) then
		--BRIAN TODO: Why does physicalKart need to reset?
		self.physicalKart:Reset()
		self.physicalKart:SetAngularVelocity(WVector3(0,0,0))
	end
	
	local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
	--print("ICED? "..tostring(player.userData.iced))
	if player.userData.iced then
		self:SetWheelFriction(0)
	end
	
	self:SetBoostPercent(0)
	self.draftAmount = 0

end


function SyncedKart:GetControllerActive()

	return not self.physicalKart:GetSleeping()

end


function SyncedKart:SetControllerStateData(stateBuiltTime, setState)

	local pos = setState:ReadWVector3()
	local orien = setState:ReadWQuaternion()
	local vel = setState:ReadWVector3()
	--local angVel = setState:ReadWVector3()
	local drafting = setState:ReadChar() / 256
	self:SetDraftEnabled(drafting)

	local state = BulletWorldObjectState()
	state:SetPosition(pos)
	state:SetOrientation(orien)
	state:SetLinearVelocity(vel)
	state:SetAngularVelocity(WVector3())--angVel)

	if self.forceClientToServerSync then
		GetBulletPhysicsSystem():SetObjectState("Main", self.physicalKart:GetID(), state)

		--We must update the transform of this object now so the ClientWorld can lerp properly
		self:SetPosition(pos, false)
		self:SetOrientation(orien, false)
		self:SetLinearVelocity(vel, false)
	end

	--Sync the server physical renderer to the last update we received from the server
	if IsValid(self.serverRenderer) then
		self.serverRenderer:SetPosition(pos)
		self.serverRenderer:SetOrientation(orien)
	end

end


function SyncedKart:GetControllerStateData(returnState)

	if IsValid(self.physicalKart) then
		returnState:WriteWVector3(self.physicalKart:GetPosition())
		returnState:WriteWQuaternion(self.physicalKart:GetOrientation())
		returnState:WriteWVector3(self.physicalKart:GetLinearVelocity())
		--returnState:WriteWVector3(self.physicalKart:GetAngularVelocity())
		returnState:WriteChar(self.draftAmount * 256)
	end

end


function SyncedKart:SetDraftEnabled(draft)

	if draft > 0 and not IsValid(self.draftStart) then
		--DRAFT START
		self.draftStart = GetClientSystem():GetTime()
	elseif draft <= 0 and IsValid(self.draftStart) then
		--DRAFT END
		local draftDuration = GetClientSystem():GetTime() - self.draftStart
		self.draftStart = nil
		if self.isLocalPlayer then
			--print("DraftDuration: "..draftDuration)
			if draftDuration > 10 then
				self.achievements:Unlock(self.achievements.AVMT_DRAFT_MASTER)
			end
		end
	end
	if IsValid(self.kartManClient) then
		self.kartManClient:EnableDraft(draft)
	end

end


function SyncedKart:MouseMoved(mouseParams)

	if not GetClientInputManager().autoMouseLook and not self.jetpackActive then
		return
	end

	local mouseXRel = mouseParams:GetParameter("MouseXRelative", true):GetIntData()
	--local mouseYRel = mouseParams:GetParameter("MouseYRelative", true):GetIntData()
	--Sensitivity
	local mSense = ((GetClientInputManager().mouseSensitivity + 1) / 50)
	--print("mSense:"..mSense)
	mouseXRel = mouseXRel * mSense / 5
	local mouseQuat = WQuaternion(0, -mouseXRel, 0);

	local pastThres = IsValid(self.lastMove) and GetClientSystem():GetTime() - self.lastMove < 0.1 and math.abs(mouseXRel) > 1

	if GetClientInputManager().autoMouseLook and pastThres then
		if IsValid(self.lastLookEnd) and GetClientSystem():GetTime() - self.lastLookEnd < 1 then
			self:MouseLookEnd()
		else
			self:MouseLookStart()
		end
	end
	self.lastMove = GetClientSystem():GetTime()

	--local mouseQuat = WQuaternion(mouseYRel / 10, -mouseXRel / 10, 0);
	self.look = self.look * mouseQuat

	local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
	if IsValid(player) then
		player:ShowCrosshairs(player.weaponInQueue and self.mouseLooking)
	end

end


function SyncedKart:MouseLookStart()

	if self.mouseLooking then
		return
	end

	self.mouseLooking = true

	local linVel = self:GetLinearVelocity()
	if linVel:Equals(WVector3(0, 0, 0), 0.5) then
		linVel = WVector3(self:GetOrientation():zAxis())
	end

	--project linVel into xz plane
	linVel.y = 0

	local camToKart = self:GetGraphicalPosition() - GetCamera():GetPosition()
	camToKart.y = 0

	local newLook = GetRotationTo(WQuaternion():zAxis(), camToKart, WVector3())
	self.look = newLook

end


function SyncedKart:MouseLookEnd()

	self.mouseLooking = false
	GetPlayerManager():GetPlayerFromID(self:GetOwnerID()):ShowCrosshairs(false)

end


function SyncedKart:JSMoved(x, y)

	if IsClient() and GetClientInputManager().gamePadMouseLook == true then
		local rotX = x
		local rotY = y

		local jsVec = WVector3(rotX, -rotY, 0)
		jsVec:Normalise()
		local angle = RadianToDegree(math.acos(WVector3(0, 1, 0):DotProduct(jsVec)))
		if rotX > 0 then
			angle = -angle
		end
		--Stay relative to the kart orientation
		local mouseQuat = WQuaternion(0, angle, 0) * self:GetGraphicalOrientation()

		self:MouseLookStart()
		self.lastMove = GetClientSystem():GetTime() - self.cameraMoveResetTime

		self.look = mouseQuat

		local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
		if IsValid(player) then
			player:ShowCrosshairs(player.weaponInQueue and self.mouseLooking)
		end
	end

end


function SyncedKart:KeyEvent(keyID, pressed, extraData)

	return self:ExecuteInputEvent(keyID, pressed, extraData, 1, 1)

end


function SyncedKart:AxisMovedEvent(axisID, position)

	--Check if this is a big enough difference from the old axis position
	if not IsValid(self.axisMap[axisID]) or math.abs(self.axisMap[axisID] - position) > 0.1 or
	   axisID == InputMap.ControlCameraLeft or axisID == InputMap.ControlCameraRight or
	   axisID == InputMap.ControlCameraUp or axisID == InputMap.ControlCameraDown then
		self.axisMap[axisID] = position
		local pressed = true
		if position > -self.axisMovedThres and position < self.axisMovedThres then
			pressed = false
		end
		--We need to normalize position between self.axisMovedThres and 1 which will make
		--the low end of self.axisMovedThres be 0, making it less sensitive at the low end
		local lerpedPos = (math.abs(position) - self.axisMovedThres) / (1 - self.axisMovedThres)
		if position < 0 then
			lerpedPos = -lerpedPos
		end
		if not pressed then
			lerpedPos = 0
		end
		self:ExecuteInputEvent(axisID, pressed, nil, lerpedPos, position)
	end

end


function SyncedKart:ExecuteInputEvent(keyID, pressed, extraData, lerpedAxisPercent, realAxisPercent)

	--Update the key map
	self:SetKeyMap(keyID, pressed, lerpedAxisPercent)

	if not self:GetEnableControls() then
		return
	end

	if keyID == InputMap.ControlAccel then
		if IsValid(self.physicalKart) then
			self.physicalKart:ControlAccel(pressed, math.abs(lerpedAxisPercent))

			if self:GetAllWheelsNotInContact() then
				self.controlAccelDown = pressed
			else
				self.controlAccelDown = false
			end
		end
		if IsClient() then
			self.kartManClient:ControlAccel(pressed)
		end
	elseif keyID == InputMap.ControlReverse then
		if IsValid(self.physicalKart) then
			self.physicalKart:ControlReverse(pressed, math.abs(lerpedAxisPercent))
			
			if self:GetAllWheelsNotInContact() then
				self.controlReverseDown = pressed
			else
				self.controlReverseDown = false
			end
		end
		if IsClient() then
			self.kartManClient:ControlReverse(pressed)
		end
	elseif keyID == InputMap.ControlRight then
		if IsValid(self.physicalKart) then
			self.physicalKart:ControlRight(pressed, math.abs(lerpedAxisPercent))
			
			if self:GetAllWheelsNotInContact() then
				self.controlRightDown = pressed
			else
				self.controlRightDown = false
			end
			
			if self:IsHopping() then
				self:HopSpin(false)
			end
		end
		if IsClient() then
			self.kartManClient:ControlRight(pressed)
		end
	elseif keyID == InputMap.ControlLeft then
		if IsValid(self.physicalKart) then
			self.physicalKart:ControlLeft(pressed, math.abs(lerpedAxisPercent))
			
			if self:GetAllWheelsNotInContact() then
				self.controlLeftDown = pressed
			else
				self.controlLeftDown = false
			end
			
			if self:IsHopping() then
				self:HopSpin(true)
			end
		end
		if IsClient() then
			self.kartManClient:ControlLeft(pressed)
		end
	elseif keyID == InputMap.ControlReset then
		if pressed then
			if IsValid(self.physicalKart) then
				self.physicalKart:ControlReset()
			end
			if IsClient() then
				self.kartManClient:ControlReset()
				GetPlayerManager():GetPlayerFromID(self:GetOwnerID()):ShowResettingGui(true)
			end
		end
	elseif keyID == InputMap.ControlMouseLook then
		self.jetpackActive = pressed
		if IsClient() then
			if not GetClientInputManager().autoMouseLook then
				if pressed then
					self:MouseLookStart()
				else
					self:MouseLookEnd()
				end
			else
				if pressed then
					self:MouseLookEnd()
					self.lastLookEnd = GetClientSystem():GetTime()
				end
			end
		end
	elseif keyID == InputMap.ControlCameraLeft or keyID == InputMap.ControlCameraRight then
		if realAxisPercent ~= 0 and (math.abs(realAxisPercent) > self.axisMovedCameraThres or math.abs(self.jsPosY) > self.axisMovedCameraThres) then
			self.jsPosX = realAxisPercent
			self:JSMoved(self.jsPosX, self.jsPosY)
		elseif realAxisPercent ~= 0 then
			self.jsPosX = realAxisPercent
		end
	elseif keyID == InputMap.ControlCameraUp or keyID == InputMap.ControlCameraDown then
		if realAxisPercent ~= 0 and (math.abs(realAxisPercent) > self.axisMovedCameraThres or math.abs(self.jsPosX) > self.axisMovedCameraThres) then
			self.jsPosY = realAxisPercent
			self:JSMoved(self.jsPosX, self.jsPosY)
		elseif realAxisPercent ~= 0 then
			self.jsPosY = realAxisPercent
		end
	elseif keyID == InputMap.ControlBoost then
		--BRIAN TODO: This is fucked up, why is BulletVehicle dealing with input?
		if IsValid(self.physicalKart) then
			self.physicalKart:ControlBoost(pressed)
		end
		if IsClient() then
			self.kartManClient:ControlBoost(pressed)
		end
	elseif keyID == InputMap.Hop then
		if IsValid(self.physicalKart) then
			self.currDrifting = pressed
		end
		-- if pressed then
		-- 	self:Hop()
		-- end
	elseif keyID == InputMap.UseItemUp then
		local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
		--print("WEAPON USED1")
		--print("player: "..tostring(player:GetName()))
		--print("weaponInQueue: "..tostring(player.weaponInQueue))
		if IsValid(player) and player.weaponInQueue then
			self.weaponsUsed = true
		   -- print("WEAPON USED2")
		end
		--The client needs to sync the shoot direction in some cases
		--Return any data you need in a Parameter
		if pressed then
			--Uncomment these lines and set the vector below
			retExtraData = Parameter()
			if self:IsMouseLooking() then
				retExtraData:SetWVector3Data(self:GetLookForward())
			else
				retExtraData:SetWVector3Data(self:GetOrientation():zAxis())
			end
			return retExtraData
		end
		
	elseif keyID == InputMap.UseItemDown then
		local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
		--print("WEAPON USED1")
		if IsValid(player) and player.weaponInQueue then
			self.weaponsUsed = true
			--print("WEAPON USED2")
		end
	end

end

function SyncedKart:Hop()

	if self:GetAllWheelsInContact() then
		local forwardQuat = self:GetOrientation()
		local upNormal = forwardQuat:yAxis()
		local upImpulse = upNormal * 1400
		self:ApplyWorldImpulse(upImpulse, WVector3())
		if self:GetKeyPressed(InputMap.ControlRight) then
			self:HopSpin(false)
		elseif self:GetKeyPressed(InputMap.ControlLeft) then
			self:HopSpin(true)
		end
		
		if IsClient() then
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Hopping_1.wav", self.graphicalKart:GetPosition(), 0.2, 10, true, SoundSystem.MEDIUM)
		end
	end

end


function SyncedKart:HopSpin(left)
	local forwardQuat = self:GetOrientation()
	local upNormal = forwardQuat:yAxis()
	local rotImpulse = upNormal * (KART_HOP_TURN_FORCE)
	if not left then
		rotImpulse = rotImpulse*-1
	end
	self.physicalKart:SetAngularVelocity(self.physicalKart:GetAngularVelocity()+rotImpulse)
	self.hopping = true
end


function SyncedKart:SetParameter(param)

end


function SyncedKart:EnumerateParameters(params)

end


syncedKartProcessEnabled = true
function SetSyncedKartProcessEnabled(setSyncedKartProcessEnabled)

	syncedKartProcessEnabled = setSyncedKartProcessEnabled

end


function SyncedKart:ProcessController(frameTime)

	if self:GetEnabled() then
		--TEST
		if IsClient() and GetClientInputManager().autoMouseLook and IsValid(self.lastMove) and GetClientSystem():GetTime() - self.lastMove > self.cameraMoveResetTime then
			self:MouseLookEnd()
		end

		if IsValid(self.kartManServer) then
			self.kartManServer:Process(frameTime)
		end

		-- Angular damping dependent on velocity
		self:SetAngularDamping(Clamp(BASE_ANGULAR_DAMPENING + self:GetControllerSpeedPercent()*(MAX_ANGULAR_DAMPENING-BASE_ANGULAR_DAMPENING), 0, MAX_ANGULAR_DAMPENING))

		-- Drifting..
		if self:GetEnableControls() and self.currDrifting and self:GetAllWheelsInContact() then
			if self.driftingDirection == 0 then
				if self:GetKeyPressed(InputMap.ControlRight) then
					self.driftingDirection = -1
				elseif self:GetKeyPressed(InputMap.ControlLeft) then
					self.driftingDirection = 1
				else
					self.driftingDirection = 0
					self.currDrifting = false
				end
				local forwardQuat = self:GetOrientation()
				local upNormal = forwardQuat:yAxis()
				local upImpulse = upNormal * 1000
				self:ApplyWorldImpulse(upImpulse, WVector3())
				self.driftTimer = WTimer()
				self.driftingTurbo = 0
			else
				local forwardQuat = self:GetOrientation()
				local upNormal = forwardQuat:yAxis()
				upNormal:Normalise()

				local kartVel = self:GetLinearVelocity()
				local speed = kartVel:Length()
				local speedClamp = Clamp((speed-5)/10, 0, 1)

				if IsServer() and speedClamp == 0 then
					self:Hop()
					self.driftingDirection = 0
					self.currDrifting = false
				else
					local rotImpulse = upNormal * (KART_DRIFTSTEER_AMOUNT * frameTime * self.driftingDirection) * speedClamp
					self.physicalKart:SetAngularVelocity((self.physicalKart:GetAngularVelocity()*KART_DRIFTSTEER_PERCENTAGE)+rotImpulse)
					self.driftingLerp = Lerp(frameTime*(speedClamp), self.driftingLerp, self.driftingDirection)

					if self.driftTimer then
						if self.driftTimer:GetTimeSeconds() > 2 and self.driftingTurbo == 0 then
							self.driftingTurbo = 1
						elseif self.driftTimer:GetTimeSeconds() > 4 and self.driftingTurbo == 1 then
							self.driftingTurbo = 2
						elseif self.driftTimer:GetTimeSeconds() > 6 and self.driftingTurbo == 2 then
							self.driftingTurbo = 3
						end
					end

					if IsClient() and speedClamp > 0.5 then
						if self.effectTimer == nil then
							self.effectTimer = WTimer()
						end

			   			if self.driftingTurbo == 1 then
		       				GetParticleSystem():AddEffect("ashton_turbo1", self.graphicalKart:GetWheelWorldPosition(WheelID.LEFT_BACK_WHEEL))
		       				GetParticleSystem():AddEffect("ashton_turbo1", self.graphicalKart:GetWheelWorldPosition(WheelID.RIGHT_BACK_WHEEL))
		       			elseif self.driftingTurbo == 2 then
		       				GetParticleSystem():AddEffect("ashton_turbo2", self.graphicalKart:GetWheelWorldPosition(WheelID.LEFT_BACK_WHEEL))
		       				GetParticleSystem():AddEffect("ashton_turbo2", self.graphicalKart:GetWheelWorldPosition(WheelID.RIGHT_BACK_WHEEL))
		       			elseif self.driftingTurbo == 3 then
		       				GetParticleSystem():AddEffect("ashton_turbo3", self.graphicalKart:GetWheelWorldPosition(WheelID.LEFT_BACK_WHEEL))
		       				GetParticleSystem():AddEffect("ashton_turbo3", self.graphicalKart:GetWheelWorldPosition(WheelID.RIGHT_BACK_WHEEL))
		       			end

						if self.effectTimer and self.effectTimer:GetTimeSeconds() > 0.2 then
			       			GetParticleSystem():AddEffect("ashton_drift", self.graphicalKart:GetWheelWorldPosition(WheelID.LEFT_BACK_WHEEL))
			       			GetParticleSystem():AddEffect("ashton_drift", self.graphicalKart:GetWheelWorldPosition(WheelID.RIGHT_BACK_WHEEL))

							GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Screech_1.wav", self.graphicalKart:GetPosition(), 0.2, 10, true, SoundSystem.MEDIUM)
	       					self.effectTimer:Reset()
	       					self.effectTimer = nil
	       				end
	       			end
				end
			end
		end

		if not self.currDrifting then
			if self.driftingTurbo ~= 0 then
				if self.driftingTurbo > 0 then
					local forwardQuat = self:GetOrientation()
					local forwardNormal = forwardQuat:zAxis()
					forwardNormal:Normalise()
					local kartVel = self.lastVelocity
					local speed = kartVel:Length()
					local forwardImpulse = forwardNormal * speed * (100*Clamp(self.driftingTurbo, 1.5, 3))
					self:ApplyWorldImpulse(forwardImpulse, WVector3())
				end

				self.driftingTurbo = 0
			end
			
			if self.driftTimer ~= nil then
	       		self.driftTimer:Reset()
	       		self.driftTimer = nil
	       	end

			if self.driftingDirection ~= 0 then
				self.driftingDirection = 0
			end
			
			if self.driftingLerp ~= 0 then
				self.driftingLerp = Lerp(frameTime* 10, self.driftingLerp, 0)
			end
		end

		-- Apply air steering
		if self:GetEnableControls() and self:GetAllWheelsNotInContact() and (self.controlAccelDown or self.controlReverseDown or self.controlRightDown or self.controlLeftDown) then
			local forwardQuat = self:GetOrientation()
			local forwardNormal = forwardQuat:zAxis()
			local upNormal = forwardQuat:yAxis()
			local rightNormal = forwardQuat:xAxis()
			forwardNormal:Normalise()
			rightNormal:Normalise()
			if self.controlRightDown then
				local rotImpulse = forwardNormal * (KART_AIRSTEER_AMOUNT * frameTime)		
				self.physicalKart:SetAngularVelocity(self.physicalKart:GetAngularVelocity()+rotImpulse)
			end
			if self.controlLeftDown then
				local rotImpulse = forwardNormal * (-KART_AIRSTEER_AMOUNT * frameTime)		
				self.physicalKart:SetAngularVelocity(self.physicalKart:GetAngularVelocity()+rotImpulse)
			end
			if self.controlAccelDown then
				local rotImpulse = rightNormal * (KART_AIRSTEER_AMOUNT * frameTime)		
				self.physicalKart:SetAngularVelocity(self.physicalKart:GetAngularVelocity()+rotImpulse)
			end
			if self.controlReverseDown then
				local rotImpulse = rightNormal * (-KART_AIRSTEER_AMOUNT * frameTime)		
				self.physicalKart:SetAngularVelocity(self.physicalKart:GetAngularVelocity()+rotImpulse)
			end
			
		end

		-- Help stick those landings
		if self:GetAllWheelsNotInContact() then
			self:SetSuspensionStiffness(self:GetSuspensionStiffness() + (AIR_SUSPENSION_STIFFNESS-self:GetSuspensionStiffness()) * frameTime)
			self:SetSuspensionDamping(self:GetSuspensionDamping() + (AIR_SUSPENSION_DAMPENING-self:GetSuspensionDamping()) * frameTime)
			self:SetSuspensionCompression(self:GetSuspensionCompression() + (AIR_SUSPENSION_COMPRESSION-self:GetSuspensionCompression()) * frameTime)
			self:SetSuspensionRestLength(self:GetSuspensionRestLength() + (AIR_SUSPENSION_REST_LENGTH-self:GetSuspensionRestLength()) * frameTime)
			self:SetMaxSuspensionTravelCm(self:GetMaxSuspensionTravelCm() + (AIR_SUSPENSION_MAX_TRAVEL-self:GetMaxSuspensionTravelCm()) * frameTime)
			--self:SetAngularDamping(self:GetAngularDamping() + (AIR_ANGULAR_DAMPENING-self:GetAngularDamping()) * frameTime)
			
			-- Track total air rotation
			--if true or self.isLocalPlayer then
				local up = WVector3(0,1,0)
				local right = WVector3(1,0,0)
				local forward = self:GetOrientation():zAxis()
				local kartSide = self:GetOrientation():xAxis()
				local newPitch = math.acos(up:DotProduct(forward))
				local newRoll = math.acos(right:DotProduct(kartSide))
				
				self.airPitch = self.airPitch + math.abs(newPitch - self.lastPitch)
				self.airRoll = self.airRoll + math.abs(newRoll - self.lastRoll)
				
				self.lastPitch = newPitch
				self.lastRoll = newRoll
			--end
			--print(self.airPitch)
			--self.airPitch = self.airPitch + self:GetOrientation():GetEulerX() - self.lastPitch
			--self.lastPitch = self:GetOrientation():GetEulerX()
		else
			self:SetSuspensionStiffness(self:GetSuspensionStiffness() + (GROUND_SUSPENSION_STIFFNESS-self:GetSuspensionStiffness()) * frameTime * 4)
			self:SetSuspensionDamping(self:GetSuspensionDamping() + (GROUND_SUSPENSION_DAMPENING-self:GetSuspensionDamping()) * frameTime * 4)
			self:SetSuspensionCompression(self:GetSuspensionCompression() + (GROUND_SUSPENSION_COMPRESSION-self:GetSuspensionCompression()) * frameTime * 4)
			self:SetSuspensionRestLength(self:GetSuspensionRestLength() + (GROUND_SUSPENSION_REST_LENGTH-self:GetSuspensionRestLength()) * frameTime * 4)
			self:SetMaxSuspensionTravelCm(self:GetMaxSuspensionTravelCm() + (GROUND_SUSPENSION_MAX_TRAVEL-self:GetMaxSuspensionTravelCm()) * frameTime * 4)
			--self:SetAngularDamping(self:GetAngularDamping() + (GROUND_ANGULAR_DAMPENING-self:GetAngularDamping()) * frameTime * 4)
		end
			-- detect in air
			if not self.inAir and self:GetAllWheelsNotInContact() then
				self.inAir = true
				self.lastVelocity = self:GetLinearVelocity()
				self.airClock:Reset()
				self.airPitch = 0
				self.airRoll = 0
				if true or self.isLocalPlayer then
					local up = WVector3(0,1,0)
					local right = WVector3(1,0,0)
					local forward = self:GetOrientation():zAxis()
					self.lastPitch = math.acos(up:DotProduct(forward))
					local kartSide = self:GetOrientation():xAxis()
					self.lastRoll = math.acos(right:DotProduct(kartSide))
				end
			end
		
			-- landing boost
			if self.inAir and not self:GetAllWheelsNotInContact() then
				self.inAir = false
				self:SetWheelFriction(self.wheelInitFriction)

				-- HOPPING SIDEWAYS BOOST (REMOVED)
				if self.hopping then
					local forwardQuat = self:GetOrientation()
					local forwardNormal = forwardQuat:zAxis()
					forwardNormal:Normalise()
					local kartVel = self.lastVelocity
					local speed = kartVel:Length()
					local forwardImpulse = forwardNormal * speed * 350
					self:ApplyWorldImpulse(kartVel*-400, WVector3())
					self:ApplyWorldImpulse(forwardImpulse, WVector3())
					local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
        			if IsValid(player.userData.place) and player.userData.place > 1 then
    					self:SetBoostPercent(self:GetBoostPercent()+0.05)
    				end
				end


				self.hopping = false
				self.controlAccelDown = false
				self.controlReverseDown = false
				self.controlRightDown = false
				self.controlLeftDown = false
			   
				if math.abs(self.airPitch) > 1.25*math.pi then
					if IsClient() then
						GetSoundSystem():EmitSound(ASSET_DIR .. "sound/stunt.wav", self:GetPosition(), 0.3, 1, false, SoundSystem.LOW)
						GetParticleSystem():AddEffect("targethit", self:GetPosition()+WVector3(0,-2,0))
						
						if self.isLocalPlayer then
							self.achievements:UpdateStat(self.achievements.STAT_FLIPS, 1)
							
							if math.abs(self.airPitch) > 3*1.25*math.pi then
								self.achievements:Unlock(self.achievements.AVMT_TRIPLE_FLIP)
							elseif math.abs(self.airPitch) > 2*1.25*math.pi then
								self.achievements:Unlock(self.achievements.AVMT_DOUBLE_FLIP)
							else
								self.achievements:Unlock(self.achievements.AVMT_FLIPPIN_AWESOME)
							end
						end
					else
						local newBoost = math.abs(self.airPitch)/(1.25*math.pi)*.25
						local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
        				if IsValid(player.userData.place) and player.userData.place > 1 then
							self:SetBoostPercent(self:GetBoostPercent() + newBoost)
						end
					end
					if IsServer() or self.isLocalPlayer then
						self.kartStuntParams:GetOrCreateParameter("angle"):SetFloatData(self.airPitch)
						self.kartStuntParams:GetOrCreateParameter("player"):SetIntData(self:GetOwnerID())
						self.kartStuntSignal:Emit(self.kartStuntParams)
					end
					print("FLIP!!!!!: "..self.airPitch)
				end
				self.airPitch = 0
			   
				if math.abs(self.airRoll) > 1.15*math.pi then
					if IsClient() then
						GetSoundSystem():EmitSound(ASSET_DIR .. "sound/stunt.wav", self:GetPosition(), 0.3, 1, false, SoundSystem.LOW)
						GetParticleSystem():AddEffect("targethit", self:GetPosition()+WVector3(0,-2,0))
						
						if self.isLocalPlayer then
							self.achievements:UpdateStat(self.achievements.STAT_BARREL_ROLLS, 1)
							self.achievements:Unlock(self.achievements.AVMT_BARREL_ROLL)
						end
					else
						local newBoost = math.abs(self.airRoll)/(1.15*math.pi)*.25
						local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
        				if IsValid(player.userData.place) and player.userData.place > 1 then
							self:SetBoostPercent(self:GetBoostPercent() + newBoost)
						end
					end
					if IsServer() or self.isLocalPlayer then
						self.kartStuntParams:GetOrCreateParameter("angle"):SetFloatData(self.airRoll)
						self.kartStuntParams:GetOrCreateParameter("player"):SetIntData(self:GetOwnerID())
						self.kartStuntSignal:Emit(self.kartStuntParams)
					end
					print("ROLL!!!!!: "..self.airRoll)
				end
				self.airRoll = 0
			   
				if IsClient() and IsValid(self.kartManClient) then
					self.airTime = self.airTime + self.airClock:GetTimeSeconds()
					--print("airTime: "..self.airTime)
					
					-- update airtime
					if self.isLocalPlayer and self.airTime >= 60 then
						self.achievements:UpdateStat(self.achievements.STAT_AIR_TIME, self.airTime/60)
						self.airTime = 0
					end
				
					local quat = self:GetOrientation()
					local kartForward = quat:zAxis()
					local kartVel = self.lastVelocity
					local downNormal = quat:yAxis()*-1
					downNormal = WVector3(0,-1,0)
					-- project the kart velocity onto the downNormal
					-- http://chortle.ccsu.edu/VectorLessons/vch11/vch11_6.html
					-- V is down normal
					-- W is kart velocity
					-- kv is projection of W onto V
					local V = downNormal
					local W = kartVel 
					local Wu = W/W:Length()
					local Vu = V/V:Length()
					local kv = W:Length()*Wu:DotProduct(Vu)*Vu
					local speed = kv:Length()
					
					if self.airClock:GetTimeSeconds() > 0.5 then
						self.kartManClient:LandEvent(speed)
					end
					
					-- Detect Paratrooper Achievement
					if self.isLocalPlayer and self.airClock:GetTimeSeconds() > 6 then
						self.achievements:Unlock(self.achievements.AVMT_PARATROOPER)
					end
					
					self.airClock:Reset()
					self.airClock:Stop()
					
					speed = kartVel:Length()
					--print(kartVel:Length())
					local kartVelNorm = kartVel
					kartVelNorm:Normalise()
					local dot = math.abs(kartForward:DotProduct(kartVelNorm))
					--print(dot)
					--print(kartVel:Length())
					if (not IsValid(self.currentSurfaceSound) or self.currentSurfaceSound:GetState() ~= SoundSource.PLAYING) and speed > 15 and dot < 0.6 then 
						self.kartManClient:doTireSqueal(speed)
					end
				end
			end
	
		if IsServer() then
			--Update the ScriptObject every process with no notifications
			self:SetPosition(self.physicalKart:GetPosition(), false)
			self:SetOrientation(self.physicalKart:GetOrientation(), false)
			self:SetLinearVelocity(self.physicalKart:GetLinearVelocity(), false)
		else
			if IsValid(self.physicalKart) then
			
				local currSpeed = 0
				local currSpeedPercent = 0
				if self:GetEnabled() and self:GetEnableControls() then
					currSpeed = self.physicalKart:GetCurrentSpeedKmHour()
					currSpeedPercent = self.physicalKart:GetSpeedPercent()
				end
				self.graphicalKart:SetCurrentSpeed(currSpeed)
				self.graphicalKart:SetSpeedPercent(currSpeedPercent)
				if not self.forceClientToServerSync then
					self.graphicalKart:SetPosition(self.physicalKart:GetPosition())
					self.graphicalKart:SetOrientation(self.physicalKart:GetOrientation())
					self:SetPosition(self.graphicalKart:GetPosition(), false)
					self:SetOrientation(self.graphicalKart:GetOrientation(), false)
				end
			end

			self.kartManClient:Process(frameTime)

			self:ProcessSurfaceSounds(frameTime)

			--Sync the client physical renderer to the client physical kart current position
			if IsValid(self.physicalKart) and IsValid(self.clientRenderer) then
				self.clientRenderer:SetPosition(self.physicalKart:GetPosition())
				self.clientRenderer:SetOrientation(self.physicalKart:GetOrientation())
			end

		end

		--if self.jetpackActive then
			--self.physicalKart:SetMaxSpeed(50)
		--else
			--self.physicalKart:SetMaxSpeed(120)
		--end

		if not self:GetEnableControls() then
			self:SetBoostEnabled(false)
		end
		self:ProcessBoost(frameTime)
		self:ProcessJetpack(frameTime)

		if IsClient() then
			self:ProcessCompositors(frameTime)
		end

	end

end


function SyncedKart:ProcessSurfaceSounds(frameTime)

	if IsValid(self.physicalKart) then
		local surfaceMat = self.physicalKart:GetCurrentMaterial()

		--Surface sound
		local surfaceSound = surfaceMat:GetParameters():GetParameter("SurfaceSound", false)
		if IsValid(surfaceSound) then
			local surfaceSoundName = surfaceSound:GetStringData()
			--Only bother playing it if it is not already playing
			if (self.currentSurfaceSoundName ~= surfaceSoundName) or
			   (self.currentSurfaceSound:GetState() ~= SoundSource.PLAYING) then
				self.currentSurfaceSoundName = surfaceSoundName
				self.currentSurfaceSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. self.currentSurfaceSoundName))
				self.currentSurfaceSound:Play()
			end
		else
			--No surface sound
			self.currentSurfaceSoundName = ""
			self.currentSurfaceSound:Stop()
		end
		self.currentSurfaceSound:SetVolume(math.abs(self:GetSpeedPercent()))
		self.currentSurfaceSound:SetPitch(0.5 + (1.35 * math.abs(self:GetSpeedPercent())))
		self.currentSurfaceSound:Process(frameTime)

		--BRIAN TODO: STILL IMPLEMENTED THROUGH THE SIGNAL, do it here instead?
		--Surface wheel particle
		--local surfaceSound = surfaceMat:GetParameters():GetParameter("WheelParticle", false)
	end

end

function SyncedKart:ProcessBoost(frameTime)

	--Only the server processes boost
	if IsServer() then
		if self:GetEnableControls() then
			if self:GetBoostPressed() then
				local currentBoostPercent = self:GetBoostPercent()
				--Only allow boost if they have KART_BOOST_PERCENT_BPS left
				if currentBoostPercent > KART_BOOST_PERCENT_BPS * frameTime then
					--Only boost if all wheels are touching
					if self:GetAllWheelsInContact() then
						--Tell the IController that boost is enabled
						self:SetBoostEnabled(true)

						--Apply the boost force
						local forwardQuat = self:GetOrientation()
						local forwardNormal = forwardQuat:zAxis()
						forwardNormal:Normalise()

						local boostImpulse = forwardNormal * (KART_BOOST_AMOUNT * frameTime)
						self:ApplyWorldImpulse(boostImpulse, WVector3())
						--Calculate the new boost amount
						
						currentBoostPercent = currentBoostPercent - (KART_BOOST_PERCENT_BPS * frameTime)
						self:SetBoostPercent(currentBoostPercent)
					end
				
				else
					--Tell the IController that boost is not enabled
					self:SetBoostEnabled(false)
				end
				
			else
				--Tell the IController that boost is not enabled
				self:SetBoostEnabled(false)
			end
		end
	else
		if self:GetBoostPressed() then
			self.boostBurned = self.boostBurned + KART_BOOST_PERCENT_BPS * frameTime
		end
	end

end


--Return how much of the total boost is used per second
function SyncedKart:GetBoostBPS()

	return KART_BOOST_PERCENT_BPS

end


function SyncedKart:ProcessJetpack(frameTime)

	if JETPACKS_ENABLED and self.jetpackActive then
		if IsValid(self.physicalKart) then
			local kartOrien = self:GetOrientation()
			local kartUpNormal = kartOrien:yAxis()
			kartUpNormal:Normalise()

			local jetpackImpulse = kartUpNormal * (KART_JETPACK_AMOUNT * frameTime)
			self:ApplyWorldImpulse(jetpackImpulse, WVector3())
		end
	end

end


function SyncedKart:ProcessCompositors(frameTime)

	if GetClientManager():GetScreenBlurAllowed() then
		--Screen blur effect only allowed if the camera is following this object
		if GetCameraManager():IsFollowObject(self) then
			local blurMax = 0.015
			--The boost effect should only display when boost is enabled and the SyncedKart is enabled
			local comEnabled = self:GetBoostEnabled() and self:GetEnabled()
			GetOGRESystem():SetCompositorEnabled("Radial Blur", comEnabled)
			--More blur while boosting
			if self:GetBoostEnabled() then
				blurMax = blurMax * 4
			end
			GetOGRESystem():SetCompositorSetting("Radial Blur", "sampleDist", self:GetSpeedPercent() * blurMax)
		end
	end

end


function SyncedKart:GetControllerUpNormal()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetUpNormal()
	end
	return WVector3(0, 1, 0)

end


function SyncedKart:GetControllerLinearVelocity()

	if IsServer() then
		if IsValid(self.physicalKart) then
			return self.physicalKart:GetLinearVelocity()
		end
		return WVector3()
	else
		return IScriptObject.GetLinearVelocity(self)
	end

end


function SyncedKart:GetControllerSpeedPercent()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetSpeedPercent()
	end
	return 0

end


function SyncedKart:GetHandbrakeEnabled()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetHandbrakeEnabled()
	end
	return false

end


function SyncedKart:SetWheelFriction(newFric)

	if IsServer() then
		--print("SetWheelFriction: "..newFric)
	
		--The wheel friction needs to be synchronized
		self.kartWFParam:SetFloatData(newFric)
		GetServerSystem():GetSendStateTable("Map"):SetState("KartWF" .. tostring(self:GetID()), self.kartWFParam)
	end
	if IsValid(self.physicalKart) then
		self.physicalKart:SetWheelFriction(newFric)
	else
		self.wheelInitFriction = newFric
	end

end


function SyncedKart:SetWheelFrictionSlot(newFricParams)

	local wheelFriction = newFricParams:GetParameter(0, true):GetFloatData()
	self:SetWheelFriction(wheelFriction)

end


function SyncedKart:GetWheelFriction()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetWheelFriction()
	end
	return 0

end

function SyncedKart:SetEnabledImp(setEnabled)

	if IsClient() then
		print("SyncedKart:SetEnabledImp:"..tostring(setEnabled))
	
		--If the controller is disabled, make it invisible
		self:SetVisible(setEnabled)
		
		--The controller should not make noise if it is disabled
		self:SetMuteSounds(not setEnabled)
		if IsValid(self.currentSurfaceSound) and not setEnabled then
			self.currentSurfaceSound:Stop()
		end

		if not setEnabled then
			self.graphicalKart:SetCurrentSpeed(0)
			self.graphicalKart:SetSpeedPercent(0)
		end

		--Manage the camera
		--[[ This used to always evaluate to nil, do we need this now?
		if self.isLocalPlayer then
			if setEnabled then
				self:ActivateCamController()
			else
				self:DeactivateCamController()
			end
		end
		--]]
	end

	if IsValid(self.physicalKart) then
		--Prevent/allow the physical kart from being checked for collision or simulated
		self.physicalKart:SetInWorld(setEnabled)
		self.physicalKart:SetAngularVelocity(WVector3(0,0,0))
	end

	self:SetBoostEnabled(false)

end


function SyncedKart:GetEnableControls()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetEnableControls()
	end
	return false

end


--BRIAN TODO: This is fucked up, why is BulletVehicle dealing with input?
function SyncedKart:GetBoostPressed()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetBoostPressed()
	end
	return 0

end


function SyncedKart:SetWheelFrictionTime(setLossTime, setGainTime)

	if IsValid(self.kartManServer) then
		self.kartManServer:SetWheelFrictionTime(setLossTime, setGainTime)
	end

end


function SyncedKart:SetSteeringMinClamp(setMin)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSteeringMinClamp(setMin)
	end

end


function SyncedKart:SetSteeringMaxClamp(setMax)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSteeringMaxClamp(setMax)
	end

end


function SyncedKart:SetMinEngineForce(setMin)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetMinEngineForce(setMin)
	end

end


function SyncedKart:SetMaxEngineForce(setMax)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetMaxEngineForce(setMax)
	end

end


function SyncedKart:SetEnableControlsImp(enable)

	if self:GetEnableControls() == enable then
		return
	end

	if IsValid(self.physicalKart) then
		--if not enable then
			-- STOP BOOSTING!!
			--self:KeyEvent(keyID, false)
		--end
		self.kartManServer:SetEnableControls(enable)
	end

	if enable then
		local mapCopy = { }
		for keyName, keyCode in pairs(InputMap) do
			mapCopy[keyCode] = { self.keyMap[keyCode][1], self.keyMap[keyCode][2] }
		end
		for keyName, keyCode in pairs(InputMap) do
			if IsValid(self.keyMap[keyCode]) then
				self:KeyEvent(keyCode, false, nil)
			end
			if IsValid(mapCopy[keyCode]) then
				self:KeyEvent(keyCode, mapCopy[keyCode][1], nil)
			end
		end
	end

end


function SyncedKart:GetAllWheelsInContact()

	if IsValid(self.physicalKart) then
		return self.kartManServer:GetAllWheelsInContact()
	end
	return false

end

function SyncedKart:GetAllWheelsNotInContact()

	if IsValid(self.physicalKart) then
		return self.kartManServer:GetAllWheelsNotInContact()
	end
	return false

end

function SyncedKart:GetTurnState()

	if IsValid(self.physicalKart) then
		return self.graphicalKart:GetTurnState()
	end
	return 0

end


function SyncedKart:GetCurrentSpeed()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetCurrentSpeedKmHour()
	end
	return 0

end


function SyncedKart:ApplyWorldImpulse(impulse, center)

	if IsValid(self.physicalKart) then
		return self.physicalKart:ApplyWorldImpulse(impulse, center)
	end

end


function SyncedKart:SetOutputDebugInfo(setOutput)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetOutputDebugInfo(setOutput)
	end

end


function SyncedKart:GetOutputDebugInfo()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetOutputDebugInfo()
	end
	return false

end


function SyncedKart:GetOwned()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetOwned()
	end
	return false

end


function SyncedKart:NotifyCustomized()

	if IsValid(self.graphicalKart) then
		self.graphicalKart:NotifyCustomized()
	end

end


function SyncedKart:NotifyOwnerIDChanged(oldID, newID)

	if IsClient() then
		print("NotifyOwnerIDChanged called for OwnerID " .. tostring(newID))
		--Init the receiving state table for the custom item settings for this kart
		self:InitCustomSettingsState()
		self.isLocalPlayer = GetPlayerManager():GetLocalPlayer():GetUniqueID() == newID
		self.kartManClient:InitSounds(self.isLocalPlayer)

	end

end


function SyncedKart:SetVisible(setVis)

	if IsValid(self.kartManClient) then
		self.kartManClient:SetVisible(setVis)
	end

end


function SyncedKart:GetVisible()

	if IsValid(self.kartManClient) then
		return self.kartManClient:GetVisible()
	end
	return false

end


function SyncedKart:GetEnableControls(enable)

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetEnableControls()
	end
	return false

end

function SyncedKart:SetRollInfluence(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetRollInfluence(value)
	end

end

function SyncedKart:GetRollInfluence()

	if IsValid(self.physicalKart) then
		self.physicalKart:GetRollInfluence()
	end
	return 0
end

function SyncedKart:SetSuspensionStiffness(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSuspensionStiffness(value)
	end

end

function SyncedKart:GetSuspensionStiffness()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetSuspensionStiffness()
	end
	return GROUND_SUSPENSION_STIFFNESS
end

function SyncedKart:SetSuspensionDamping(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSuspensionDamping(value)
	end

end

function SyncedKart:GetSuspensionDamping()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetSuspensionDamping()
	end
	return GROUND_SUSPENSION_DAMPENING
end

function SyncedKart:SetAngularDamping(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetAngularDamping(value)
	end

end

function SyncedKart:GetAngularDamping()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetAngularDamping()
	end
	return GROUND_ANGULAR_DAMPENING
end

function SyncedKart:SetSuspensionCompression(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSuspensionCompression(value)
	end

end

function SyncedKart:GetSuspensionCompression()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetSuspensionCompression()
	end
	return GROUND_SUSPENSION_COMPRESSION
end

function SyncedKart:SetSuspensionRestLength(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetSuspensionRestLength(value)
	end

end

function SyncedKart:GetSuspensionRestLength()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetSuspensionRestLength()
	end
	return GROUND_SUSPENSION_REST_LENGTH
end

function SyncedKart:SetMaxSuspensionTravelCm(value)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetMaxSuspensionTravelCm(value)
	end

end

function SyncedKart:GetMaxSuspensionTravelCm()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetMaxSuspensionTravelCm()
	end
	return GROUND_SUSPENSION_MAX_TRAVEL
end


function SyncedKart:SetWheelDriveMode(setWheelDriveMode)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetWheelDriveMode(setWheelDriveMode)
	end

end


function SyncedKart:GetWheelDriveMode()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetWheelDriveMode()
	end
	return BulletVehicle.BACK_WHEEL_DRIVE

end


function SyncedKart:SetWheelGripMode(setWheelGripMode)

	if IsValid(self.physicalKart) then
		self.physicalKart:SetWheelGripMode(setWheelGripMode)
	end

end


function SyncedKart:GetWheelGripMode()

	if IsValid(self.physicalKart) then
		return self.physicalKart:GetWheelGripMode()
	end
	return BulletVehicle.TWO_WHEEL_GRIP

end


function SyncedKart:SetKart(itemName)

	--BRIAN TODO: GetMeshLoaded code disabled until it can be properly tested
	local itemLoaded = false
	if itemLoaded or GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			print("$$$$$$ Loading " .. itemName .. " now")
			self.graphicalKart:SetKart(itemName)
		end
	else
		print("$$$$$$ Can't load " .. itemName .. " yet")
		self.deferredLoad[self.SetKart] = itemName
	end

end

function SyncedKart:GetKart()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetKart()
	else
		return nil
	end

end

function SyncedKart:SetKartSlot(itemParams)

	local itemName = itemParams:GetParameter(0, true):GetStringData()
	print(self:GetName() .. " = " .. itemName .. ", OwnerID = " .. tostring(self:GetOwnerID()))
	self:SetKart(itemName)

end


function SyncedKart:SetCharacter(itemName)

	print("Setting character in SyncedKart:SetCharacter(" .. itemName .. ")")
	local itemLoaded = false
	if itemLoaded or GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			print("Calling self.graphicalKart:SetCharacter()")
			self.graphicalKart:SetCharacter(itemName)
		end
	else
		self.deferredLoad[self.SetCharacter] = itemName
	end

end

function SyncedKart:GetCharacter()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetCharacter()
	else
		return nil
	end

end

function SyncedKart:SetCharacterSlot(itemParams)

	local itemName = itemParams:GetParameter(0, true):GetStringData()
	self:SetCharacter(itemName)

end


function SyncedKart:SetWheel(itemName)

	local itemLoaded = false
	if itemLoaded or GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetWheel(itemName)
		end
	else
		self.deferredLoad[self.SetWheel] = itemName
	end

end


function SyncedKart:SetWheelSlot(itemParams)

	local itemName = itemParams:GetParameter(0, true):GetStringData()
	self:SetWheel(itemName)

end


function SyncedKart:SetHat(itemName)

	local itemLoaded = false
	if itemLoaded or GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetHat(itemName)
		end
	else
		self.deferredLoad[self.SetHat] = itemName
	end

end

function SyncedKart:GetHat()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetHat()
	else
		return nil
	end

end

function SyncedKart:SetHatSlot(itemParams)

	local itemName = itemParams:GetParameter(0, true):GetStringData()
	self:SetHat(itemName)

end


function SyncedKart:SetAccessory(itemName)

	local itemLoaded = false
	if itemLoaded or GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetAccessory(itemName)
		end
	else
		self.deferredLoad[self.SetAccessory] = itemName
	end

end

function SyncedKart:GetAccessory()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetAccessory()
	else
		return nil
	end

end

function SyncedKart:SetAccessorySlot(itemParams)

	local itemName = itemParams:GetParameter(0, true):GetStringData()
	self:SetAccessory(itemName)

end

function SyncedKart:SetKartColor(colorName, red, green, blue, alpha)

	--Bail if we've already painted the kart a team color
	local player = GetPlayerManager():GetPlayerFromID(self:GetOwnerID())
	--print("SyncedKart:SetKartColor: player = "..tostring(player))
	--[[if IsValid(player) and IsValid(player.userData.teamID) then
		if player.userData.teamID == "Red" then
			red = 1
			green = 0
			blue = 0
		elseif player.userData.teamID == "Blue" then
			red = 65/255
			green = 150/255
			blue = 1
		end
		--self.graphicalKart:SetKartColor(colorName, red, green, blue, alpha)
		--return
	end

	if IsValid(player) then
		player.userData.painted = false
	end
	--]]
	if GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetKartColor(colorName, red, green, blue, alpha)
		end
	else
		self.deferredColorLoad[self.SetKartColor] = { Name = colorName, Red = red, Green = green, Blue = blue, Alpha = alpha }
	end
	
	

end


function SyncedKart:SetKartColor1Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetKartColor("Color" .. tostring(1), CustomItemParseColor(colorStr, CustomItem.RED),
											  CustomItemParseColor(colorStr, CustomItem.GREEN),
											  CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetKartColor2Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetKartColor("Color" .. tostring(2), CustomItemParseColor(colorStr, CustomItem.RED),
											  CustomItemParseColor(colorStr, CustomItem.GREEN),
											  CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetKartColor3Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetKartColor("Color" .. tostring(3), CustomItemParseColor(colorStr, CustomItem.RED),
											  CustomItemParseColor(colorStr, CustomItem.GREEN),
											  CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetKartColor4Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetKartColor("Color" .. tostring(4), CustomItemParseColor(colorStr, CustomItem.RED),
											  CustomItemParseColor(colorStr, CustomItem.GREEN),
											  CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetCharacterColor(colorName, red, green, blue, alpha)

	if GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetCharacterColor(colorName, red, green, blue, alpha)
		end
	else
		self.deferredColorLoad[self.SetCharacterColor] = { Name = colorName, Red = red, Green = green, Blue = blue, Alpha = alpha }
	end

end


function SyncedKart:SetCharacterColor1Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetCharacterColor("Color" .. tostring(1), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetCharacterColor2Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetCharacterColor("Color" .. tostring(2), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetCharacterColor3Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetCharacterColor("Color" .. tostring(3), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetCharacterColor4Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetCharacterColor("Color" .. tostring(4), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetWheelColor(colorName, red, green, blue, alpha)

	if GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetWheelColor(colorName, red, green, blue, alpha)
		end
	else
		self.deferredColorLoad[self.SetWheelColor] = { Name = colorName, Red = red, Green = green, Blue = blue, Alpha = alpha }
	end

end


function SyncedKart:SetWheelColor1Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetWheelColor("Color" .. tostring(1), CustomItemParseColor(colorStr, CustomItem.RED),
											   CustomItemParseColor(colorStr, CustomItem.GREEN),
											   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetWheelColor2Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetWheelColor("Color" .. tostring(2), CustomItemParseColor(colorStr, CustomItem.RED),
											   CustomItemParseColor(colorStr, CustomItem.GREEN),
											   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetWheelColor3Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetWheelColor("Color" .. tostring(3), CustomItemParseColor(colorStr, CustomItem.RED),
											   CustomItemParseColor(colorStr, CustomItem.GREEN),
											   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetWheelColor4Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetWheelColor("Color" .. tostring(4), CustomItemParseColor(colorStr, CustomItem.RED),
											   CustomItemParseColor(colorStr, CustomItem.GREEN),
											   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetHatColor(colorName, red, green, blue, alpha)

	if GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetHatColor(colorName, red, green, blue, alpha)
		end
	else
		self.deferredColorLoad[self.SetHatColor] = { Name = colorName, Red = red, Green = green, Blue = blue, Alpha = alpha }
	end

end


function SyncedKart:SetHatColor1Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetHatColor("Color" .. tostring(1), CustomItemParseColor(colorStr, CustomItem.RED),
											 CustomItemParseColor(colorStr, CustomItem.GREEN),
											 CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetHatColor2Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetHatColor("Color" .. tostring(2), CustomItemParseColor(colorStr, CustomItem.RED),
											 CustomItemParseColor(colorStr, CustomItem.GREEN),
											 CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetHatColor3Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetHatColor("Color" .. tostring(3), CustomItemParseColor(colorStr, CustomItem.RED),
											 CustomItemParseColor(colorStr, CustomItem.GREEN),
											 CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetHatColor4Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetHatColor("Color" .. tostring(4), CustomItemParseColor(colorStr, CustomItem.RED),
											 CustomItemParseColor(colorStr, CustomItem.GREEN),
											 CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetAccessoryColor(colorName, red, green, blue, alpha)

	if GetClientManager():GetLoadingAllowed() then
		if IsValid(self.graphicalKart) then
			self.graphicalKart:SetAccessoryColor(colorName, red, green, blue, alpha)
		end
	else
		self.deferredColorLoad[self.SetAccessoryColor] = { Name = colorName, Red = red, Green = green, Blue = blue, Alpha = alpha }
	end

end


function SyncedKart:SetAccessoryColor1Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetAccessoryColor("Color" .. tostring(1), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetAccessoryColor2Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetAccessoryColor("Color" .. tostring(2), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetAccessoryColor3Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetAccessoryColor("Color" .. tostring(3), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end


function SyncedKart:SetAccessoryColor4Slot(colorParams)

	local colorStr = colorParams:GetParameter(0, true):GetStringData()
	self:SetAccessoryColor("Color" .. tostring(4), CustomItemParseColor(colorStr, CustomItem.RED),
												   CustomItemParseColor(colorStr, CustomItem.GREEN),
												   CustomItemParseColor(colorStr, CustomItem.BLUE), 1)

end

function SyncedKart:LoadingAllowedSlot(params)

	local loadingAllowed = params:GetParameter("Allowed", true):GetBoolData()
	if loadingAllowed then
		--Only ignore ping if there is something to load
		if #self.deferredLoad > 0 then
			GetClientSystem():SetIgnorePing(true)
		end
		for setterFunc, value in pairs(self.deferredLoad) do
			setterFunc(self, value)
		end
		self.deferredLoad = { }
		--Now that the items are loaded, set their color
		for setterFunc, value in pairs(self.deferredColorLoad) do
			setterFunc(self, value.Name, value.Red, value.Green, value.Blue, value.Alpha)
		end
		self.deferredColorLoad = { }
		GetClientSystem():SetIgnorePing(false)
	end

end


function SyncedKart:SetCastShadows(setCast)

	if IsValid(self.graphicalKart) then
		self.graphicalKart:SetCastShadows(setCast)
	end

end


function SyncedKart:GetCastShadows()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetCastShadows()
	end
	return false

end


function SyncedKart:SetWipeoutEnabled(setEnabled)

	if IsValid(self.graphicalKart) then
		self.graphicalKart:SetWipeoutEnabled(setEnabled)
	end

end


function SyncedKart:SetOverlay(setOverlay, onTopOfOverlays)

	if IsValid(self.graphicalKart) then
		self.graphicalKart:SetOverlay(setOverlay, onTopOfOverlays)
	end

end


function SyncedKart:SetMuteSounds(setMute)

	if IsValid(self.kartManClient) then
		self.kartManClient:SetMuteSounds(setMute)
	end

end


function SyncedKart:GetMuteSounds()

	if IsValid(self.kartManClient) then
		return self.kartManClient:GetMuteSounds()
	end
	return true

end


function SyncedKart:SetBoostEnabledImp(setEnabled)

	if IsValid(self.kartManClient) then
		self.kartManClient:SetBoostEnabled(setEnabled)
	end
	if IsValid(self.physicalKart) then
		self.physicalKart:SetBoosting(setEnabled)
	end
	self:SetWipeoutEnabled(setEnabled)

	if IsClient() and not setEnabled then
		GetOGRESystem():SetCompositorEnabled("Radial Blur", false)
	end

end


function SyncedKart:GetBoundingBox()

	if IsClient() then
		if IsValid(self.graphicalKart) then
			return self.graphicalKart:GetBoundingBox()
		end
	elseif IsServer() and IsValid(self.physicalKart) then
		self.physicalKart:GetBoundingBox()
	end
	return WAxisAlignedBox()

end


function SyncedKart:GetSceneNode()

	if IsValid(self.graphicalKart) then
		return self.graphicalKart:GetSceneNode()
	end

end


function SyncedKart:NotifyDebugDrawEnabled(enabled)

	if IsValid(self.clientRenderer) then
		--self.clientRenderer:SetVisible(enabled)
	end
	if IsValid(self.serverRenderer) then
		--self.serverRenderer:SetVisible(enabled)
	end

end

--SYNCEDKART CLASS END
