UseModule("IBase", "Scripts/")

--IGAMEMODE CLASS START

class 'IGameMode' (IBase)

function IGameMode:__init() super()

	self.gameResetSignal = self:CreateSignal("GameReset")
	self.gameResetParams = Parameters()

	--All the players are kept here
	self.players = { }

	--The game is not running until we are told it is running
	self.gameRunning = false

	--This is the new game mode
	SetGameMode(self)

end


function IGameMode:BuildInterfaceDefIBase()

	self:AddClassDef("IGameMode", "IBase", "The base class for any class that manages a game mode")
	self:AddFuncDef("IGameMode", self.BuildInterfaceDefIGameMode, self.I_REQUIRED_FUNC, "BuildInterfaceDefIGameMode", "The child class must build their interface in this function")
	self:AddFuncDef("IGameMode", self.InitGameMode, self.I_REQUIRED_FUNC, "InitGameMode", "Will be called when this object is being initialized")
	self:AddFuncDef("IGameMode", self.UnInitGameMode, self.I_REQUIRED_FUNC, "UnInitGameMode", "Will be called when this object is being uninitialized")
	self:AddFuncDef("IGameMode", self.AddPlayer, self.I_OPTIONAL_FUNC, "AddPlayer", "Will be called to notify the game mode a player should be added to play")
	self:AddFuncDef("IGameMode", self.RemovePlayer, self.I_OPTIONAL_FUNC, "RemovePlayer", "Will be called to notify the game mode a player should be removed from play")

	self:BuildInterfaceDefIGameMode()

end


function IGameMode:InitIBase()

	self:InitGameMode()

end


function IGameMode:UnInitIBase()

	self:RemoveAllPlayers()
	self:UnInitGameMode()

	--This is no longer the current game mode
	--BRIAN TODO: Better way to handle this?
	SetGameMode(nil)

end


function IGameMode:RemoveAllPlayers()

	local playerListCopy = { }
	for index, player in ipairs(self.players) do
		table.insert(playerListCopy, player)
	end
	for index, player in ipairs(playerListCopy) do
		if IsValid(self.RemovePlayer) then
			self:RemovePlayer(player)
		end
	end

end


function IGameMode:GameReset()

	self.gameResetSignal:Emit(self.gameResetParams)

    --Reset weapon boxes (TODO: replace with real manager at some point)
    if IsServer() then
        local objIter = GetServerWorld():GetObjectIterator()
        while not objIter:IsEnd() do
            local worldObject = objIter:Get()
            if IsValid(worldObject) and worldObject:GetTypeName() == "ScriptObject" then
                local scriptObject = ToScriptObject(worldObject)
                if scriptObject:GetScriptObjectTypeName() == "WeaponBox" then
                    --print("Respawning weapon box")
                    scriptObject:Get():Spawn()
                end
            end
            objIter:Next()
        end
    end

    if IsValid(self.GameResetImp) then
        self:GameResetImp()
    end

end


function IGameMode:SetLoadingAllowed(setAllowed)

	GetClientManager():SetLoadingAllowed(setAllowed)

end


function IGameMode:GetLoadingAllowed()

	return GetClientManager():GetLoadingAllowed()

end


--The game is considered running when the players are actually playing
--If the players are viewing results for example, then the game is considered not running
function IGameMode:SetGameRunning(setRunning)

	self.gameRunning = setRunning

end


function IGameMode:GetGameRunning()

	return self.gameRunning

end


function IGameMode:CheckGentlemansWager()

    --Check gentleman's wager achievement
    local i = 1
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local wager = true
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if (not player:GetControllerValid()) or player:GetController():GetHat() ~= "Top Hat" then
			wager = false
		end
		i = i + 1
	end
	print("Gentleman's wager: "..tostring(wager))
	if wager and numPlayers > 1 then
	    self.achievements:Unlock(self.achievements.AVMT_GENTLEMANS_WAGER)
	end

end


function IGameMode:CheckPirateParty()

    --Check pirate party achievement
    local i = 1
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local party = true
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if (not player:GetControllerValid()) or player:GetController():GetHat() ~= "Pirate Hat" or player:GetController():GetKart() ~= "Barnacle Bucket" then
			party = false
		end
		i = i + 1
	end
	print("Pirate party: "..tostring(party))
	if party and numPlayers > 1 then
	    self.achievements:Unlock(self.achievements.AVMT_PIRATE_PARTY)
	end

end


function IGameMode:CheckWargames()

    --Check war games achievement
    local i = 1
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local wargame = true
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if (not player:GetControllerValid()) or player:GetController():GetHat() ~= "General Cap" or not(player:GetController():GetKart() == "Tank" or player:GetController():GetKart() == "Willy") then
			wargame = false
		end
		i = i + 1
	end
	print("Wargame: "..tostring(wargame))
	if wargame and numPlayers > 1 then
	    self.achievements:Unlock(self.achievements.AVMT_WAR_GAMES)
	end

end


function IGameMode:CheckInspectorKemp()

    --Check inspector kemp achievement
    local i = 1
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local kemp = true
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if (not player:GetControllerValid()) or not(player:GetController():GetAccessory() == "Monocle" or player:GetController():GetAccessory() == "Mischievous") then
			kemp = false
		end
		i = i + 1
	end
	print("Kemp: "..tostring(kemp))
	if kemp and numPlayers > 1 then
	    self.achievements:Unlock(self.achievements.AVMT_INSPECTOR_KEMP)
	end

end


function IGameMode:CheckTermination()

    --Check termination achievement
    local i = 1
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local termination = true
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if (not player:GetControllerValid()) or player:GetController():GetCharacter() ~= "Robot" then
			termination = false
		end
		i = i + 1
	end
	print("Termination: "..tostring(termination))
	if termination and numPlayers > 1 then
	    self.achievements:Unlock(self.achievements.AVMT_TERMINATION)
	end

end


function IGameMode:SpawnPlayerController(player, createFunction, spawnPos, spawnOrien)

    print("** Begin SpawnPlayerController")

    local spawnPlayerControllerInsideFuncTotalTimeClock = WTimer()

    local spawnPlayerControllerCreateClock = WTimer()
	local newController = createFunction(spawnPos, spawnOrien)
	print("** SpawnPlayerControllerCreate Time: " .. tostring(spawnPlayerControllerCreateClock:GetTimeSeconds()))

    --NOTE: The next chunk takes almost 0 time
	--Give this player ownership of the newly created controller
	GetServerWorld():SetObjectOwner(newController:GetID(), player:GetUniqueID())

    local spawnPlayerControllerSetControllerClock = WTimer()
	--Notify the player of their controller
	player:SetController(newController)
	print("** SpawnPlayerControllerSetController Time: " .. tostring(spawnPlayerControllerSetControllerClock:GetTimeSeconds()))

	print("** SpawnPlayerControllerInsideFuncTotalTime Time: " .. tostring(spawnPlayerControllerInsideFuncTotalTimeClock:GetTimeSeconds()))

end


function IGameMode:DestroyPlayerController(player, destroyFunction)

	local destroyController = player:GetController()

	player:SetController(nil)

	--Ownership will be removed when the controller is destroyed
	destroyFunction(destroyController)

end


--Controller creators
function CreateKartController(spawnPos, spawnOrien)

	local spawnParams = Parameters()
	spawnParams:GetOrCreateParameter("Position"):SetWVector3Data(spawnPos)
	spawnParams:GetOrCreateParameter("Orientation"):SetWQuaternionData(spawnOrien)

    local createKartControllerClock = WTimer()
	local createdObject = GetServerWorld():CreateObject("Kart" .. tostring(GenerateID()), "SyncedKart", true, spawnParams)
	print("** CreateKartController Time: " .. tostring(createKartControllerClock:GetTimeSeconds()))

	return createdObject

end


function DestroyKartController(controller)

	GetServerWorld():DestroyObject(controller:GetID())

end


function CreateBallController(spawnPos, spawnOrien)

	local spawnParams = Parameters()
	spawnParams:GetOrCreateParameter("PositionX"):SetFloatData(spawnPos.x)
	spawnParams:GetOrCreateParameter("PositionY"):SetFloatData(spawnPos.y)
	spawnParams:GetOrCreateParameter("PositionZ"):SetFloatData(spawnPos.z)
	spawnParams:GetOrCreateParameter("OrientationX"):SetFloatData(spawnOrien.x)
	spawnParams:GetOrCreateParameter("OrientationY"):SetFloatData(spawnOrien.y)
	spawnParams:GetOrCreateParameter("OrientationZ"):SetFloatData(spawnOrien.z)
	spawnParams:GetOrCreateParameter("OrientationW"):SetFloatData(spawnOrien.w)
	spawnParams:GetOrCreateParameter("ScaleX"):SetFloatData(1)
	spawnParams:GetOrCreateParameter("ScaleY"):SetFloatData(1)
	spawnParams:GetOrCreateParameter("ScaleZ"):SetFloatData(1)

	local createdObject = GetServerWorld():CreateObject("Ball" .. tostring(GenerateID()), "SyncedBallController", true, spawnParams)
	return createdObject

end


function DestroyBallController(controller)

	GetServerWorld():DestroyObject(controller:GetID())

end

--IGAMEMODE CLASS END