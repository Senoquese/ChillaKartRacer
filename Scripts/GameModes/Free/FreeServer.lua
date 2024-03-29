UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("SpawnPointManager", "Scripts/")
UseModule("FreeStates", "Scripts\\GameModes\\Free\\")

--FREESERVER CLASS START

class 'FreeServer' (IGameMode)

local ROUND_TIMER = 60 * 2.5

function FreeServer:__init(setMap) super()

    GetServerManager():SetCurrentBotType("FreeBot")

    self.resettingPlayers = { }

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode FreeServer in init")
	end

	--This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

    self:InitState()

	self.gameStates = FreeStates()

	--First wait for at least 1 person
	self.gameState = nil
	self:SetGameState(self.gameStates.GS_WAIT_FOR_PLAYERS)

    self.gameClock = WTimer()
    self.showWinnersClock = WTimer()
    self.showWinnersTimer = 10

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--This is emitted to when a player pressed the reset key
	self.playerResetSlot = self:CreateSlot("PlayerReset", "PlayerReset")

	--This is emitted to when a player is respawned
	self.playerRespawnedSlot = self:CreateSlot("PlayerRespawned", "PlayerRespawned")
	GetServerManager():GetSignal("PlayerRespawned"):Connect(self.playerRespawnedSlot)

    --This is emitted when a player performs a stunt
    self.playerStuntSlot = self:CreateSlot("PlayerStunt", "PlayerStunt")

	--Init all the players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:AddPlayer(player)
		i = i + 1
	end

end


function FreeServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("FreeServer", "IGameMode", "Manages the reverse tag game mode")

end


function FreeServer:InitGameMode()

	--There isn't really any kind of game being played here
	self:SetGameRunning(false)

end


function FreeServer:UnInitGameMode()

    self:UnInitState()
	self:UnInitGame()

end

function FreeServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == addPlayer:GetUniqueID() then
			print("%%% Attempt was made in FreeServer:AddPlayer() to add an existing player")
			return
		end
	end

    --Spawn a controller for this player
	local spawnPos, spawnOrien = GetSpawnPointManager():GetFreeSpawnPoint()
	if spawnPos == nil or spawnOrien == nil then
		spawnPos = WVector3()
		spawnOrien = WQuaternion()
	end
    --self:SpawnPlayerController(addPlayer, CreateBallController, spawnPos, spawnOrien)
	self:SpawnPlayerController(addPlayer, CreateKartController, spawnPos, spawnOrien)

	--We want to know when the player is reset so we can respawn them with a delay
	addPlayer:GetSignal("Resetting", true):Connect(self.playerResetSlot)

    --Listen for stunts
    addPlayer:GetController():GetSignal("Stunt", true):Connect(self.playerStuntSlot)

    self:InitPlayerState(addPlayer)

	table.insert(self.players, addPlayer)

    --Check if the game is waiting for players to join for it to start
	if self.gameState == self.gameStates.GS_WAIT_FOR_PLAYERS then
		--Start the game!
		self:SetGameState(self.gameStates.GS_PLAY)
	end

end

function FreeServer:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	self.param:SetIntData(player.userData.score)
	
	print("SetPlayerScore: "..player:GetName()..", "..playerScore)
	
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Score", self.param)

end

function FreeServer:GetPlayerScore(player)

    if IsValid(player.userData.score) then
	    return player.userData.score
	else
        return 0
    end

end

function FreeServer:RemovePlayer(removePlayer)

    self:UnInitPlayerState(removePlayer)

	local removeIndex = 0
	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == removePlayer:GetUniqueID() then
			removeIndex = index
		end
	end

	if removeIndex > 0 then
		table.remove(self.players, removeIndex)
	else
		print("%%% Attempt was made in FreeServer:RemovePlayer() to remove a player we don't know about")
	end

	--self:DestroyPlayerController(removePlayer, DestroyBallController)
	self:DestroyPlayerController(removePlayer, DestroyKartController)

end


function FreeServer:GetNumberOfPlayers()

	return #self.players

end


function FreeServer:UnInitGame()

	if IsValid(self.ITSensor) then
		self.ITSensor:UnInit()
		self.ITSensor = nil
	end

end

--This will respawn all the players
function FreeServer:RespawnAllPlayers()

	for index, player in ipairs(self.players)
	do
		GetServerManager():RespawnPlayer(player:GetUniqueID())
	end

	GetServerManager():ResetAllPlayers()

end

function FreeServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState
	
	self.param:SetFloatData(ROUND_TIMER)
    GetServerSystem():GetSendStateTable("Map"):SetState("RoundTimer", self.param)
	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)
	
	if oldState == self.gameStates.GS_SHOW_WINNERS then
	    self:UnInitStateShowWinners()
	end
	
	if newGameState == self.gameStates.GS_PLAY then
	    self:SetGameRunning(true)
	    self:RespawnAllPlayers()
	    self.gameClock:Reset()
	    self.gameEndTime = GetServerSystem():GetTime() + ROUND_TIMER
	    self.param:SetFloatData(self.gameEndTime)
	    GetServerSystem():GetSendStateTable("Map"):SetState("GameEndTime", self.param)
	elseif newGameState == self.gameStates.GS_SHOW_WINNERS then
	    self:SetGameRunning(false)
	    self:InitStateShowWinners()
    end
	
	self:SetGameRunning(self.gameState == self.gameStates.GS_PLAY)
		
end

function FreeServer:GetGameState()

	return self.gameState

end

function FreeServer:InitStateShowWinners()

	self.showWinnersClock:Reset()

	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(false)
		player:SetControllerEnabled(false)
	end

end


function FreeServer:UnInitStateShowWinners()

	--Reset all the players scores
	for index, player in ipairs(self.players) do
		self:SetPlayerScore(player, 0)
	
		local controller = player:GetController()
		controller:SetEnableControls(true)
		controller:SetBoostPercent(0)
		player:SetControllerEnabled(true)
	end

end

function FreeServer:Process()

	self:ProcessResettingPlayers()
	
	if self:GetGameState() == self.gameStates.GS_PLAY and self.gameClock:GetTimeSeconds() >= ROUND_TIMER then
	    self:SetGameState(self.gameStates.GS_SHOW_WINNERS)
	elseif self:GetGameState() == self.gameStates.GS_SHOW_WINNERS and self.showWinnersClock:GetTimeSeconds() >= self.showWinnersTimer then
	    self:SetGameState(self.gameStates.GS_PLAY)
	end

end


function FreeServer:ProcessResettingPlayers()

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock

			--Index 1 is the actual player object
			GetServerManager():RespawnPlayer(resetPlayer[1]:GetUniqueID())
			table.remove(self.resettingPlayers, index)
			--If there are more to be reset, we will catch them next time
			return

	end

end

function FreeServer:GetRandomTarget()

    local sp = GetSpawnPointManager():GetFreeSpawnPoint()
    --print("sp: "..tostring(sp))
    return sp

end

function FreeServer:PlayerStunt(stuntParams)

	local angle = stuntParams:GetParameter("angle", true):GetFloatData()
    local playerID = stuntParams:GetParameter("player", true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	print("Stunt by "..player:GetName()..": "..angle)
	
	self:SetPlayerScore( player, self:GetPlayerScore(player) + math.floor(angle) )

end

function FreeServer:PlayerReset(resetParams)

	local playerKartID = resetParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromObjectID(playerKartID)
	--Make sure this player isnt resetting already
	local alreadyResetting = false
	for index, resetPlayer in pairs(self.resettingPlayers) do
		if resetPlayer[1] == player then
			alreadyResetting = true
		end
	end
	if not alreadyResetting then
		table.insert(self.resettingPlayers, { player, WTimer() })
	end

end


function FreeServer:PlayerRespawned(respawnParams)

	local playerID = respawnParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	player:Reset()

end


function FreeServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
    
	self:AddPlayer(player)

end


function FreeServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:RemovePlayer(player)

end

function FreeServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("RoundTimer")

end


function FreeServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RoundTimer")

end

function FreeServer:InitPlayerState(player)

	--GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Score")
	--GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_ScoreTarget")

	--Init the data for this client
	--player.userData.state = nil
	player.userData.score = 0
	--player.userData.scoreTarget = ""
    
end


function FreeServer:UnInitPlayerState(player)

	--GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Score")
	--GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_ScoreTarget")

end

function FreeServer:GetProcessSlot()

	return self.processSlot

end

--FreeServer CLASS END