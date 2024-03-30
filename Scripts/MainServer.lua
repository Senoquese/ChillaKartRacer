jit.on()

--NOTE: no objects should be initialized before main() runs
serverManager = nil

function main(assetDir)

	--SetCurrentHostType("ENet")
	SetCurrentHostType("Steam")

    --BRIAN TODO: Test code forcing a lower process priority and disabling process priority adjusting
    --RaiseProcessPriority()
    -- LowerProcessPriority()
    -- SetEnableProcessPriorityAdjusting(false)

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

	--Need this factory template for the ClientWorld object factory
	UseModule("SyncedObjectFactoryTemplate", "Scripts/SyncedObjects/")
	--Needed to parse ports out of server settings file
	UseModule("ServerSettingsManager", "Scripts/")
	InitSystems()

	--Load the kart management code
	UseModule("ServerManager", ASSET_DIR .. "Scripts/")

	serverManager = ServerManager()
	InitServerSystem(GetServerSystem())

	InitServerWorld()

	print("Server Version: " .. GetVersionString())

    --Load any custom scripts
    UseModule("PluginLoader", "Scripts/")
    pluginLoader = PluginLoader()
    
	--Now it is safe to load a map
	if IsValid(serverManager.firstLoad) then
		serverManager:LoadMapNow(serverManager.currentMap)
	end

end


function InitSystems()

	local logSystem = GetLogSystem()

	local scriptSystem = GetScriptSystem()

	local bulletPhysicsSystem = GetBulletPhysicsSystem()
	--Add the main physics world to the system
	GetBulletPhysicsSystem():CreateWorld("Main", Tags("RayCast"))

	--local objectSystem = GetObjectSystem()
	--objectSystem:SetFactory(ServerObjectFactory())

	local settingTable = GetSettingTable()
	settingTable:SerializeFromXML("Shared", false, false)
	settingTable:SerializeFromXML("System", false, false)
	--Add the ASSET_DIR setting to the setting table
	settingTable:AddSetting(Parameter("ASSET_DIR", ASSET_DIR), "System")

	local steamServerSystem = GetSteamServerSystem()
	local serverSystem = GetServerSystem()
	local serverSettings = ServerSettingsManager()
    --Write it now just to make sure the file exists for the admin to modify later
    serverSettings:WriteFile()
	serverSystem:SetConnectionPort(serverSettings.gamePort)

	local botSystem = GetBotSystem()
	local serverInputSystem = GetServerInputSystem()
	steamServerSystem:SetServerSystem(serverSystem)
	steamServerSystem:SetGameName("zerogear")
	--BRIAN TODO: This version should come from code, the steam server should know this automatically even
	steamServerSystem:SetServerVersion(GetVersionString())
	steamServerSystem:SetAuthPort(serverSettings.authPort)
	steamServerSystem:SetMasterPort(serverSettings.steamPort)
	steamServerSystem:SetEnabled(true)
	local serverWorld = GetServerWorld()
	serverWorld:SetServerSystem(serverSystem)
	--local serverBulletDebugDrawer = GetServerBulletDebugDrawer()
	--serverBulletDebugDrawer:SetServerSystem(serverSystem)
	--bulletPhysicsSystem:SetDebugDrawer(ToIBulletDebugDrawer(GetServerBulletDebugDrawer()))
	--bulletPhysicsSystem:SetDebugDraw(false)
	--0.05 = 20 times a second
	--0.1 = 10 times a second
	--serverBulletDebugDrawer:SetUpdateTimer(0.05)

	logSystem:SetName("LogSystem")
	bulletPhysicsSystem:SetName("BulletPhysicsSystem")
	--The time in the ITimed object is used to mark the current time in PhysicsCommands
	bulletPhysicsSystem:SetTimedForCommands(serverSystem)

	--objectSystem:SetName("ObjectSystem")
	settingTable:SetName("SettingTable")
	serverSystem:SetName("ServerSystem")
	botSystem:SetName("BotSystem")
	serverInputSystem:SetName("ServerInputSystem")
	steamServerSystem:SetName("SteamServerSystem")
	serverWorld:SetName("ServerWorld")
	--serverBulletDebugDrawer:SetName("ServerBulletDebugDrawer")

	GetSystemManager():AddSystem(scriptSystem:ToISystem())
	GetSystemManager():AddSystem(logSystem:ToISystem())
	GetSystemManager():AddSystem(bulletPhysicsSystem:ToISystem())
	--GetSystemManager():AddSystem(objectSystem:ToISystem())
	GetSystemManager():AddSystem(settingTable:ToISystem())
	GetSystemManager():AddSystem(serverInputSystem:ToISystem())
	GetSystemManager():AddSystem(steamServerSystem:ToISystem())
	GetSystemManager():AddSystem(serverWorld:ToISystem())
	--GetSystemManager():AddSystem(serverBulletDebugDrawer:ToISystem())
	GetSystemManager():AddSystem(botSystem:ToISystem())
	--On the server, the ServerSystem should update last to send out data based on this frames update
	GetSystemManager():AddSystem(serverSystem:ToISystem())

	GetSystemManager():Init()

	GetSystemManager():GetSignal("UpdateFramerate", true):Connect(serverSystem:GetSlot("UpdateFramerate", true))

	local serverName = steamServerSystem:GetLocalPlayerName()
	if string.len(serverName) > 0 then
		serverName = serverName .. "'s Server"
		serverSystem:SetServerName(serverName)
	end

	--Note: You should override the final server name here
	--   -- <--- that is a comment, remove it below to set your server's name
	--serverSystem:SetServerName("Your Server Name")

end


function InitServerSystem(serverSystem)

    local settings = GetServerManager().serverSettings
	serverSystem:SetMaxNumberOfClients(tonumber(settings.maxPlayers))
	serverSystem:SetServerName(settings.serverName)

	--When the SteamServerSystem uninits we need to uninit the ServerSystem as it may be using Steam APIs internally
	GetServerSystem():GetSlot("UnInitNetHost", true):Connect(GetSteamServerSystem():GetSignal("UnInitBegin", true))

end


function InitServerWorld()

	local serverWorld = GetServerWorld()

	serverWorld:SetCoreObjectFactory(CreateSyncedObjectFactory())

	serverWorld:SetSyncRates(1 / 20, 1 / 120)

	AssignInputMapping(serverWorld)

end


function PrintNetworkInfo()

	local netInfo = GetServerSystem():GetConnectionInfo()
	local i = 0
	local numParams = netInfo:GetNumberOfParameters()
	while i < numParams do
		local currentParam = netInfo:GetParameterAtIndex(i, true)
		GetConsole():Print(currentParam:GetName() .. ": " .. currentParam:GetStringData())
		i = i + 1
	end

end


function GetServerManager()

	return serverManager

end


function IsClient()

	return false

end


function IsServer()

	return true

end


function GetNetworkSystem()

	return GetServerSystem()

end


function GetNetworkedWorld()

	return GetServerWorld()

end