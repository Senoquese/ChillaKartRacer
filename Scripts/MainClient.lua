jit.on()

--NOTE: no objects should be initialized before main() runs
local clientManager = nil
local playerCam = nil
local mainClientSystem = nil
local mainMyGUISystem = nil

function RunClockTest()

    --WClock test
    local testClock = WTimer()
    while testClock:GetTimeSeconds() < 5 do
        print("loop1 - clock1: " .. tostring(testClock:GetTimeSeconds()))
    end
    local stopTime = testClock:Stop()
    print("Stop time after loop 1: " .. tostring(stopTime))
    local testClock2 = WTimer()
    while testClock2:GetTimeSeconds() < 5 do
        print("loop2 - clock1: " .. tostring(testClock:GetTimeSeconds()) .. " clock2: " .. tostring(testClock2:GetTimeSeconds()))
    end
    testClock:Start()
    while testClock:GetTimeSeconds() < 10 do
        print("loop 3 - clock1: " .. tostring(testClock:GetTimeSeconds()))
    end
    testClock:Reset()
    while testClock:GetTimeSeconds() < 5 do
        print("loop 4 (after Reset) - clock1: " .. tostring(testClock:GetTimeSeconds()))
    end

end


function main(assetDir)

	print("Started Lua main()")

	--SetCurrentHostType("ENet")
	SetCurrentHostType("Steam")

    --BRIAN TODO: Test code forcing a lower process priority and disabling process priority adjusting
    --RaiseProcessPriority()
    LowerProcessPriority()
    SetEnableProcessPriorityAdjusting(false)

	ASSET_DIR = assetDir

	--Load the module manager to load and manage all other modules
	package.path = ASSET_DIR .. "Scripts/?.lua"
	require("ModuleManager")

	--The Lua profiler, profiler.dll must be in working directory
	--See: http://www.keplerproject.org/luaprofiler/
	--require("profiler")

	--Load the persistent wrappers
	UseModule("PersistentSignalWrapper", "Scripts/")
	UseModule("PersistentSlotWrapper", "Scripts/")

	--Load the utilities
	UseModule("LuaUtils", "Scripts/")

	--The shortcuts to longer commands
	UseModule("ShortCuts", "Scripts/")

	--InputMap is a global table to hold the input values
	UseModule("InputMap", "Scripts/")

	--Local Client Manager
	UseModule("ClientManager", "Scripts/")

	clientManager = ClientManager()
		
	--Increment the launch count
    local launchCountParam = GetSettingTable():GetSetting("LaunchCount", "Shared", false)
    local launchCount = 1
	if IsValid(launchCountParam) and launchCountParam:GetFloatData() >= 0 then
		launchCount = launchCountParam:GetFloatData()
		launchCount = launchCount + 1
		launchCountParam:SetFloatData(launchCount)
	else
		launchCountParam = Parameter("LaunchCount", 1)
		GetSettingTable():AddSetting(launchCountParam, "Shared")
	end
	clientManager.launchCount = launchCount

    --Change this to simulate low sound source conditions
    --GetSoundSystem():SetMaxNumberSoundSources(16)

	--Need this factory template for the ClientWorld object factory
	UseModule("SyncedObjectFactoryTemplate", "Scripts/SyncedObjects/")
	print("Starting InitSystem() call in Lua main")
	InitSystems()
	print("Finished InitSystem() call in Lua main")

	--Load the console commands
	UseModule("consoleCommands", "Scripts/")
	print("Starting GetClientManager():Init() call in Lua main")
	GetClientManager():Init()
	print("Finished GetClientManager():Init() call in Lua main")

    --Load any custom scripts
    UseModule("PluginLoader", "Scripts/")
    pluginLoader = PluginLoader()
    
	InitClientWorld()

	--Init a few graphics settings
	--Shadow stuff
	SetAmbientLight(1.0, 1.0, 1.0)
	SetShadowColor(0.5, 0.5, 0.5, 1)

	--Preload any assets that we don't want to load during gameplay
	Preload()

	print("Finished Lua main()")

    print("Client Version: " .. GetVersionString())

    --RunClockTest()

end


--InitCamera should only be called from this file
local function InitCamera()

	--Instantiate Camera
	playerCam = WCamera()
	playerCam:Init(Parameters())
    
	playerCam:SetFOV(60)
	playerCam:SetBaseFOV(60)

end


function InitSystems()

	local logSystem = GetLogSystem()
	local ogreSystem = GetOGRESystem()
	local scriptSystem = GetScriptSystem()

	local bulletPhysicsSystem = GetBulletPhysicsSystem()
	--Add the main physics world to the system
	GetBulletPhysicsSystem():CreateWorld("Main", Tags("TimeAdapted", "DebugDraw", "RayCast"))
	bulletPhysicsSystem:SetDebugDrawer(ToIBulletDebugDrawer(BulletDebugDrawer()))

	InitCamera()

	local inputSystem = GetInputSystem()

	local myGUISystem = GetMyGUISystem()
	InitGUI(myGUISystem)

	local settingTable = GetSettingTable()
	--Add the ASSET_DIR setting to the setting table
	settingTable:AddSetting(Parameter("ASSET_DIR", ASSET_DIR), "System")

	local customItemSystem = GetCustomItemSystem()
	local clientSystem = GetClientSystem()
	local particleSystem = GetParticleSystem()
	local soundSystem = GetSoundSystem()
	local steamClientSystem = GetSteamClientSystem()
	steamClientSystem:SetClientSystem(clientSystem)
	steamClientSystem:SetEnabled(true)
	--local webServerSystem = GetWebServerSystem()
	local clientWorld = GetClientWorld()
	clientWorld:SetClientSystem(clientSystem)
	clientWorld:SetPhysicsSystem(bulletPhysicsSystem)
	--local clientBulletDebugDrawer = GetClientBulletDebugDrawer()
	--clientBulletDebugDrawer:SetClientSystem(clientSystem)

	--We must init the Network at this point
	clientManager:InitNetwork()

	--BRIAN TODO: The name should be set before the AddSystem call below
	logSystem:SetName("LogSystem")
	ogreSystem:SetName("OGRESystem")
	inputSystem:SetName("InputSystem")
	myGUISystem:SetName("MyGUISystem")
	scriptSystem:SetName("ScriptSystem")
	bulletPhysicsSystem:SetName("BulletPhysicsSystem")
	--The time in the ITimed object is used to mark the current time in PhysicsCommands
	bulletPhysicsSystem:SetTimedForCommands(clientSystem)

	--objectSystem:SetName("ObjectSystem")
	settingTable:SetName("SettingTable")
	clientSystem:SetName("ClientSystem")
	customItemSystem:SetName("CustomItemSystem")
	particleSystem:SetName("ParticleSystem")
	soundSystem:SetName("SoundSystem")
	steamClientSystem:SetName("SteamClientSystem")
	--webServerSystem:SetName("WebServerSystem")
	clientWorld:SetName("ClientWorld")
	--clientBulletDebugDrawer:SetName("ClientBulletDebugDrawer")

	--On the client the ClientSystem needs to run first to receive updates to render
	GetSystemManager():AddSystem(clientSystem:ToISystem())
	GetSystemManager():AddSystem(logSystem:ToISystem())
	GetSystemManager():AddSystem(scriptSystem:ToISystem())
	GetSystemManager():AddSystem(inputSystem:ToISystem())
	GetSystemManager():AddSystem(myGUISystem:ToISystem())
	GetSystemManager():AddSystem(bulletPhysicsSystem:ToISystem())
	--GetSystemManager():AddSystem(objectSystem:ToISystem())
	GetSystemManager():AddSystem(settingTable:ToISystem())
	GetSystemManager():AddSystem(customItemSystem:ToISystem())
	GetSystemManager():AddSystem(particleSystem:ToISystem())
	GetSystemManager():AddSystem(soundSystem:ToISystem())
	GetSystemManager():AddSystem(steamClientSystem:ToISystem())
	--GetSystemManager():AddSystem(webServerSystem:ToISystem())
	GetSystemManager():AddSystem(clientWorld:ToISystem())
	--GetSystemManager():AddSystem(clientBulletDebugDrawer:ToISystem())
	--OGRESystem is added last because it should render last
	GetSystemManager():AddSystem(ogreSystem:ToISystem())

	GetSystemManager():Init()

	--When the SteamClientSystem uninits we need to uninit the ClientSystem as it may be using Steam APIs internally
	GetClientSystem():GetSlot("UnInitNetHost", true):Connect(GetSteamClientSystem():GetSignal("UnInitBegin", true))

	GetSystemManager():GetSignal("UpdateFramerate", true):Connect(clientSystem:GetSlot("UpdateFramerate", true))

end


function InitClientWorld(clientWorld)

	local clientWorld = GetClientWorld()

	clientWorld:SetCoreObjectFactory(CreateSyncedObjectFactory())

	AssignInputMapping(clientWorld)

end


function InitGUI(guiSystem)

    if IsValid(guiSystem:GetSlot("KeyPressed", false)) then
        guiSystem:GetSlot("KeyPressed", true):Connect(GetInputSystem():GetSignal("KeyPressed", true))
    end
    if IsValid(guiSystem:GetSlot("KeyReleased", false)) then
        guiSystem:GetSlot("KeyReleased", true):Connect(GetInputSystem():GetSignal("KeyReleased", true))
    end

	guiSystem:GetSlot("MouseMoved", true):Connect(GetInputSystem():GetSignal("MouseMoved", true))
	guiSystem:GetSlot("MousePressed", true):Connect(GetInputSystem():GetSignal("MousePressed", true))
	guiSystem:GetSlot("MouseReleased", true):Connect(GetInputSystem():GetSignal("MouseReleased", true))

end


function Preload()

	LoadOgreResourceGroup("Weapons", ASSET_DIR .. "items", "FileSystem", true)

	local preloader = OGREModel()
	local loadParams = Parameters()
	local meshNames = { "heart_indicator.mesh", "icecube.mesh", "itembox.mesh", "luvbot.mesh", "pow.mesh", "repulsor.mesh", "seamine.mesh", "twister.mesh" }
	for i, v in ipairs(meshNames) do
		loadParams:GetOrCreateParameter("RenderMeshName"):SetStringData(v)
		preloader:Init(loadParams)
		preloader:UnInit()
	end

end


function GetClientManager()

	return clientManager

end


function GetCamera()

	return playerCam

end


--Toggle the mouse visibility
function TM()

end


--Toggle the network info GUI
function TNI()

	print(tostring(GetClientSystem():GetServerPing() * 1000))

end


function IsClient()

	return true

end


function IsServer()

	return false

end


function GetNetworkSystem()

	return GetClientSystem()

end


--There can be multiple ClientSystems but there is one main one always
function GetClientSystem()

	if not IsValid(mainClientSystem) then
		mainClientSystem = CreateClientSystem()
	end
	return mainClientSystem

end


function GetMyGUISystem()

	if not IsValid(mainMyGUISystem) then
		mainMyGUISystem = CreateMyGUISystem()
	end
	return mainMyGUISystem

end


function GetNetworkedWorld()

	return GetClientWorld()

end