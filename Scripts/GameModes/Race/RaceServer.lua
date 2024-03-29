UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("RaceCheckpointManager", "Scripts\\GameModes\\Race\\")
UseModule("RaceNodeManager", "Scripts\\GameModes\\Race\\")
UseModule("RaceStates", "Scripts\\GameModes\\Race\\")
UseModule("AchievementManager", "Scripts/")

local PLAYER_RESET_TIMER = 1
local setReset = function (value) PLAYER_RESET_TIMER = value end
local getReset = function () return PLAYER_RESET_TIMER end
DefineVar("PLAYER_RESET_TIMER", setReset, getReset)

local WAIT_PLAYERS = 1
local setWait = function (value) WAIT_PLAYERS = value end
local getWait = function () return WAIT_PLAYERS end
DefineVar("WAIT_PLAYERS", setWait, getWait)

local WAIT_PLAYER_TIME = 15

local NUM_LAPS = 2
local setNumLaps = function (value) NUM_LAPS = value end
local getNumLaps = function () return NUM_LAPS end
DefineVar("NUM_LAPS", setNumLaps, getNumLaps)

local FORCE_FINISH = false
local setForceFinish = function (value) FORCE_FINISH = value end
local getForceFinish = function () return FORCE_FINISH end
DefineVar("FORCE_FINISH", setForceFinish, getForceFinish)

local RACE_BOOST_GROWTH = 4
local setRaceBoost = function (value) RACE_BOOST_GROWTH = value end
local getRaceBoost = function () return RACE_BOOST_GROWTH end
DefineVar("RACE_BOOST_GROWTH", setRaceBoost, getRaceBoost)

local RACE_FORCE_FINISH_TIME = 60
local setRaceFinish = function (value) RACE_FORCE_FINISH_TIME = value end
local getRaceFinish = function () return RACE_FORCE_FINISH_TIME end
DefineVar("RACE_FORCE_FINISH_TIME", setRaceFinish, getRaceFinish)

--RACESERVER CLASS START

class 'RaceServer' (IGameMode)

function RaceServer:__init(setMap) super()

    -- debug
    self.sameNode = false

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode Race in init")
	end

	GetServerManager():SetCurrentBotType("RaceBot")
	--GetServerManager():SetCurrentBotType("TestBot")

    --Lap Count
	local lapCountParam = self.map:GetSetting("LapCount", false)
	if IsValid(lapCountParam) then
		NUM_LAPS = lapCountParam:GetIntData()
	else
	    NUM_LAPS = 3
    end

	--This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

	--This is clock that measures how much time has passed in the current game state
	self.stateClock = WTimer()

	--These are limiter clocks
	self.updatePlayerPlacesLimit = WTimer(1 / 20)
	self.processPlayerBoostsLimit = WTimer(1 / 20)
	self.playerBoostsTD = 0

	--Race settings init
	self.raceCountdownTimer = 3
	self.showWinnersTimer = 10

	self:InitState()

	self.raceNodeManager = nil
	self:InitNodes()

	self.raceCheckpointManager = nil
	self:InitCheckpoints()

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	self.playerResetSlot = self:CreateSlot("PlayerReset", "PlayerReset")

	--This is the global time that the round will start so the countdown is in sync
	self.roundStartTime = 0
	self.doneWaitTime = 0
	self.countdownActive = false

	--The race will be forced to end at this time
	self.raceEndTime = 0
	self.raceEndTimeActive = false

	--These are the players that are waiting to reset
	self.resettingPlayers = { }

	--The current placement list
	self.placementList = { }

	self.raceStates = RaceStates()

	--First wait for at least 2 players to be in the server
	self.gameState = nil
	self:SetGameState(self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS)

	--Init all the players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:AddPlayer(player)
		i = i + 1
	end

end


function RaceServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("RaceServer", "IGameMode", "Manages the race game mode")

end


function RaceServer:InitGameMode()

end


function RaceServer:UnInitGameMode()

	self:UnInitCheckpoints()
	self:UnInitNodes()
	self:UnInitState()

end


function RaceServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("RoundStartTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("RaceEndTime")

	--Race settings
	--NumLaps
	GetServerSystem():GetSendStateTable("Map"):NewState("NumLaps")
	self.param:SetIntData(NUM_LAPS)
	GetServerSystem():GetSendStateTable("Map"):SetState("NumLaps", self.param)
	print("%%% NumLaps: " .. tostring(NUM_LAPS))
	--RaceCountdownTimer
	GetServerSystem():GetSendStateTable("Map"):NewState("RaceCountdownTimer")
	self.param:SetFloatData(self.raceCountdownTimer)
	GetServerSystem():GetSendStateTable("Map"):SetState("RaceCountdownTimer", self.param)
	print("%%% RaceCountdownTimer: " .. tostring(self.raceCountdownTimer))

end


function RaceServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RoundStartTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RaceEndTime")

	GetServerSystem():GetSendStateTable("Map"):RemoveState("NumLaps")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RaceCountdownTimer")

end


function RaceServer:InitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Lap")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Place")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Checkpoint")

	--Init the data for this client
	player.userData.state = nil
	player.userData.lap = 0
	player.userData.place = 0

end


function RaceServer:UnInitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Lap")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Place")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Checkpoint")

end


function RaceServer:InitNodes()

	self.raceNodeManager = RaceNodeManager(GetServerWorld())
	--self.raceNodeManager:SetVisualizationEnabled(true)
end


function RaceServer:UnInitNodes()

	self.raceNodeManager:UnInit()
	self.raceNodeManager = nil

end


function RaceServer:InitCheckpoints()

	--Init the checkpoint manager with this map and checkpoints
	self.raceCheckpointManager = RaceCheckpointManager(self.map, self.raceNodeManager)
	self.playerFinishedLapSlot = self:CreateSlot("PlayerFinishedLap", "PlayerFinishedLap")
	self.raceCheckpointManager:GetSignal("PlayerFinishedLap"):Connect(self.playerFinishedLapSlot)
	self.playerEntersCheckpointSlot = self:CreateSlot("PlayerEntersCheckpoint", "PlayerEntersCheckpoint")
	self.raceCheckpointManager:GetSignal("PlayerEntersCheckpoint"):Connect(self.playerEntersCheckpointSlot)
	self.playerHitInvalidCheckpointSlot = self:CreateSlot("PlayerHitInvalidCheckpoint", "PlayerHitInvalidCheckpoint")
	self.raceCheckpointManager:GetSignal("PlayerHitInvalidCheckpoint"):Connect(self.playerHitInvalidCheckpointSlot)

end


function RaceServer:UnInitCheckpoints()

	self.raceCheckpointManager:UnInit()
	self.raceCheckpointManager = nil

end


function RaceServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState

	print("%%% New Race gamestate: " .. self.raceStates:GameStateToString(self.gameState))

	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)

	--Reset the state clock
	self.stateClock:Reset()

	--UnInit old state
	if oldState == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.raceStates.GAME_STATE_COUNTDOWN then
		self:UnInitStateCountdown()
	elseif oldState == self.raceStates.GAME_STATE_RACE then
		self:UnInitStateRace()
	elseif oldState == self.raceStates.GAME_STATE_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:SetGameRunning(false)
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.raceStates.GAME_STATE_COUNTDOWN then
		self:SetGameRunning(true)
		self:InitStateCountdown()
	elseif self.gameState == self.raceStates.GAME_STATE_RACE then
		self:SetGameRunning(true)
		self:InitStateRace()
	elseif self.gameState == self.raceStates.GAME_STATE_SHOW_WINNERS then
		self:SetGameRunning(false)
		self:InitStateShowWinners()
	end

	--Update the states of all the current players based on this new game state
	self:UpdatePlayerStates()

end


function RaceServer:GetGameState()

	return self.gameState

end


function RaceServer:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState

	print("%%% Player " .. player:GetName() .. " changed to state: " .. self.raceStates:PlayerStateToString(player.userData.state))

	self.param:SetIntData(player.userData.state)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_State", self.param)

    -- Clear boost!
    player:GetController():SetBoostPercent(0) 

	--Based on the player state, manage their controller
	if player.userData.state == self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS then
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_COUNTDOWN then
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_RACE then
	    print("State PLAYER_STATE_RACE")
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_RACE_FINISHED then
		--player:SetControllerEnabled(false)
		player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_SHOW_WINNERS then
		player:SetControllerEnabled(false)
		player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END then
		player:SetControllerEnabled(false)
		player:GetController():SetEnableControls(false)
	end

	--Register or unregister the player with the checkpoint manager based on the player state
	--It doesn't hurt to register or unregister a player multiple times
	if player.userData.state == self.raceStates.PLAYER_STATE_RACE then
		self.raceCheckpointManager:RegisterPlayer(player)
	else
		self.raceCheckpointManager:UnregisterPlayer(player)
	end

end


function RaceServer:GetPlayerState(player)

	return player.userData.state

end


--Update all the current player's states based on the current game state
function RaceServer:UpdatePlayerStates()

	for index, player in ipairs(self.players)
	do
		self:UpdatePlayerState(player)
	end

end


--Update the passed in player's state based on the current game state
function RaceServer:UpdatePlayerState(forPlayer)

	--Based on the current game state, set this player's state
	if self:GetGameState() == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the race to start
		self:SetPlayerState(forPlayer, self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS)

	elseif self:GetGameState() == self.raceStates.GAME_STATE_COUNTDOWN then
		--The game is about to start
		self:SetPlayerState(forPlayer, self.raceStates.PLAYER_STATE_COUNTDOWN)

	elseif self:GetGameState() == self.raceStates.GAME_STATE_RACE then
		--The game has started
		if self:GetPlayerState(forPlayer) ~= self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END then
            self:SetPlayerState(forPlayer, self.raceStates.PLAYER_STATE_RACE)
        end

	elseif self:GetGameState() == self.raceStates.GAME_STATE_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(forPlayer, self.raceStates.PLAYER_STATE_SHOW_WINNERS)
	end

end


function RaceServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == addPlayer:GetUniqueID() then
			error("Attempt was made in RaceServer:AddPlayer() to add an existing player")
		end
	end

	--Spawn a controller for this player
	local spawnPos, spawnOrien = GetSpawnPointManager():GetFreeSpawnPoint()
	if spawnPos == nil or spawnOrien == nil then
		spawnPos = WVector3()
		spawnOrien = WQuaternion()
	end

	--BRIAN TODO: Debug only
	print("SpawnPlayerController " .. addPlayer:GetName())

	--self:SpawnPlayerController(addPlayer, CreateBallController, spawnPos, spawnOrien)
	self:SpawnPlayerController(addPlayer, CreateKartController, spawnPos, spawnOrien)

	--We want to know when the player is reset so we can respawn them on a node
	addPlayer:GetSignal("Resetting", true):Connect(self.playerResetSlot)

	--Init this player's state
	self:InitPlayerState(addPlayer)

	--This will set this player's state based on the current game state
	if self:GetGameState() == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the race to start
		self:SetPlayerState(addPlayer, self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS)

        --Reset done wait timer
        self.doneWaitTime = GetServerSystem():GetTime() + WAIT_PLAYER_TIME

	elseif self:GetGameState() == self.raceStates.GAME_STATE_COUNTDOWN then
		--The game has already started, this player must wait
		self:SetPlayerState(addPlayer, self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END)

	elseif self:GetGameState() == self.raceStates.GAME_STATE_RACE then
		--The game has already started, this player must wait
		self:SetPlayerState(addPlayer, self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END)

	elseif self:GetGameState() == self.raceStates.GAME_STATE_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(addPlayer, self.raceStates.PLAYER_STATE_SHOW_WINNERS)
	end

	table.insert(self.players, addPlayer)

end


function RaceServer:RemovePlayer(removePlayer)

	--Remove this player from the race managers
	self.raceCheckpointManager:UnregisterPlayer(removePlayer)

	self:UnInitPlayerState(removePlayer)

	for index, placed in ipairs(self.placementList) do
		if placed:GetUniqueID() == removePlayer:GetUniqueID() then
			table.remove(self.placementList, index)
			break
		end
	end

	for index, resetting in ipairs(self.resettingPlayers) do
		if resetting[1]:GetUniqueID() == removePlayer:GetUniqueID() then
			table.remove(self.resettingPlayers, index)
			break
		end
	end

	local removeIndex = 0
	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == removePlayer:GetUniqueID() then
			removeIndex = index
		end
	end

	if removeIndex > 0 then
		table.remove(self.players, removeIndex)
	else
		print("%%% Attempt was made in RaceServer:RemovePlayer() to remove a player we don't know about")
	end

	--self:DestroyPlayerController(removePlayer, DestroyBallController)
	self:DestroyPlayerController(removePlayer, DestroyKartController)

end


function RaceServer:GetNumberOfPlayers()

	return #self.players

end


function RaceServer:Process()

	local frameTime = GetFrameTime()

	self.raceCheckpointManager:Process(frameTime)

	if self.gameState == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_COUNTDOWN then
		self:ProcessStateCountdown(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_RACE then
		self:ProcessStateRace(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
	end

	self:ProcessResettingPlayers(frameTime)

end


function RaceServer:ProcessResettingPlayers(frameTime)

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock
		if resetPlayer[2]:GetTimeSeconds() > PLAYER_RESET_TIMER then
			--Index 1 is the actual player object
			self:RespawnPlayerAtLastNode(resetPlayer[1]:GetUniqueID())
			table.remove(self.resettingPlayers, index)
			--If there are more to be reset, we will catch them next time
			break
		end
	end

end


function RaceServer:InitStateWaitForPlayers()

	--Nothing to init here

end


function RaceServer:UnInitStateWaitForPlayers()

	--Nothing to uninit here

end


function RaceServer:InitStateCountdown()

	--Send the num laps again in case it changed
	self.param:SetIntData(NUM_LAPS)
	GetServerSystem():GetSendStateTable("Map"):SetState("NumLaps", self.param)
	print("%%% NumLaps: " .. tostring(NUM_LAPS))

	--BRIAN TODO: Debug only
	print("RespawnAllPlayers()")

	--Line all the players up at the start line
	GetSpawnPointManager():ResetSpawnPointer()
	self:RespawnAllPlayers()
	--Disable their controls

	for index, player in ipairs(self.players) do
		--Always start all players on lap 1
		self:SetPlayerLap(player, 1)
	end

	--Notify the clients what time the countdown will start at so we are all in sync
	self.roundStartTime = GetServerSystem():GetTime() + 1
	self.param:SetFloatData(self.roundStartTime)
	GetServerSystem():GetSendStateTable("Map"):SetState("RoundStartTime", self.param)

	--The countdown isn't active until the round start time has passed
	self.countdownActive = false

	--Notify the base IGameMode that the game has reset
	self:GameReset()

end


function RaceServer:GameResetImp()

    --Clear items
    GetWeaponManagerServer():RemoveWeapons(nil)

end


function RaceServer:UnInitStateCountdown()

	--Nothing to uninit here

end


function RaceServer:InitStateRace()

    for index, player in ipairs(self.players) do
        player.userData.node = 0
        player.userData.nodeCount = 0
	end

end


function RaceServer:UnInitStateRace()

	--Nothing to uninit here

end


function RaceServer:InitStateShowWinners()

end


function RaceServer:UnInitStateShowWinners()

end


--Waiting for more players
function RaceServer:ProcessStateWaitForPlayers(frameTime)

	--At least WAIT_PLAYERS+1 players are required to start the game
	if self:GetNumberOfPlayers() > WAIT_PLAYERS and GetServerSystem():GetTime() > self.doneWaitTime then
		--We have at least WAIT_PLAYERS+1 players, start the countdown
		self:SetGameState(self.raceStates.GAME_STATE_COUNTDOWN)
	end

end


function RaceServer:ProcessStateCountdown(frameTime)

	--The countdown doesn't start until after the time in self.roundStartTime
	if GetServerSystem():GetTime() > self.roundStartTime and not self.countdownActive then
		self.stateClock:Reset()
		self.countdownActive = true
	end

	if self.countdownActive then
		if self.stateClock:GetTimeSeconds() > self.raceCountdownTimer then
			--Countdown finished
			self:SetGameState(self.raceStates.GAME_STATE_RACE)
		end
	end

end


function RaceServer:ProcessStateRace(frameTime)

	--Update the player places based on laps, checkpoints, and nodes
	self:UpdatePlayerPlaces()

	--The players currently get boost based on race placement
	self:ProcessPlayerBoosts(frameTime)

	--Find out if the race is over
	local raceOver = true
	local numRacers = 0
	local numFinished = 0
	for index, player in ipairs(self.players) do

		--BRIAN TODO: Test code only to force the race to end right at the start
		--self:SetPlayerState(player, self.raceStates.PLAYER_STATE_RACE_FINISHED)

		--If at least one player is still racing then the race isn't over
		if self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_RACE then
			raceOver = false
			numRacers = numRacers + 1
		--If at least one player has finished racing, then start the end timer
		elseif self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_RACE_FINISHED then
		    numFinished = numFinished + 1
			if not self.raceEndTimeActive then
				self.raceEndTimeActive = true
				self.raceEndTime = GetServerSystem():GetTime() + RACE_FORCE_FINISH_TIME
				self.param:SetFloatData(self.raceEndTime)
				GetServerSystem():GetSendStateTable("Map"):SetState("RaceEndTime", self.param)
			end
		end
	end

	if self.raceEndTimeActive then
		if GetServerSystem():GetTime() >= self.raceEndTime then
			raceOver = true
		end
	end

    if numRacers <= 1 and numFinished == 0 then
        raceOver = true
    end

	if raceOver or FORCE_FINISH then
		self.raceEndTimeActive = false
		self.raceEndTime = 0
		self.param:SetFloatData(self.raceEndTime)
		GetServerSystem():GetSendStateTable("Map"):SetState("RaceEndTime", self.param)
		self:SetGameState(self.raceStates.GAME_STATE_SHOW_WINNERS)
	end

end


function RaceServer:ProcessStateShowWinners(frameTime)

	--After giving the clients time to review the winners list, start the countdown again
	if self.stateClock:GetTimeSeconds() > self.showWinnersTimer then
		self:SetGameState(self.raceStates.GAME_STATE_COUNTDOWN)
	end

end


function RaceServer:ProcessPlayerBoosts(frameTime)

	--Accumulate the time diff since this code is limited
	self.playerBoostsTD = self.playerBoostsTD + frameTime

	if self.processPlayerBoostsLimit:IsTimerUp() then
		self.processPlayerBoostsLimit:Reset()
		-- Loop through players behind first
		local draftBoostAmount = 0.05
		local maxDraftDist = 12
		local draftDotMin = 0.8
		for placeIndex, placedPlayer in ipairs(self.placementList) do
			placedPlayer:GetController().draftAmount = 0
			if placeIndex > 1 then
				local player = placedPlayer
				local draftCount = 0
				for rivalPlace, rival in ipairs(self.placementList) do
					local PtoR = rival:GetPosition() - player:GetPosition()
					if rival.userData.place < player.userData.place and PtoR:Length() <= maxDraftDist and rival:GetControllerEnabled() then
						local PtoRNorm = WVector3(PtoR)
						PtoRNorm:Normalise()
						local Rlv = rival:GetLinearVelocity()
						local RlvNorm = rival:GetLinearVelocity()
						RlvNorm:Normalise()
						-- check how parallel PtoRNorm and RlvNorm are
						local draftDot = math.abs(PtoRNorm:DotProduct(RlvNorm))
						if draftDot >= draftDotMin then
							--print("DRAFTING")
							local dotStrength = draftDot*(1/(1-draftDotMin))
							local distStrength = (maxDraftDist - PtoR:Length())/maxDraftDist
							local speedStrength = player:GetController():GetSpeedPercent()
							if speedStrength < 0.25 then
							    speedStrength = 0
							end
							local draftBoost = distStrength * (self.playerBoostsTD * dotStrength * speedStrength * draftBoostAmount)
							player:GetController():SetBoostPercent(player:GetController():GetBoostPercent()+draftBoost)
							player:GetController().draftAmount = draftBoost
						end
					end
				end
			end
		end
		self.playerBoostsTD = 0
	end

end


--This will respawn all the players and reset them
function RaceServer:RespawnAllPlayers()

	for index, player in ipairs(self.players)
	do
		GetServerManager():RespawnPlayer(player:GetUniqueID())
	end

	--Reset all the players on a respawn
	GetServerManager():ResetAllPlayers()

end


function RaceServer:SetPlayerLap(player, newLap)

	if newLap > NUM_LAPS then
		--This player finished the race
		self:SetPlayerState(player, self.raceStates.PLAYER_STATE_RACE_FINISHED)
		return
	end

	player.userData.lap = newLap
	self.param:SetIntData(player.userData.lap)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Lap", self.param)
	print("%%% Player " .. player:GetName() .. " is on lap: " .. tostring(player.userData.lap))

end


function RaceServer:SetPlayerCheckpoint(player, checkpointIndex)

	self.param:SetIntData(checkpointIndex)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Checkpoint", self.param)
    player.userData.checkpoint = checkpointIndex

    self:UpdatePlayerNodes()

    local leader = self.placementList[1]
    local i = 2
    while leader.userData.state == PLAYER_STATE_RACE_FINISHED and i <= #self.placementList do
        leader = self.placementList[i]
        i = i + 1
    end
    
    local leadNodeIndex = leader.userData.nodeIndex
    local playerNodeIndex = player.userData.nodeIndex
    if IsValid(player.userData.checkpoint) and IsValid(leadNodeIndex) and IsValid(playerNodeIndex) then
        
        local leadDist = (leader.userData.lap-1)*self.raceNodeManager:GetLapLength() + self.raceNodeManager:DistBetweenNodes(1,leadNodeIndex)
        local playerDist = (player.userData.lap-1)*self.raceNodeManager:GetLapLength() + self.raceNodeManager:DistBetweenNodes(1,playerNodeIndex)
        local distBehind = leadDist-playerDist
        
        if player.userData.place > 1 then
            local boostAmt = distBehind*0.01
            if boostAmt < 0.2 then
                boostAmt = 0.2
            end
            player:GetController():SetBoostPercent(player:GetController():GetBoostPercent()+boostAmt)

			self.weaponPicker = WeaponPickerFactory():CreateWeaponPicker("WeaponPickerRandom")
			GetWeaponManagerServer():GivePlayerWeapon(player, self.weaponPicker:PickWeapon())
        else
            -- player:GetController():SetBoostPercent(player:GetController():GetBoostPercent()+0.1)
        end
        
        --[[
        if leader.userData.state== PLAYER_STATE_RACE_FINISHED or not(leader.userData.lap == 1 and leader.userData.checkpoint == 1) then
            if player.userData.place > 1 then
                player:GetController():SetBoostPercent(player:GetController():GetBoostPercent()+(nodesBehind+1)*0.25)
            else
                player:GetController():SetBoostPercent(player:GetController():GetBoostPercent()+0.1)
            end
        end
        --]]
    end

end


function RaceServer:PlayerFinishedLap(playerParams)

	local playerID = playerParams:GetParameter(0, true):GetIntData()
	for index, player in ipairs(self.players)
	do
		if player:GetUniqueID() == playerID then
			print("%%% Player: " .. player:GetName() .. " finished a lap!")
			self:SetPlayerLap(player, player.userData.lap + 1)
			break
		end
	end

end


function RaceServer:PlayerEntersCheckpoint(playerParams)

    print("RaceServer:PlayerEntersCheckpoint")

	local playerID = playerParams:GetParameter(0, true):GetIntData()
	local checkpointIndex = playerParams:GetParameter(1, true):GetIntData()
	for index, player in ipairs(self.players)
	do
		if player:GetUniqueID() == playerID then
			self:SetPlayerCheckpoint(player, checkpointIndex)
			break
		end
	end

end


function RaceServer:PlayerHitInvalidCheckpoint(playerParams)

    print("RaceServer:PlayerHitInvalidCheckpoint")

	local playerID = playerParams:GetParameter(0, true):GetIntData()
	for index, player in ipairs(self.players)
	do
		if player:GetUniqueID() == playerID then
			self:RespawnPlayerAtLastNode(player:GetUniqueID())
			break
		end
	end

end


function RaceServer:UpdatePlayerNodes()
    for index, player in ipairs(self.players) do
        local playerCheckpoint = self.raceCheckpointManager:GetPlayerCheckpoint(player)
        if IsValid(playerCheckpoint) then
            local playerCP = self.raceCheckpointManager:GetCheckpoint(playerCheckpoint)     
            if IsValid(playerCP) then
                local nodeA, distA = self.raceNodeManager:GetNextClosestNode(playerCP, player:GetPosition())
                player.userData.nodeIndex = nodeA:Get():GetIndex()
            end
        end
    end
end


--Update the player places based on laps, checkpoints, and nodes
function RaceServer:UpdatePlayerPlaces()

	--This doesn't need to happen every frame
	if self.updatePlayerPlacesLimit:IsTimerUp() then
		self.updatePlayerPlacesLimit:Reset()
		--First clear out all places that haven't finished yet
		local clearIndex = 1
		while clearIndex < #self.placementList + 1 do
			local placedPlayer = self.placementList[clearIndex]
			if self:GetPlayerState(placedPlayer) ~= self.raceStates.PLAYER_STATE_RACE_FINISHED then
				table.remove(self.placementList, clearIndex)
				clearIndex = 1
			else
				clearIndex = clearIndex + 1
			end
		end

		--Sort the places out first
		for index, player in ipairs(self.players) do
			local placed = false
			for placeIndex, placedPlayer in ipairs(self.placementList) do
				--if the player has finished, break to the next
				if self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_RACE_FINISHED then
					placed = true
					break
				--if the placed player has finished, continue on
				elseif self:GetPlayerState(placedPlayer) == self.raceStates.PLAYER_STATE_RACE_FINISHED then
					--continue on
				--If this player is ahead of the placed player in laps, they are ahead
				elseif player.userData.lap > placedPlayer.userData.lap then
					table.insert(self.placementList, placeIndex, player)
					placed = true
					break
				--If this player is on the same lap as the placed player, check their checkpoints
				elseif player.userData.lap == placedPlayer.userData.lap then
					local playerCheckpoint = self.raceCheckpointManager:GetPlayerCheckpoint(player)
					local placedCheckpoint = self.raceCheckpointManager:GetPlayerCheckpoint(placedPlayer)

					--BRIAN TODO: Why does this happen???
					if playerCheckpoint == nil or placedCheckpoint == nil then
						break
					--If this player is ahead of the placed player in checkpoints, they are ahead
					elseif playerCheckpoint > placedCheckpoint then
						table.insert(self.placementList, placeIndex, player)
						placed = true
						break
					--checkpoint 0 indicates that neither player had reached a checkpoint yet
					elseif playerCheckpoint == 0 and placedCheckpoint == 0 then
						break
					--If the two players are within the same checkpoint, check their nodes
					elseif playerCheckpoint == placedCheckpoint then
						local playerCP = self.raceCheckpointManager:GetCheckpoint(playerCheckpoint)
						local nextCPindex = playerCheckpoint + 1
						if nextCPindex == self.raceCheckpointManager:GetNumCheckpoints() then
							nextCPindex = 1
						end
						local nextCP = self.raceCheckpointManager:GetCheckpoint(nextCPindex)

						--GetAheadPlayer returns the player who is ahead based on their nodes
						--BRIAN TODO: Testing checkpoint tests only, ignoring nodes as they are slow
						local aheadPlayer = self:GetAheadPlayer(player, placedPlayer, playerCP)
						--local aheadPlayer = self:GetPlayerClosestToCheckPoint(player, placedPlayer, playerCP)

						if aheadPlayer == player then
							table.insert(self.placementList, placeIndex, player)
							placed = true
							break
						end
					end
				end
			end

			if not placed then
				--If the player couldn't be placed ahead of another player, they are in last :(
				table.insert(self.placementList, player)
			end
		end

		for placeIndex, placedPlayer in ipairs(self.placementList) do
			--Only update if it has changed
			if placedPlayer.userData.place ~= placeIndex then
				placedPlayer.userData.place = placeIndex
				self.param:SetIntData(placedPlayer.userData.place)
				GetServerSystem():GetSendStateTable("Map"):SetState(tostring(placedPlayer:GetUniqueID()) .. "_Place", self.param)
			end
		end
	end

end


--GetAheadPlayer returns the player who is ahead based on their nodes within the same checkpoint
function RaceServer:GetAheadPlayer(playerA, playerB, checkpoint)

	local retPlayer = playerB

	local nodeA, distA = self.raceNodeManager:GetNextClosestNode(checkpoint, playerA:GetPosition())
	local nodeB, distB = self.raceNodeManager:GetNextClosestNode(checkpoint, playerB:GetPosition())

	--GetNextClosestNode returns nil if it doesn't have any checkpoints
	if not IsValid(nodeA) or not IsValid(nodeB) then
		retPlayer = playerA
		self.sameNode = false
	elseif nodeA:Get():GetIndex() > nodeB:Get():GetIndex() then
		retPlayer = playerA
		self.sameNode = false
	elseif nodeA:Get():GetIndex() < nodeB:Get():GetIndex() then
		retPlayer = playerB
		self.sameNode = false
	--If the two players are within the same node, check thier distance
	elseif nodeA:Get():GetIndex() == nodeB:Get():GetIndex() then
        if self.sameNode == false then
            --print("Both players in cp,node: "..checkpoint:Get():GetName()..","..nodeA:Get():GetIndex())
            self.sameNode = true 
        end
        --If the player is closer to the node, they are ahead
        if distA > distB then
            retPlayer = playerA
        end
	end

	return retPlayer

end


function RaceServer:GetPlayerClosestToCheckPoint(playerA, playerB, checkpoint)

	PUSH_PROFILE("RaceServer:GetPlayerClosestToCheckPoint(playerA, playerB, checkpoint)")

	pADist = playerA:GetPosition():SquaredDistance(checkpoint:GetPosition())
	pBDist = playerB:GetPosition():SquaredDistance(checkpoint:GetPosition())

	local closestPlayer = playerB
	if pADist < pBDist then
		closestPlayer = playerA
	end

	POP_PROFILE("RaceServer:GetPlayerClosestToCheckPoint(playerA, playerB, checkpoint)")

	return closestPlayer

end


function RaceServer:RespawnPlayerAtLastNode(playerID, reason)

	local player = GetPlayerManager():GetPlayerFromID(playerID)

    --Cancel any existng reset request
    for index, resetPlayer in pairs(self.resettingPlayers) do
		if resetPlayer[1] == player then
			table.remove(self.resettingPlayers, index)
			break
		end
	end

	local checkpointIndex = self.raceCheckpointManager:GetPlayerCheckpoint(player)
	--print("Resetting Player at Checkpoint #"..checkpointIndex)
	local playerCP = self.raceCheckpointManager:GetCheckpoint(checkpointIndex)
	if IsValid(playerCP) then
		local node, dist = self.raceNodeManager:GetNextClosestNode(playerCP, player:GetPosition(), false)
		--print("Resetting Player at Node #"..node:Get():GetIndex())
		local orien = WQuaternion()
		orien:FromNormal(node:Get():GetNormal())
		GetServerManager():RespawnPlayer(player:GetUniqueID(), node:GetPosition(), orien, reason)
	else
		--Player isn't at any checkpoint, just respawn them anywhere
		GetServerManager():RespawnPlayer(player:GetUniqueID(), nil, nil, nil, reason)
	end

	--Remove their boost and take their items away
	player:Reset()

end


function RaceServer:PlayerReset(resetParams)

	local playerControllerID = resetParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromObjectID(playerControllerID)
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


function RaceServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:AddPlayer(player)

end


function RaceServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:RemovePlayer(player)

	--At least 2 people are required if the game isn't already waiting
	if self:GetGameState() ~= self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS and self:GetNumberOfPlayers() < 2 then
		--Go back to waiting
		self:SetGameState(self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS)
	end

end

--RACESERVER CLASS END