--[[

SHORTCUTS IN THIS FILE:

--Load a GUI layout file for testing, visuals only
LGUI(layoutName)

--Set allow buffered sends
BUFFSEND(bool)

--Sends a command to the server to adjust the gravity
SetGrav(float)

--Toggle Spike Detection, disabled by default,
--first param is optional, controls how much time is needed to go over/below
--the average time for a spike to be detected, 0.010 by default (10 MS)
TSD(float)

--Toggle Net Graph Prints, #GRAPH statements will be printed out if this is enabeld
TNGP()

--Toggle Force Allow Input, when enabled, this allows client game input even
--when the console or a GUI has input
TFAI()

--Use Convex Shape for bullet vehicle
UCS(bool)

--Change Physics TimeStep, 1.0 / 150.0 by default
TS(float)

--Returns a number >= 0 and < 1
SRANDOM()

--Bot System AI Enabled, true by default
AI(bool)

--Network Thread Enabled, true by default
NTE(bool)

--Network Sending Enabled, true by default
--Set to false to prevent the network from sending data (some low level data will still be sent)
NSE(bool)

--Network set Force Unreliable, false by default
--When true, forces all data to be sent unreliable
NFU(bool)

--Send a command to the server, the server password must already be set with GetClientSystem():SetServerAdminPassword(string)
CMD(string)

--Toggle Network Artificial Lag, pass the min and max number of seconds to lag by, call again to disable the lag
TAL(float, float)

--Set Network Receive Queue Timer, this is how much time passes before processing more queued reliable packets
NRQT(float)

--Toggle Network Artificial Jitter in the connection, float between 0 and 1 to specify how much
--traffic should be dropped to cause jitter
--BRIAN TODO: Not implemented yet
TAJ(float)

--Network Thread Sleep in MS, 10 by default
NTS(int)

--Print Network Queued Events Stats
PNQES()

--Set Time Sync Timer for the ClintSystem, 5 by default, how often the client syncs time with the server
STST(float)

--Networked World set Sync Rates, min and max, 1 / 5 and 1 / 30 by default, how often the server syncs the world state with the clients
NWSR(float, float)

--(Force) Lua GC Step, true by default
LGC(bool)

--Connect the client to the passed in server address with the passed in name
--Leave both params blank to connect locally, leave the name param blank for a default name
C(string, string)

--Client World set Adapt time Damper, 0.50 by default, the damper prevents time adaption from being too reactive
CWAD(float)

--Client World use average high ping time, will smooth out jitters at the cost of more input lag
HighPing()

--Disable Sync on the (Client/Server) World, false by default
DS(bool)

--Toggles timeshifting on the ServerWorld
Timeshift(bool)

--Toggles Object Speed modifier in the ServerWorld update rates
ObjSpeedMod(bool)

--Time Thread Enabled, true by default
TTE(bool

--Toggle Split Impulse Enabled
TSIE()

--Set Num Solver Iterations
SNSI(int)

--Set Enable Sleep
SES(bool)

--Set Enable Switch To Thread
ESTT(bool)

--Physics Collision Firing Enabled, true by default
--If set to false, nothing will be notified of collisions
PCFE(bool)

--Physics Object State Update Enabled, true by default
--If object state updating is not enabled, objects will not be notified of their new state every tick
PSUE(bool)

--Physics sim enabled, true by default
PE(bool)

--Global time Modifier, 1.0 by default, change to a smaller value to slow time or a larger value to speed up time
GM(float)

--Physics sim Modifier, 1.0 by default, change to a smaller value to slow time or a larger value to speed up time
PM(float)

--Ogre Profiler Enabled, false by default, pass true to display the Ogre profiler overlay,
--the second param is the rate at which it should update
--1 = every frame, 10 = every 10 frames
OPE(bool, int)

--Ogre VSync Enabled, chosen by the user by default, only works in fullscreen
--(Doesn't seem to work for some reason)
OVSE(bool)

--Set Fog, pass in red, green, and blue float values, pass in the start point and end point as float
SF(float, float, float, float, float)

--Enable Visualization on the client, defaults to false
EV(bool)

--Use Boost Signals, defaults to false
UBS(bool)

--Allow Wheel Casts in BulletVehicles, defaults to true
AWC(bool)

--Toggle Wheel Drive Mode for BulletVehicles
TWDM()

--Toggle Wheel Grip Mode for BulletVehicles
TWGM()

--Enable EmitTransform signal in WTransform, used for testing only, defaults to true
EET(bool)

--SyncedKart Process Enabled, enables or disables processing for SyncedKart, defaults to true
SKPE(bool)

--Enabled or disable the blur screen effect
BLUR(bool)

--Spawn Soccer Ball on the server, all params are optional
SSB(posX, posY, posZ, scale)

--Spawn Multiple Soccer Balls
SSSB(howMany, startX, startY, startZ)

--Give the player a weapon, pass in the name of the player and the name of the weapon type
Pass in a blank name "" to give all players the weapon
GW(string, string)

--Give the player a LUVBot, pass in the name of the player
GLB(string)

--Give the player an Ice Cube, pass in the name of the player
GIC(string)

--Give the player a Sea Mine, pass in the name of the player
GSM(string)

--Give the player a Puncher, pass in the name of the player
GP(string)

--Give the player a Twister, pass in the name of the player
GT(string)

--Cycle Cameras, pass in true to cycle, false to go back to the current camera
CC(bool)

--Buffer Physics Commands, true by default, set to false to force commands to
--process immediately
BPC(bool)

--Print Network Info
--BRIAN TODO: Does this still work? Is it useful?
PNI()

--Toggle Kart Debug Info
--BRIAN TODO: Does this still work? Is it useful?
TDI()

--Raise Process Priority
RPP()

--Lower Process Priority
LPP()

--Load "ChampionCircuit"
LM()

--Load "ChuteShoot"
LJ()

--Load "SpaghettiWest"
LW()

--Load "PunchBowl"
LPB()

--Load "ChillMountain"
LC()

--Load "TagArena"
LTT()

--Load "DirtCircuit"
LD()

--Load "Fallout"
LF()

--Load "RinkyDink"
LR()

--Load "SpaceJump"
LSJ()

--Load "DustBunny"
LDB()

--Load "BotArena"
LBA()

--Load "KickIt"
LKI()

--Go to the next map in the map cycle
NEXTMAP()

--Kick the passed in player
KICK(string)

--Kick all players
KICKALL()

--Respawn the passed in player
RESPAWN(string)

--Give all players full boost
BOOSTIT()

--Restart the race, only works in race mode
RESTARTRACE()

--Print the server FPS
FPS()

--Suspension Stiffness
SS(float)

--Suspension Damping
SD(float)

--Suspension Compression
SC(float)

--Suspension Rest Length
SRL(float)

--Set Max Suspension Travel Cm
SMST(float)

--Set Controller Mass
SCM(float)

--Set Controller Linear Damping
SCLD(float)

--Set Controller Angular Damping
SCAD(float)

--Set Wheel Friction Regain Time, how long until the vehicle wheels completely regain traction
--with the road after losing contact, parameters are setLossTime and setGainTime
SWFRT(float, float)

--Set Steering Clamp, pass in the min and max clamp values as floats
SSC(float, float)

--Set Engine Force, pass in the min and max force values as floats
SEF(float, float)

--]]

function PUSH_PROFILE(name)

	--Easily stop profiling code by commenting this out
	--PushProfile(name)

end


function POP_PROFILE(name)

	--Easily stop profiling code by commenting this out
	--PopProfile(name)

end


--Output Profiler Info
local profilerIter = nil
if profilerIter == nil and IsValid(GetSystemManager().GetRootProfileNode) then
	profilerIter = GetSystemManager():GetRootProfileNode()
end
if profilerIter == nil and IsValid(GetSuperProfilerIterator) then
    profilerIter = GetSuperProfilerIterator()
end
local printProfilerInfoSlot = WSlot("PrintProfilerInfo", "PrintShinyProfilerInfo")
local printProfilerInfo = false
function OPI()

	if not printProfilerInfo then
		if IsClient() then
			printProfilerInfoSlot:Connect(GetOGRESystem():GetSignal("ProcessBegin", true))
		else
			printProfilerInfoSlot:Connect(GetServerSystem():GetSignal("ProcessEnd", true))
		end
	else
		printProfilerInfoSlot:DisconnectAll()
	end
	printProfilerInfo = not printProfilerInfo

end


--EnterChild, enter the child profile with the passed in index
function EC(childIndex)

	profilerIter:EnterChild(childIndex)

end


--EnterParent, enter the parent profile
function EP()

	profilerIter:EnterParent()

end


function PrintProfilerInfo()

	GetConsole():Clear()

	profilerIter:SetFirst()
	--local parentTotalTime = profilerIter:GetCurrentParentTotalTime()
	local parentTotalTime = profilerIter:GetCurrentParentMeasureTime()
	local parentTotalCalls = profilerIter:GetCurrentParentTotalCalls()
	print("Profiling: " .. profilerIter:GetCurrentParentName() .. " - Total Runtime: " .. string.format("%.3f", parentTotalTime))
	local index = 0
	while true do
		if IsValid(profilerIter:GetCurrentName()) then
			--local childTime = profilerIter:GetCurrentTotalTime()
			local childTime = profilerIter:GetCurrentMeasureTime()
			local childCalls = profilerIter:GetCurrentTotalCalls()
			--The parent calls will be 0 if it is root
			if parentTotalCalls == 0 then
				parentTotalCalls = childCalls
			end
			print(" " .. tostring(index) .. " - " .. profilerIter:GetCurrentName() .. " T: " .. string.format("%3.3f", childTime) ..
				  ", " .. string.format("%3.3f%%", (childTime / parentTotalTime) * 100) .. " C: " .. tostring(childCalls) ..
				  ", " .. string.format("%3.3f%%", (childCalls / parentTotalCalls) * 100) ..
				  ", Spike: " .. string.format("%3.3f", (profilerIter:GetCurrentLastHighestTimeWhileMeasuring())))
		end
		if profilerIter:IsEnd() then
			break
		end
		profilerIter:SetNext()
		index = index + 1
	end

end


function PrintShinyProfilerInfo()

	GetConsole():Clear()

	--Parent
	print(profilerIter:GetName() .. " Time: " .. tostring(profilerIter:GetAverageTime()))

	--Children
	local numChildren = profilerIter:NumChildren()
	local currChildIndex = 0
	while currChildIndex < numChildren do
		profilerIter:EnterChild(currChildIndex)
		print("  " .. tostring(currChildIndex) .. ": " .. profilerIter:GetName() .. " Time: " .. tostring(profilerIter:GetAverageTime()))
		currChildIndex = currChildIndex + 1
		profilerIter:EnterParent()
	end

end


--PhysicsOutputDebugInfo, toggles on and off
function PODI()

	GetBulletPhysicsSystem():SetOutputDebugInfo(not GetBulletPhysicsSystem():GetOutputDebugInfo())

end


--PhysicsOutputProfilerInfo, toggles on and off
function POPI()

	GetBulletPhysicsSystem():SetOutputProfilerInfo(not GetBulletPhysicsSystem():GetOutputProfilerInfo())

end


--PhysicsEnterChild, enter the child profile with the passed in index
function PEC(childIndex)

	GetBulletPhysicsSystem():EnterChildProfile(childIndex)

end


--PhysicsEnterParent, enter the parent profile
function PEP()

	GetBulletPhysicsSystem():EnterParentProfile()

end


--PhysicsDumpProfilerStats, output the current stats to a file
function PDPS()

	--First get the log we want to output the stats to
	local statLog = GetLogSystem():GetOrCreateLog("PhysicsProfilerStats.txt")
	GetBulletPhysicsSystem():DumpProfilerStats(statLog)
	print("Physics stats dumped to " .. statLog:GetName())

end


local testGUIs = {}
function LGUI(layoutName)

    table.insert(testGUIs, GetMyGUISystem():LoadLayout(layoutName, GenerateName()))

end

function g()
    LGUI("mainmenu.layout")
end


function TNGP()

	local eventType = NetworkSystem.PROCESS_EVENT
    local typeEnabled = GetNetworkSystem():GetGraphPrintEnabled(eventType)
	GetNetworkSystem():SetGraphPrintEnabled(eventType, not typeEnabled)
	GetNetworkSystem():SetGraphPrintEnabled(NetworkSystem.RECEIVE_EVENT, not typeEnabled)

end


function BUFFSEND(allow)

    SetAllowBufferedSends(allow)

end


function SetGrav(newGrav)

    CMD("GetBulletPhysicsSystem():SetGravity(Tags(Tags.ANY), WVector3(0, " .. tostring(newGrav) .. ", 0))")
    print("Gravity is now " .. tostring(newGrav))

end


function TSD(spikeTime)

    if IsValid(spikeTime) then
        GetSystemManager():SetSpikeDetectionTime(spikeTime)
    end
    GetSystemManager():SetSpikeDetectionEnabled(not GetSystemManager():GetSpikeDetectionEnabled())

end


function TFAI()

    GetClientInputManager():SetForceAllowInput(not GetClientInputManager():GetForceAllowInput())
    print("Allow Input Forced: " .. tostring(GetClientInputManager():GetForceAllowInput()))

end


function UCS(setUse, ballSize)

    SetUseConvexShapeForBulletVehicle(setUse)
    SetBallSizeForBulletVehicle(ballSize)

end


function TS(stepSize)

	GetBulletPhysicsSystem():SetInternalTimeStep("Main", stepSize)

end


function SRANDOM()

    local srandom = 1
    while srandom == 1 do
        srandom = Random()
    end
    return srandom

end


function AI(enabled)

	GetBotSystem():SetAIEnabled(enabled)

end


function NTE(enabled)

	if IsServer() then
		GetServerSystem():SetNetworkThreadEnabled(enabled)
	else
		GetClientSystem():SetNetworkThreadEnabled(enabled)
	end

end


function NSE(enabled)

	if IsServer() then
		GetServerSystem():SetSendingEnabled(enabled)
	else
		GetClientSystem():SetSendingEnabled(enabled)
	end

end


function NFU(enabled)

	GetNetworkSystem():SetForceUnreliable(enabled)

end


function CMD(serverCommand)

	GetClientSystem():SendServerCommand(serverCommand)

end


function TAL(minLagTime, maxLagTime)

	print("Artificial Lag enabled: " .. tostring(not GetNetworkSystem():GetArtificialLagEnabled()))
	GetNetworkSystem():SetArtificialLagEnabled(not GetNetworkSystem():GetArtificialLagEnabled(), minLagTime, maxLagTime)

end


function NRQT(setTimer)

    GetNetworkSystem():SetReceiveQueueTimer(setTimer)

end


function NTS(ms)

	if IsServer() then
		GetServerSystem():SetThreadSleepMS(ms)
	else
		GetClientSystem():SetThreadSleepMS(ms)
	end

end


function PNQES()

	print("Num Events: " .. tostring(GetNetworkSystem():GetNumberQueuedEvents()))
	print("Event Data Size: " .. tostring(GetNetworkSystem():GetDataSizeQueuedEvents()))
	
end


function STST(ms)
	GetClientSystem():SetTimeSyncTimer(ms)
end


function NWSR()
	-- GetClientSystem():SetSyncRates(0.02, 0.01)
end


function LGC(forced)

	GetScriptSystem():SetForceGCStep(forced)

end


function C(serverAddress, clientName)

	if not IsValid(serverAddress) then
		serverAddress = "localhost"
	end
	if not IsValid(clientName) then
		clientName = "Lazy" .. tostring(math.random(0, 100))
	end

	GetClientSystem():SetClientName(clientName)
	GetClientSystem():RequestConnect(serverAddress, SavedItemsSerializer():GetSettingsAsParameters())

end


function CWAD(setDamper)

	if IsClient() then
		GetClientWorld():SetAdaptTimeDamper(setDamper)
	end

end


function HighPing()

	local useHigh = GetClientWorld():GetUseHighestPingTime()
	GetClientWorld():SetUseHighestPingTime(not useHigh)
	print("ClientWorld use high average ping time: " .. tostring(not useHigh))

end


function DS(disabled)

	GetNetworkedWorld():SetDisableSync(disabled)

end


function Timeshift(enabled)

	if IsValid(enabled) then
		GetServerWorld():SetTimeShiftEnabled(enabled)
	else
		GetServerWorld():SetTimeShiftEnabled(not GetServerWorld():GetTimeShiftEnabled())
	end
	print("ServerWorld Timeshift enabled: " .. tostring(GetServerWorld():GetTimeShiftEnabled()))

end


function ObjSpeedMod(enabled)

    if IsValid(enabled) then
        GetServerWorld():SetFactorObjSpeedUpdateRateEnabled(enabled)
    else
        GetServerWorld():SetFactorObjSpeedUpdateRateEnabled(not GetServerWorld():GetFactorObjSpeedUpdateRateEnabled())
    end
    print("ServerWorld Obj Speed Mod enabled: " .. tostring(GetServerWorld():GetFactorObjSpeedUpdateRateEnabled()))

end


function TTE(enabled)

    if enabled then
        StartClockThread()
    else
        StopClockThread()
    end

end


function TSIE()

    GetBulletPhysicsSystem():SetSplitImpulseEnabled("Main", not GetBulletPhysicsSystem():GetSplitImpulseEnabled("Main"))
    print("Split Impulse Enabled: " .. tostring(GetBulletPhysicsSystem():GetSplitImpulseEnabled("Main")))

end


function SNSI(numIterations)

    GetBulletPhysicsSystem():SetNumSolverIterations("Main", numIterations)

end


function SES(enabled)

    SetEnableSleep(enabled)

end


function ESTT(enabled)

	SetEnableSwitchToThread(enabled)

end


function PCFE(enabled)

	GetBulletPhysicsSystem():SetCollisionFiringEnabled(enabled)

end


function PSUE(enabled)

	GetBulletPhysicsSystem():SetObjectStateUpdateEnabled(enabled)

end


function PE(enabled)

	GetBulletPhysicsSystem():SetSimulationEnabled(enabled)

end


function GM(modifier)

	SetTimeModifier(modifier)

end


function PM(modifier)

	GetBulletPhysicsSystem():SetSimulationModifier(modifier)

end


function OPE(enabled, rate)

	if rate == nil then
		rate = 10
	end

	GetOGRESystem():SetProfilerEnabled(enabled, rate)

end


function OVSE(enabled)

	GetOGRESystem():SetVSyncEnabled(enabled)

end


function SF(red, green, blue, linStart, linEnd)

	GetOGRESystem():SetFog(OGRESystem.FOG_LINEAR, WColorValue(red, green, blue, 0), 0, linStart, linEnd)

end


function EV(enable)

	GetGameMode():SetVisualizationEnabled(enable)

end


function UBS(enabled)

	SetUseBoostSignals(enabled)

end


function AWC(enabled)

	SetAllowWheelCasts(enabled)

end


function TWDM()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		local wheelDriveMode = player:GetController():GetWheelDriveMode()
		if wheelDriveMode == BulletVehicle.FRONT_WHEEL_DRIVE then
			wheelDriveMode = BulletVehicle.BACK_WHEEL_DRIVE
			print(player:GetName() .. "'s drive mode is BACK_WHEEL_DRIVE")
		elseif wheelDriveMode == BulletVehicle.BACK_WHEEL_DRIVE then
			wheelDriveMode = BulletVehicle.ALL_WHEEL_DRIVE
			print(player:GetName() .. "'s drive mode is ALL_WHEEL_DRIVE")
		elseif wheelDriveMode == BulletVehicle.ALL_WHEEL_DRIVE then
			wheelDriveMode = BulletVehicle.FRONT_WHEEL_DRIVE
			print(player:GetName() .. "'s drive mode is FRONT_WHEEL_DRIVE")
		end
		player:GetController():SetWheelDriveMode(wheelDriveMode)
		i = i + 1
	end

end


function TWGM()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		local wheelGripMode = player:GetController():GetWheelGripMode()
		if wheelGripMode == BulletVehicle.NO_WHEEL_GRIP then
			wheelGripMode = BulletVehicle.TWO_WHEEL_GRIP
			print(player:GetName() .. "'s grip mode is TWO_WHEEL_GRIP")
		elseif wheelGripMode == BulletVehicle.TWO_WHEEL_GRIP then
			wheelGripMode = BulletVehicle.FOUR_WHEEL_GRIP
			print(player:GetName() .. "'s grip mode is FOUR_WHEEL_GRIP")
		elseif wheelGripMode == BulletVehicle.FOUR_WHEEL_GRIP then
			wheelGripMode = BulletVehicle.NO_WHEEL_GRIP
			print(player:GetName() .. "'s grip mode is NO_WHEEL_GRIP")
		end
		player:GetController():SetWheelGripMode(wheelGripMode)
		i = i + 1
	end

end


function EET(enabled)

	SetEnableEmitTransform(enabled)

end


function SKPE(enabled)

	SetSyncedKartProcessEnabled(enabled)

end


function BLUR(enabled)

	GetOGRESystem():SetCompositorEnabled("Radial Blur", enabled)

end


function BLURS(value)

	--sampleStrength
	GetOGRESystem():SetCompositorSetting("Radial Blur", "sampleDist", value)

end


function TILE(enabled)

	GetOGRESystem():SetCompositorEnabled("Tiling", enabled)

end


function TILES(value)

	GetOGRESystem():SetCompositorSetting("Tiling", "NumTiles", value)

end


function SSB(mass, posX, posY, posZ, scale)

	local initParams = Parameters()
	if not IsValid(posX) then
		posX = 0
	end
	if not IsValid(posY) then
		posY = 0
	end
	if not IsValid(posZ) then
		posZ = 0
	end
	initParams:AddParameter(Parameter("Position", WVector3(posX, posY, posZ)))
	if not IsValid(scale) then
		scale = 1.5
	end
	initParams:AddParameter(Parameter("Scale", WVector3(scale, scale, scale)))
	if not IsValid(mass) then
		mass = 50
	end
	initParams:AddParameter(Parameter("Mass", mass))
	initParams:AddParameter(Parameter("Restitution", 0.7))
	initParams:AddParameter(Parameter("AngularDamping", 0.25))
	--initParams:AddParameter(Parameter("Deactivates", true))
	--initParams:AddParameter(Parameter("Static", false))
	initParams:AddParameter(Parameter("CastShadows", true))
	initParams:AddParameter(Parameter("ReceiveShadows", false))
	initParams:AddParameter(Parameter("RenderMeshName", "soccer_ball.mesh"))
	GetNetworkedWorld():CreateObject("SoccerBall" .. tostring(GenerateID()), "SyncedBall", true, initParams)

end


function SSSB(howMany, startX, startY, startZ)

	local i = 0
	while i < howMany do
		SSB(50, startX, startY, startZ)
		startY = startY + 4
		i = i + 1
	end

end


function GW(playerName, weaponTypeName)

    if playerName == nil then
        local i = 1
        while i <= GetPlayerManager():GetNumberOfPlayers() do
            GW(GetPlayerManager():GetPlayer(i):GetName(), weaponTypeName)
            i = i + 1
        end
    else
        GetWeaponManagerServer():GivePlayerWeapon(GetPlayerManager():GetPlayer(playerName), weaponTypeName)
    end

end


function GLB(playerName)

    GW(playerName, "SyncedLUVBot")

end


function GIC(playerName)

    GW(playerName, "SyncedIceCube")

end


function GSM(playerName)

    GW(playerName, "SyncedSeaMine")

end


function GP(playerName)

    GW(playerName, "SyncedPuncher")

end


function GT(playerName)

	GW(playerName, "SyncedTwister")

end


function GR(playerName)

	GW(playerName, "SyncedRepulsor")

end

function GS(playerName)

	GW(playerName, "SyncedSpring")

end


function CC(enable)

    GetCameraManager():CycleCamera(enable)

end


function BPC(enable)

	SetBufferPhysicsCommands(enable)

end


function SetGameMode(newMode)

	if IsServer() then
		return GetServerManager():SetGameMode(newMode)
	else
		return GetClientManager():SetGameMode(newMode)
	end

end


function GetGameMode()

	if IsServer() then
		return GetServerManager():GetGameMode()
	else
		return GetClientManager():GetGameMode()
	end

end


function PNI()

	PrintNetworkInfo()

end


function TDI()

	GetServerManager():ToggleKartDebugInfo()

end


function RPP()

    RaiseProcessPriority()

end


function LPP()

    LowerProcessPriority()

end


function LoadMap(mapName)

    serverManager:LoadMap(mapName)

end


--Valve style commands
function changelevel(mapName)

    LoadMap(mapName)

end


function LM()

	serverManager:LoadMap("ChampionCircuit")

end


function LJ()

	serverManager:LoadMap("ChuteShoot")

end


function LW()

	serverManager:LoadMap("SpaghettiWest")

end


function LPB()

	serverManager:LoadMap("PunchBowl")

end


function LC()

	serverManager:LoadMap("ChillMountain")

end


function LTT()

	serverManager:LoadMap("TagArena")

end



function LD()

	serverManager:LoadMap("DirtCircuit")

end


function LP()

	serverManager:LoadMap("Pachinko")

end


function LF()

	serverManager:LoadMap("Fallout")

end


function LR()

	serverManager:LoadMap("RinkyDink")

end

function LS()

	serverManager:LoadMap("Skate")

end


function LSJ()

	serverManager:LoadMap("SpaceJump")

end


function LDB()

	serverManager:LoadMap("DustBunny")

end


function LBA()

	serverManager:LoadMap("BotArena")

end


function LKI()

	serverManager:LoadMap("KickIt")

end


function NEXTMAP()

	GetServerManager():LoadNextMapInRotation()

end


function KICK(peerName, reasonStr)

    if not IsValid(reasonStr) then
        reasonStr = "Kicked from the server"
    end
    local foundPeer = GetServerSystem():GetPeer(peerName)
    if not IsValid(foundPeer) then
        return false
    end
	GetServerSystem():DisconnectPeer(foundPeer, reasonStr)
    return true

end


function KICKID(peerID, reasonStr)

    if not IsValid(reasonStr) then
        reasonStr = "Kicked from the server"
    end
    local foundPeer = GetServerSystem():GetPeerFromID(peerID)
    if not IsValid(foundPeer) then
        return false
    end
	GetServerSystem():DisconnectPeer(foundPeer, reasonStr)
    return true

end


function KICKALL(reasonStr)

    if not IsValid(reasonStr) then
        reasonStr = "Kicked from the server"
    end
	GetServerSystem():DisconnectAllPeers(reasonStr)

end


function SENDMESSAGE(peerID, message)

    local foundPeer = GetServerSystem():GetPeerFromID(peerID)
    if IsValid(foundPeer) then
        GetServerSystem():SendServerMessage(foundPeer, message, false)
    end

end


function RESPAWN(clientName)

	GetServerManager():RespawnPlayer(clientName)

end


--Give all players full boost
function BOOSTIT()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:GetController():SetBoostPercent(1)
		i = i + 1
	end

end


--Only works in race mode
function RESTARTRACE()

	GetServerManager():GetGameMode():SetGameState(GetServerManager():GetGameMode().raceStates.GAME_STATE_WAIT_FOR_PLAYERS)

end


function FPS()

	print(tostring(GetSystemManager():GetFramerate()))

end


function SS(value)
	
	if(value) == nil then
		print(tostring(GROUND_SUSPENSION_STIFFNESS))
		return
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
--		player:GetController():SetSuspensionStiffness(value)
		GROUND_SUSPENSION_STIFFNESS=(value)
		i = i + 1
	end

end

function SSS(value)
    GetMenuManager():GetRoster():SetScoreSorting(value)
end

function SD(value)

	if(value) == nil then
		print(tostring(GROUND_SUSPENSION_DAMPENING))
		return
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
--		player:GetController():SetSuspensionDamping(value)
		GROUND_SUSPENSION_DAMPENING=(value)
		i = i + 1
	end

end


function SC(value)

	if(value) == nil then
		print(tostring(GROUND_SUSPENSION_COMPRESSION))
		return
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
--		player:GetController():SetSuspensionCompression(value)
		GROUND_SUSPENSION_COMPRESSION=(value)
		i = i + 1
	end

end


function SRL(value)

	if(value) == nil then
		print(tostring(GROUND_SUSPENSION_REST_LENGTH))
		return
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
--		player:GetController():SetSuspensionRestLength(value)
		GROUND_SUSPENSION_REST_LENGTH=(value)
		i = i + 1
	end

end


function SMST(value)

	if(value) == nil then
		print(tostring(GROUND_SUSPENSION_MAX_TRAVEL))
		return
	end
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
--		player:GetController():SetMaxSuspensionTravelCm(value)
		GROUND_SUSPENSION_MAX_TRAVEL=(value)
		i = i + 1
	end

end


function SCM(value)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		if(value) == nil then
			print(tostring(player:GetController():GetMass()))
			return
		else
			player:GetController():SetMass(value) 
		end
		i = i + 1
	end

end


function SCLD(value)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:GetController():SetLinearDamping(value)
		i = i + 1
	end

end


function SCAD(value)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:GetController():SetAngularDamping(value)
		i = i + 1
	end

end


function SWFRT(setLossTime, setGainTime)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player:GetController():SetWheelFrictionTime(setLossTime, setGainTime)
		i = i + 1
	end

end


function SSC(setMin, setMax)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		if IsValid(setMin) then
			player:GetController():SetSteeringMinClamp(setMin)
		end
		if IsValid(setMax) then
			player:GetController():SetSteeringMaxClamp(setMax)
		end
		i = i + 1
	end

end


function SEF(setMin, setMax)

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		if IsValid(setMin) then
			player:GetController():SetMinEngineForce(setMin)
		end
		if IsValid(setMax) then
			player:GetController():SetMaxEngineForce(setMax)
		end
		i = i + 1
	end

end


function IsComputerOn()

	return true

end


function RunBenchmarks()

	local benchmarkClock = WTimer()

	print("fannkuch(10) = " .. tostring(fannkuch(10)))

	print("Benchmarks Total Runtime: " .. tostring(benchmarkClock:GetTimeSeconds()))

end


function fannkuch(n)
  local p, q, s, odd, check, maxflips = {}, {}, {}, true, 0, 0
  for i=1,n do p[i] = i; q[i] = i; s[i] = i end
  repeat
    -- Print max. 30 permutations.
    if check < 30 then
      if not p[n] then return maxflips end	-- Catch n = 0, 1, 2.
      print(unpack(p))
      check = check + 1
    end
    -- Copy and flip.
    local q1 = p[1]				-- Cache 1st element.
    if p[n] ~= n and q1 ~= 1 then		-- Avoid useless work.
      for i=2,n do q[i] = p[i] end		-- Work on a copy.
      for flips=1,1000000 do			-- Flip ...
	local qq = q[q1]
	if qq == 1 then				-- ... until 1st element is 1.
	  if flips > maxflips then maxflips = flips end -- New maximum?
	  break
	end
	q[q1] = q1
	if q1 >= 4 then
	  local i, j = 2, q1 - 1
	  repeat q[i], q[j] = q[j], q[i]; i = i + 1; j = j - 1; until i >= j
	end
	q1 = qq
      end
    end
    -- Permute.
    if odd then
      p[2], p[1] = p[1], p[2]; odd = false	-- Rotate 1<-2.
    else
      p[2], p[3] = p[3], p[2]; odd = true	-- Rotate 1<-2 and 1<-2<-3.
      for i=3,n do
	local sx = s[i]
	if sx ~= 1 then s[i] = sx-1; break end
	if i == n then return maxflips end	-- Out of permutations.
	s[i] = i
	-- Rotate 1<-...<-i+1.
	local t = p[1]; for j=1,i do p[j] = p[j+1] end; p[i+1] = t
      end
    end
  until false
end