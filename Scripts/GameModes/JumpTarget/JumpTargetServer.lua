UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("SpawnPointManager", "Scripts/")
UseModule("JumpTargetStates", "Scripts\\GameModes\\JumpTarget\\")
UseModule("JumpTargetManager", "Scripts\\GameModes\\JumpTarget\\")

local JUMP_ROUND_TIMER = 40
local setRoundTimer = function (value) JUMP_ROUND_TIMER = value end
local getRoundTimer = function () return JUMP_ROUND_TIMER end
DefineVar("JUMP_ROUND_TIMER", setRoundTimer, getRoundTimer)

local JUMP_NUM_ROUNDS = 5
local setRounds = function (value) JUMP_NUM_ROUNDS = value end
local getRounds = function () return JUMP_NUM_ROUNDS end
DefineVar("JUMP_NUM_ROUNDS", setRounds, getRounds)

local JUMP_PLAYER_RESET_TIMER = 1
local setReset = function (value) JUMP_PLAYER_RESET_TIMER = value end
local getReset = function () return JUMP_PLAYER_RESET_TIMER end
DefineVar("JUMP_PLAYER_RESET_TIMER", setReset, getReset)

--JUMPTARGETSERVER CLASS START

class 'JumpTargetServer' (IGameMode)

function JumpTargetServer:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode JumpTargetServer in init")
	end

    GetServerManager():SetCurrentBotType("TargetBot")

	--This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

	self.resettingPlayers = { }

	--This is emitted whenever a new round starts
	self.roundStartSignal = self:CreateSignal("RoundStart")
	self.roundStartParams = Parameters()

	--This is emitted whenever a new game start
	self.gameStartSignal = self:CreateSignal("GameStart")
	self.gameStartParams = Parameters()

	self.jumpTargetManager = nil
	self:InitJumpTargets()

	self:InitState()

	self.jumpStates = JumpTargetStates()

	--First wait for at least 1 person
	self.gameState = nil
	self:SetGameState(self.jumpStates.GS_WAIT_FOR_PLAYERS)

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

	--This is the global time that the round will start so the countdown is in sync
	self.roundStartTime = 0

	--This is emitted to when a player is respawned
	self.playerRespawnedSlot = self:CreateSlot("PlayerRespawned", "PlayerRespawned")
	GetServerManager():GetSignal("PlayerRespawned"):Connect(self.playerRespawnedSlot)

    --Collision slots
    self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")
	GetBulletPhysicsSystem():GetSignal("StartCollision", true):Connect(self.collisionStartSlot)

	--Track how many rounds have been played so far
	self.roundsPlayed = 0

	--The clock to keep track of how long the current round has been going on
	self.roundClock = WTimer()
	self.countdownActive = false

	self.countdownClock = WTimer()
	self.countdownTimer = 3

	--The clock to keep track of how long the winners have been shown
	self.showWinnersClock = WTimer()
	self.showWinnersTimer = 10

	--Load the settings defined in the map
	self:LoadMapSettings(self.map)

	self:InitGame()

	--Init all the players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:AddPlayer(player)
		i = i + 1
	end

end


function JumpTargetServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("JumpTargetServer", "IGameMode", "Manages the jump target game mode")

end


function JumpTargetServer:InitGameMode()

end


function JumpTargetServer:UnInitGameMode()

	self:UnInitState()
	self:UnInitGame()

end


function JumpTargetServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState

	print("%%% New Jump gamestate: " .. self.jumpStates:GameStateToString(self.gameState))

    self.param:SetFloatData(JUMP_ROUND_TIMER)
    GetServerSystem():GetSendStateTable("Map"):SetState("RoundTimer", self.param)
	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)

	--UnInit old state
	if oldState == self.jumpStates.GS_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.jumpStates.GS_COUNTDOWN then
		self:UnInitStateCountdown()
	elseif oldState == self.jumpStates.GS_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.jumpStates.GS_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.jumpStates.GS_WAIT_FOR_PLAYERS then
		self:SetGameRunning(false)
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.jumpStates.GS_COUNTDOWN then
		self:SetGameRunning(true)
		self:InitStateCountdown()
	elseif self.gameState == self.jumpStates.GS_PLAY then
		self:SetGameRunning(true)
		self:InitStatePlay()
	elseif self.gameState == self.jumpStates.GS_SHOW_WINNERS then
		self:SetGameRunning(false)
		self:InitStateShowWinners()
	end

	--Update the states of all the current players based on this new game state
	self:UpdatePlayerStates()

end


function JumpTargetServer:GetGameState()

	return self.gameState

end


function JumpTargetServer:SetPlayerState(player, playerState)

	player.userData.state = playerState
	self.param:SetIntData(player.userData.state)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_State", self.param)

end


function JumpTargetServer:GetPlayerState()

	return player.userData.state

end


function JumpTargetServer:GetPlayerScore(player)

	return player.userData.score

end

function JumpTargetServer:GetRandomTarget()

    return self.jumpTargetManager:GetRandomTarget()

end

function JumpTargetServer:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	self.param:SetIntData(player.userData.score)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Score", self.param)

end


--Update all the current player's states based on the current game state
function JumpTargetServer:UpdatePlayerStates()

	for index, player in ipairs(self.players)
	do
		self:UpdatePlayerState(player)
	end

end


--Update the passed in player's state based on the current game state
function JumpTargetServer:UpdatePlayerState(forPlayer)

	--Based on the current game state, set this player's state
	if self:GetGameState() == self.jumpStates.GS_WAIT_FOR_PLAYERS then
		--This state should never be set with a player in the server
        forPlayer:GetController():SetEnableControls(true)
	elseif self:GetGameState() == self.jumpStates.GS_COUNTDOWN then
		--The game is about to start
		--forPlayer:GetController():SetBoostPercent(1)
		self:SetPlayerState(forPlayer, self.jumpStates.PS_PLAY)
        forPlayer:GetController():SetEnableControls(false)
	elseif self:GetGameState() == self.jumpStates.GS_PLAY then
		forPlayer:GetController():SetBoostPercent(1)
		self:SetPlayerState(forPlayer, self.jumpStates.PS_PLAY)
        forPlayer:GetController():SetEnableControls(true)
	elseif self:GetGameState() == self.jumpStates.GS_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(forPlayer, self.jumpStates.PS_SHOW_WINNERS)
		forPlayer:GetController():SetEnableControls(false)
	end

end


function JumpTargetServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players)
	do
		if player == addPlayer then
			print("%%% Attempt was made in JumpTargetServer:AddPlayer() to add an existing player")
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

	--Check if the game is waiting for players to join for it to start
	if self:GetGameState() == self.jumpStates.GS_WAIT_FOR_PLAYERS then
		--Start the game!
		self:SetGameState(self.jumpStates.GS_COUNTDOWN)
	end

	--We want to know when the player is reset so we can respawn them with a delay
	addPlayer:GetSignal("Resetting", true):Connect(self.playerResetSlot)

	--Init this player's state
	self:InitPlayerState(addPlayer)

	--Update this player's state based on the current game state
	self:UpdatePlayerState(addPlayer)

	table.insert(self.players, addPlayer)

	self.jumpTargetManager:RegisterPlayer(addPlayer)

end


function JumpTargetServer:RemovePlayer(removePlayer)

	self.jumpTargetManager:UnregisterPlayer(removePlayer)

	self:UnInitPlayerState(removePlayer)

	local removeIndex = 0
	for index, player in ipairs(self.players) do
		if player == removePlayer then
			removeIndex = index
		end
	end

	if removeIndex > 0 then
		table.remove(self.players, removeIndex)
	else
		print("%%% Attempt was made in JumpTargetServer:RemovePlayer() to remove a player we don't know about")
	end

	--At least 1 player is required for there to be any kind of game
	if self:GetGameState() ~= self.jumpStates.GS_WAIT_FOR_PLAYERS and self:GetNumberOfPlayers() < 1 then
		--Go back to waiting
		self:SetGameState(self.jumpStates.GS_WAIT_FOR_PLAYERS)
	end

    --self:DestroyPlayerController(removePlayer, DestroyBallController)
	self:DestroyPlayerController(removePlayer, DestroyKartController)

end


function JumpTargetServer:GetNumberOfPlayers()

	return #self.players

end


function JumpTargetServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("RoundStartTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("RoundTimer")

end


function JumpTargetServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RoundStartTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RoundTimer")

end


function JumpTargetServer:InitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_ScoreTarget")

	--Init the data for this client
	player.userData.state = nil
	player.userData.score = 0
	player.userData.scoreTarget = ""
    
end


function JumpTargetServer:UnInitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_ScoreTarget")

end


function JumpTargetServer:InitJumpTargets()

	--Init the checkpoint manager with this map and checkpoints
	self.jumpTargetManager = JumpTargetManager(self.map)
	self.playerScoresPointsSlot = self:CreateSlot("PlayerScoresPoints", "PlayerScoresPoints")
	self.jumpTargetManager:GetSignal("PlayerScoresPoints"):Connect(self.playerScoresPointsSlot)

	self.jumpTargetManager:GetSlot("IncreasePoints"):Connect(self.roundStartSignal)
	self.jumpTargetManager:GetSlot("ResetPoints"):Connect(self.gameStartSignal)

end


function JumpTargetServer:UnInitJumpTargets()

	self.jumpTargetManager:UnInit()
	self.jumpTargetManager = nil

end


function JumpTargetServer:LoadMapSettings(fromMap)

	--Map Extents
	local mapExtentsParam = self.map:GetSetting("MapExtents", false)
	if IsValid(mapExtentsParam) then
		self.mapExtents = mapExtentsParam:GetFloatData()
	end

	--Find the FalloutSensor in the map
	self.falloutSensor = self.map:GetMapObject("FalloutSensor", true)
	self.falloutSensorCallbackSlot = self:CreateSlot("FalloutSensorCallbackSlot", "FalloutSensorCallbackSlot")
	self.falloutSensor:Get():GetSignal("SensorCallback", true):Connect(self.falloutSensorCallbackSlot)

end


function JumpTargetServer:InitGame()

end


function JumpTargetServer:UnInitGame()

end


function JumpTargetServer:Process()

    local frameTime = GetFrameTime()

	if self.gameState == self.jumpStates.GS_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers(frameTime)
	elseif self.gameState == self.jumpStates.GS_COUNTDOWN then
		self:ProcessStateCountdown(frameTime)
	elseif self.gameState == self.jumpStates.GS_PLAY then
		self:ProcessStatePlay(frameTime)
	elseif self.gameState == self.jumpStates.GS_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
	end

	self:ProcessResettingPlayers(frameTime)
	self.jumpTargetManager:Process(frameTime)

end


function JumpTargetServer:ProcessResettingPlayers(frameTime)

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock
		if resetPlayer[2]:GetTimeSeconds() > JUMP_PLAYER_RESET_TIMER then
			--Index 1 is the actual player object
			GetServerManager():RespawnPlayer(resetPlayer[1]:GetUniqueID())
			table.remove(self.resettingPlayers, index)
			--If there are more to be reset, we will catch them next time
			return
		end
	end

end


function JumpTargetServer:InitStateWaitForPlayers()

	--Nothing to init here

end


function JumpTargetServer:UnInitStateWaitForPlayers()

	--Nothing to uninit here

end


function JumpTargetServer:InitStateCountdown()

	--Notify the clients how long this round will last
	self.param:SetFloatData(JUMP_ROUND_TIMER)
	GetServerSystem():GetSendStateTable("Map"):SetState("RoundTimer", self.param)

	--Notify the clients what time the countdown will start at so we are all in sync
	self.roundStartTime = GetServerSystem():GetTime() + 6
	self.param:SetFloatData(self.roundStartTime)
	GetServerSystem():GetSendStateTable("Map"):SetState("RoundStartTime", self.param)

	--The countdown isn't active until the round start time has passed
	self.countdownActive = false

	--Give all the players boost at the start of a new round
	for index, player in ipairs(self.players) do
		player:GetController():SetBoostPercent(1)
	end

	--Line all the players up at the start line
	GetSpawnPointManager():ResetSpawnPointer()
    self:RespawnAllPlayers()
	
    --Disable their controls
	self:SetEnablePlayerControls(false)

	if self.roundsPlayed == 0 then
		--New game starts!
		self.gameStartSignal:Emit(self.gameStartParams)
	end

	--New round starts!
	self.roundStartSignal:Emit(self.roundStartParams)

	--Notify the base IGameMode that the game has reset
	self:GameReset()

end


function JumpTargetServer:UnInitStateCountdown()

	--Nothing to uninit here

end


function JumpTargetServer:InitStatePlay()

	--Reset the round clock
	self.roundClock:Reset()

	--They can control their controllers again
	self:SetEnablePlayerControls(true)

    --Give everyone a spring
    GS()
    --GT()

	--They can score again
	for index, player in ipairs(self.players)
	do
		player.userData.scoreLock = false
	end

end


function JumpTargetServer:UnInitStatePlay()

	--Nothing to uninit here

end


function JumpTargetServer:InitStateShowWinners()

	self.showWinnersClock:Reset()

	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(false)
		player:SetControllerEnabled(false)
	end

end


function JumpTargetServer:UnInitStateShowWinners()

	--Reset the number of rounds played
	self.roundsPlayed = 0

	--Reset all the players scores
	for index, player in ipairs(self.players) do
		self:SetPlayerScore(player, 0)
	
		local controller = player:GetController()
		controller:SetEnableControls(true)
		player:SetControllerEnabled(true)
	end

end


--Waiting for more players
function JumpTargetServer:ProcessStateWaitForPlayers(frameTime)

	--Do nothing

end


--Countdown, Game is about to start
function JumpTargetServer:ProcessStateCountdown(frameTime)

	--The countdown doesn't start until after the time in self.roundStartTime
	if GetServerSystem():GetTime() > self.roundStartTime and not self.countdownActive then
		self.countdownClock:Reset()
		self.countdownActive = true
	end

	if self.countdownActive then
		if self.countdownClock:GetTimeSeconds() > self.countdownTimer then
			--Countdown finished
			self:SetGameState(self.jumpStates.GS_PLAY)
		end
	end

end


function JumpTargetServer:ProcessStatePlay(frameTime)

	--Check if all the players are done
	local roundOver = true
	for index, player in ipairs(self.players) do
		if not player.userData.scoreLock then
			roundOver = false
		end
	end

	--A round clock makes sure a round doesn't go on forever
	if roundOver or (self.roundClock:GetTimeSeconds() > JUMP_ROUND_TIMER) then
		self.roundsPlayed = self.roundsPlayed + 1
		--Check if all the rounds have been played
		if self.roundsPlayed >= JUMP_NUM_ROUNDS then
			self:SetGameState(self.jumpStates.GS_SHOW_WINNERS)
			return
		end
		self:SetGameState(self.jumpStates.GS_COUNTDOWN)
	end

end


function JumpTargetServer:ProcessStateShowWinners(frameTime)

	--After giving the clients time to review the winners list, start the countdown again
	if self.showWinnersClock:GetTimeSeconds() > self.showWinnersTimer then
		self:SetGameState(self.jumpStates.GS_COUNTDOWN)
	end

end


--This will respawn all the players
function JumpTargetServer:RespawnAllPlayers()

	for index, player in ipairs(self.players)
	do
		GetServerManager():RespawnPlayer(player:GetUniqueID())
	end

	GetServerManager():ResetAllPlayers()

end


--Enable or disable the players ability to control their controllers
function JumpTargetServer:SetEnablePlayerControls(enabled)

	for index, player in ipairs(self.players)
	do
		local controller = player:GetController()
		controller:SetEnableControls(enabled)
	end

end


function JumpTargetServer:PlayerReset(resetParams)

	--Don't do anything on a reset

end


function JumpTargetServer:FalloutSensorCallbackSlot(falloutParams)

	--Once they fall out of the map, they cannot score
	if self.gameState == self.jumpStates.GS_PLAY then
		local playerID = falloutParams:GetParameter("Player", true):GetIntData()
		local player = GetPlayerManager():GetPlayerFromID(playerID)
		player.userData.scoreLock = true
	end

end


function JumpTargetServer:PlayerRespawned(respawnParams)

	local playerID = respawnParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	player:Reset()

end


function JumpTargetServer:PlayerScoresPoints(pointsParams)

	local playerID = pointsParams:GetOrCreateParameter(0):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	--Only let them score if they haven't scored yet this round
	if not player.userData.scoreLock then
		--Set this players score target
		local scoreTargetName = pointsParams:GetOrCreateParameter(1):GetStringData()
		player.userData.scoreTarget = scoreTargetName
		self.param:SetStringData(player.userData.scoreTarget)
		GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_ScoreTarget", self.param)
		--Set this players score
		local points = pointsParams:GetOrCreateParameter(2):GetIntData()
		self:SetPlayerScore(player, player.userData.score + points)
		player.userData.scoreLock = true
		print("Player " .. player:GetName() .. " scored! New score: " .. tostring(player.userData.score))
	end

end

function JumpTargetServer:BulletCollisionStart(collParams)

	--BRIAN TODO: Collision test code
	--print("ClientManager:BulletCollisionStart() called")

	--local collidePosition = WVector3()
	local aID = collParams:GetParameter("ObjectAID", true):GetIntData()
	local bID = collParams:GetParameter("ObjectBID", true):GetIntData()
	--collidePosition.x = collParams:GetParameter("ImpactX", true):GetFloatData()
	--collidePosition.y = collParams:GetParameter("ImpactY", true):GetFloatData()
	--collidePosition.z = collParams:GetParameter("ImpactZ", true):GetFloatData()
	--local appliedImpulse = collParams:GetParameter("AppliedImpulse", true):GetFloatData()
	local aMatName = collParams:GetParameter("AMaterial", true):GetStringData()
	local bMatName = collParams:GetParameter("BMaterial", true):GetStringData()
	local normal = collParams:GetParameter("Normal", true):GetWVector3Data()

	--print("Collision between "..aMatName.." and "..bMatName)

    if aMatName == 'bouncymat' or bMatName == 'bouncymat' then
        local tID = nil
        if aMatName == 'bouncymat' then
            normal:Negate()
            tID = bID
        else
            tID = aID
        end
        local tPhysObj = nil
        local objPlayer = GetPlayerManager():GetPlayerFromObjectID(tID)
        if IsValid(objPlayer) then
            tPhysObj = objPlayer:GetController()
        else
            tPhysObj = ToBulletPhysicalObject(GetServerWorld():GetObjectFromID(tID))
        end
        if IsValid(tPhysObj) then
            tPhysObj:ApplyWorldImpulse(normal * 20000, WVector3())
        end
	end

end



function JumpTargetServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:AddPlayer(player)

end


function JumpTargetServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:RemovePlayer(player)

end


function JumpTargetServer:GetProcessSlot()

	return self.processSlot

end

--JUMPTARGETSERVER CLASS END