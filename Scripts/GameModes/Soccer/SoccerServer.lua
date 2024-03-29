UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("SpawnPointManager", "Scripts/")
UseModule("SoccerStates", "Scripts\\GameModes\\Soccer\\")
UseModule("SoccerCollisionManager", "Scripts\\GameModes\\Soccer\\")

local WAIT_SOCCER_PLAYERS = 1
local setWait = function (value) WAIT_SOCCER_PLAYERS = value end
local getWait = function () return WAIT_SOCCER_PLAYERS end
DefineVar("WAIT_SOCCER_PLAYERS", setWait, getWait)

local SOCCER_PLAYER_RESET_TIMER = 3
local setReset = function (value) SOCCER_PLAYER_RESET_TIMER = value end
local getReset = function () return SOCCER_PLAYER_RESET_TIMER end
DefineVar("SOCCER_PLAYER_RESET_TIMER", setReset, getReset)

--300
local SOCCER_PLAY_TIMER = 300
local setPlayTimer = function (value) SOCCER_PLAY_TIMER = value end
local getPlayTimer = function () return SOCCER_PLAY_TIMER end
DefineVar("SOCCER_PLAY_TIMER", setPlayTimer, getPlayTimer)

--SOCCERSERVER CLASS START

class 'SoccerServer' (IGameMode)

function SoccerServer:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode SoccerServer in init")
	end

    GetServerManager():SetCurrentBotType("SoccerBot")

	--This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

	self.goalScoredSlot = self:CreateSlot("GoalScored", "GoalScored")
	self.soccerCollisionManager = SoccerCollisionManager(self.map)
	self.soccerCollisionManager:GetSignal("GoalScored"):Connect(self.goalScoredSlot)

	self.redScore = 0
	self.blueScore = 0

	self.redTeamPlayers = { }
	self.blueTeamPlayers = { }

	self.resettingPlayers = { }

	self:InitState()

	self.soccerStates = SoccerStates()

	--First wait for at least 1 person
	self.gameState = nil
	self:SetGameState(self.soccerStates.GS_WAIT_FOR_PLAYERS)

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

	self.soccerGoalScoredSignal = self:CreateSignal("SoccerGoalScored", GetServerSystem(), true)
	self.soccerGoalScoredParams = Parameters()

	--gameEndTime is the time which the current game ends
	self.gameEndTime = 0

	self.countdownStartTime = 0
	self.countdownActive = false
	self.countdownClock = WTimer()
	self.countdownTimer = 3

	--The clock to keep track of how long the winners have been shown
	self.showWinnersClock = WTimer()
	self.showWinnersTimer = 10

	--The clock to keep track of how long the game has been in the goal scored state
	self.goalScoredClock = WTimer()
	self.goalScoredTimer = 5

	--self.processClock = WTimer()

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


function SoccerServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("SoccerServer", "IGameMode", "Manages the soccer game mode")

end


function SoccerServer:InitGameMode()

end


function SoccerServer:UnInitGameMode()

	self:UnInitState()
	self:UnInitGame()

end


function SoccerServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState

	print("%%% New Soccer gamestate: " .. self.soccerStates:GameStateToString(self.gameState))

	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)

	--UnInit old state
	if oldState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.soccerStates.GS_COUNTDOWN then
		self:UnInitStateCountdown()
	elseif oldState == self.soccerStates.GS_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.soccerStates.GS_GOAL_SCORED then
		self:UnInitStateGoalScored()
	elseif oldState == self.soccerStates.GS_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:SetGameRunning(false)
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.soccerStates.GS_COUNTDOWN then
		self:SetGameRunning(true)
		self:InitStateCountdown()
	elseif self.gameState == self.soccerStates.GS_PLAY then
		self:SetGameRunning(true)
		self:InitStatePlay()
	elseif self.gameState == self.soccerStates.GS_GOAL_SCORED then
		self:SetGameRunning(true)
		self:InitStateGoalScored()
	elseif self.gameState == self.soccerStates.GS_SHOW_WINNERS then
		self:SetGameRunning(false)
		self:InitStateShowWinners()
	end

	--Update the states of all the current players based on this new game state
	self:UpdatePlayerStates()

end


function SoccerServer:GetGameState()

	return self.gameState

end


function SoccerServer:SetPlayerState(player, playerState)

	player.userData.state = playerState
	self.param:SetIntData(player.userData.state)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_State", self.param)
    --REDUNDANT
    self.param:SetStringData(player.userData.teamID)
    GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Team", self.param)
    
end


function SoccerServer:GetPlayerState()

	return player.userData.state

end

function SoccerServer:GetBall(index)
    if IsValid(self.soccerCollisionManager) then
        return self.soccerCollisionManager:GetSoccerBallByIndex(index)
    else
        return nil
    end
end

function SoccerServer:GetGoal(index)
    
    if IsValid(self.soccerCollisionManager) then
        return self.soccerCollisionManager:GetGoalByIndex(index)
    else
        return nil
    end
    
end

function SoccerServer:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	self.param:SetIntData(player.userData.score)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Score", self.param)

end


function SoccerServer:GetPlayerScore(player)

	return player.userData.score

end


function SoccerServer:SetPlayerTeam(player, teamID)

    print("Setting team: " .. tostring(teamID) .. " for player: " .. player:GetName() .. " with ID: " .. tostring(player:GetUniqueID()))

	player.userData.teamID = teamID
	self.param:SetStringData(player.userData.teamID)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Team", self.param)

end


function SoccerServer:GetPlayerTeam(player)

	return player.userData.teamID

end


--Update all the current player's states based on the current game state
function SoccerServer:UpdatePlayerStates()

	for index, player in ipairs(self.players)
	do
		self:UpdatePlayerState(player)
	end

end


--Update the passed in player's state based on the current game state
function SoccerServer:UpdatePlayerState(forPlayer)

	--Based on the current game state, set this player's state
	if self:GetGameState() == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the game to start
		self:SetPlayerState(forPlayer, self.soccerStates.PS_NOT_PLAYING)
        forPlayer:GetController():SetEnableControls(true)
	elseif self:GetGameState() == self.soccerStates.GS_COUNTDOWN then
		self:SetPlayerState(forPlayer, self.soccerStates.PS_NOT_PLAYING)
        forPlayer:GetController():SetEnableControls(false)
	elseif self:GetGameState() == self.soccerStates.GS_PLAY then
		--The game has started
		self:SetPlayerState(forPlayer, self.soccerStates.PS_PLAYING)
        forPlayer:GetController():SetEnableControls(true)
	elseif self:GetGameState() == self.soccerStates.GS_GOAL_SCORED then
		self:SetPlayerState(forPlayer, self.soccerStates.PS_NOT_PLAYING)
        forPlayer:GetController():SetEnableControls(true)
	elseif self:GetGameState() == self.soccerStates.GS_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(forPlayer, self.soccerStates.PS_SHOW_WINNERS)
		forPlayer:GetController():SetEnableControls(false)
	end

end

function SoccerServer:ResetTeams()
    
    print("SoccerServer:ResetTeams()")
    
    self.redTeamPlayers = {}
    self.blueTeamPlayers = {}
    
    for index, player in ipairs(self.players) do
		if #self.redTeamPlayers < #self.blueTeamPlayers then
            self:SetPlayerTeam(player, "Red")
            table.insert(self.redTeamPlayers, player)
        else
            self:SetPlayerTeam(player, "Blue")
            table.insert(self.blueTeamPlayers, player)
        end
    end
    
    self:PrintTeams()
end

function SoccerServer:PrintTeams()
    
    print("SoccerServer:Teams--------------")
    
    for index, player in ipairs(self.blueTeamPlayers) do
		print(index..". BLUE: "..player:GetName())
    end
    
    for index, player in ipairs(self.redTeamPlayers) do
		print(index..".  RED: "..player:GetName())
    end
    
end

function SoccerServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == addPlayer:GetUniqueID() then
			print("%%% Attempt was made in SoccerServer:AddPlayer() to add an existing player")
			return
		end
	end

	
    
    print("Decide team for new player: "..addPlayer:GetName())
	--Add this player to the team with less people
	local team = nil
	if #self.redTeamPlayers < #self.blueTeamPlayers then
		team = "Red"
        --self:SetPlayerTeam(addPlayer, "Red")
		table.insert(self.redTeamPlayers, addPlayer)
	else --#self.blueTeamPlayers < #self.redTeamPlayers then
		team = "Blue"
        --self:SetPlayerTeam(addPlayer, "Blue")
		table.insert(self.blueTeamPlayers, addPlayer)
	end

    --Init this player's state first
	self:InitPlayerState(addPlayer)

	--Spawn a controller for this player
	local spawnPos, spawnOrien = GetSpawnPointManager():GetFreeSpawnPoint(team)
	if spawnPos == nil or spawnOrien == nil then
		spawnPos = WVector3()
		spawnOrien = WQuaternion()
	end

	--self:SpawnPlayerController(addPlayer, CreateBallController, spawnPos, spawnOrien)
	self:SpawnPlayerController(addPlayer, CreateKartController, spawnPos, spawnOrien)

    self:SetPlayerTeam(addPlayer, team)

	--We want to know when the player is reset so we can respawn them with a delay
	addPlayer:GetSignal("Resetting", true):Connect(self.playerResetSlot)

    addPlayer:GetController():SetEnableControls(false)
    
    
    

    --[[
	--This will set this player's state based on the current game state
	if self:GetGameState() == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the game to start
		self:SetPlayerState(addPlayer, self.soccerStates.PS_NOT_PLAYING)

	elseif self:GetGameState() == self.soccerStates.GS_COUNTDOWN then
		self:SetPlayerState(addPlayer, self.soccerStates.PS_NOT_PLAYING)

	elseif self:GetGameState() == self.soccerStates.GS_PLAY then
		self:SetPlayerState(addPlayer, self.soccerStates.PS_PLAYING)

	elseif self:GetGameState() == self.soccerStates.GS_GOAL_SCORED then
		self:SetPlayerState(addPlayer, self.soccerStates.PS_NOT_PLAYING)

	elseif self:GetGameState() == self.soccerStates.GS_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(addPlayer, self.soccerStates.PS_SHOW_WINNERS)
	end
	--]]
    self:UpdatePlayerState(addPlayer)
	table.insert(self.players, addPlayer)

    self:PrintTeams()

end


function SoccerServer:RemovePlayer(removePlayer)

	local teamRemoveFunc = 
		function(teamTable, removeTeamPlayer)
			for index, player in ipairs(teamTable) do
				if player:GetUniqueID() == removeTeamPlayer:GetUniqueID() then
					table.remove(teamTable, index)
					return
				end
			end
		end

	if removePlayer.userData.teamID == "Red" then
		teamRemoveFunc(self.redTeamPlayers, removePlayer)
	else
		teamRemoveFunc(self.blueTeamPlayers, removePlayer)
	end

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
		print("%%% Attempt was made in SoccerServer:RemovePlayer() to remove a player we don't know about")
	end

	--self:DestroyPlayerController(removePlayer, DestroyBallController)
	self:DestroyPlayerController(removePlayer, DestroyKartController)

end


function SoccerServer:GetNumberOfPlayers()

	return #self.players

end


function SoccerServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("CountdownStartTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("BlueScore")
	GetServerSystem():GetSendStateTable("Map"):NewState("RedScore")

end


function SoccerServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("CountdownStartTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("BlueScore")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RedScore")

end


function SoccerServer:InitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Team")

	--Init the data for this client
	player.userData.state = nil
	player.userData.score = 0
	player.userData.teamID = ""

end


function SoccerServer:UnInitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Team")

end


function SoccerServer:LoadMapSettings(fromMap)

	--No settings to load yet

end


function SoccerServer:InitGame()

	--Nothing to Init yet

end


function SoccerServer:UnInitGame()

	--Nothing to UnInit yet

end


function SoccerServer:Process()

	local timeDiff = GetFrameTime()

	if self.gameState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers()
	elseif self.gameState == self.soccerStates.GS_COUNTDOWN then
		self:ProcessStateCountdown()
	elseif self.gameState == self.soccerStates.GS_PLAY then
		self:ProcessStatePlay()
	elseif self.gameState == self.soccerStates.GS_GOAL_SCORED then
		self:ProcessStateGoalScored()
	elseif self.gameState == self.soccerStates.GS_SHOW_WINNERS then
		self:ProcessStateShowWinners()
	end

	self:ProcessResettingPlayers()
	self:ProcessPlayerBoosts(timeDiff)

	self.soccerCollisionManager:Process()

end


function SoccerServer:ProcessResettingPlayers()

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock
		if resetPlayer[2]:GetTimeSeconds() > SOCCER_PLAYER_RESET_TIMER then
			--Index 1 is the actual player object
			GetServerManager():RespawnPlayer(resetPlayer[1]:GetUniqueID(), nil, nil, resetPlayer[1].userData.teamID)
			table.remove(self.resettingPlayers, index)
			--If there are more to be reset, we will catch them next time
			return
		end
	end

end


function SoccerServer:ProcessPlayerBoosts(timeDiff)

	--Boost can be given to the players in any manner here
	for playerIndex, player in ipairs(self.players) do
		local newBoostPercent = player:GetController():GetBoostPercent()
		local boostGrowth = (player:GetController():GetBoostBPS() / 4) * timeDiff
		newBoostPercent = newBoostPercent + boostGrowth
		player:GetController():SetBoostPercent(newBoostPercent)
	end

end


function SoccerServer:InitStateWaitForPlayers()

	self:ResetTeamScores()

end


function SoccerServer:UnInitStateWaitForPlayers()

	--Nothing to uninit here

end


function SoccerServer:InitStateCountdown()

	--Notify the clients what time the countdown will start at so we are all in sync
	self.countdownStartTime = GetServerSystem():GetTime() + 6
	print("SoccerServer:InitStateCountdown() countdownStartTime = "..self.countdownStartTime)
	self.param:SetFloatData(self.countdownStartTime)
	GetServerSystem():GetSendStateTable("Map"):SetState("CountdownStartTime", self.param)

	--The countdown isn't active until the game start time has passed
	self.countdownActive = false

	--Remove all the players boost at the start of a new game
	for index, player in ipairs(self.players) do
		player:GetController():SetBoostPercent(0)
	end

	self:RespawnAllPlayers()
	--Disable their controls
	self:SetEnablePlayerControls(false)

	--Remove all weapons from the field
	--Passing in nil removes all weapons
	GetWeaponManagerServer():RemoveWeapons(nil)

	self.soccerCollisionManager:RespawnBalls()

end


function SoccerServer:UnInitStateCountdown()

	--Nothing to uninit here

end


function SoccerServer:InitStatePlay()

	--Players can control their karts again
	self:SetEnablePlayerControls(true)

end


function SoccerServer:UnInitStatePlay()

	--Nothing to uninit here

end


function SoccerServer:InitStateGoalScored()

	print("### Called self.goalScoredClock:Reset()")
	self.goalScoredClock:Reset()

end


function SoccerServer:UnInitStateGoalScored()

	--Nothing to uninit here

end


function SoccerServer:InitStateShowWinners()

	--This clock keeps track of how much time has been spent in the show winners state
	self.showWinnersClock:Reset()

	self:SetEnablePlayerControls(false)

	for index, player in ipairs(self.players) do
		self:SetPlayerScore(player, 0)
		player:SetControllerEnabled(false)
	end

end


function SoccerServer:UnInitStateShowWinners()

	--Reset all the players scores
	for index, player in ipairs(self.players) do
		self:SetPlayerScore(player, 0)
		player:SetControllerEnabled(true)
	end

	self:ResetTeamScores()
	self:ResetTeams()

end


--Waiting for more players
function SoccerServer:ProcessStateWaitForPlayers()

	--At least WAIT_SOCCER_PLAYERS players are required to start the game
	if self:GetNumberOfPlayers() >= WAIT_SOCCER_PLAYERS then
		--We have at least WAIT_SOCCER_PLAYERS players, start the game
		self:SetGameState(self.soccerStates.GS_COUNTDOWN)
		--Find the next game end time
		self:GenerateGameEndTime()
	end

end


function SoccerServer:ProcessStateCountdown()

	--The countdown doesn't start until after the time in self.countdownStartTime
	if GetServerSystem():GetTime() > self.countdownStartTime and not self.countdownActive then
		self.countdownClock:Reset()
		self.countdownActive = true
	end

	if self.countdownActive then
		if GetServerSystem():GetTime() > self.countdownStartTime + self.countdownTimer then
			--Countdown finished
			self:SetGameState(self.soccerStates.GS_PLAY)
		end
	end

end


function SoccerServer:ProcessStatePlay()

	--Check if the game is over based on time passed
	if GetServerSystem():GetTime() >= self.gameEndTime and self.redScore ~= self.blueScore then
		self:SetGameState(self.soccerStates.GS_SHOW_WINNERS)
	end

end


function SoccerServer:ProcessStateGoalScored()

    if GetServerSystem():GetTime() >= self.gameEndTime and self.redScore ~= self.blueScore then
		self:SetGameState(self.soccerStates.GS_SHOW_WINNERS)
    elseif self.goalScoredClock:GetTimeSeconds() > self.goalScoredTimer then
        if GetServerSystem():GetTime() >= self.gameEndTime then
		    self:SetGameState(self.soccerStates.GS_SHOW_WINNERS)
	    else
		    self:SetGameState(self.soccerStates.GS_COUNTDOWN)
		end
	end

end


function SoccerServer:ProcessStateShowWinners()

	--After giving the clients time to review the winners list, start the countdown again
	if self.showWinnersClock:GetTimeSeconds() > self.showWinnersTimer then
		self:SetGameState(self.soccerStates.GS_COUNTDOWN)
		--Find the next game end time
		self:GenerateGameEndTime()
	end

end


function SoccerServer:GenerateGameEndTime()

	self.gameEndTime = GetServerSystem():GetTime() + SOCCER_PLAY_TIMER
	--Notify the clients when the game will end
	self.param:SetFloatData(self.gameEndTime)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameEndTime", self.param)

end


--This will respawn all the players and reset them
function SoccerServer:RespawnAllPlayers()

	for index, player in ipairs(self.players)
	do
		GetServerManager():RespawnPlayer(player:GetUniqueID(), nil, nil, player.userData.teamID)
	end

	GetServerManager():ResetAllPlayers()

end


--Enable or disable the players ability to control their karts
function SoccerServer:SetEnablePlayerControls(enabled)

	for index, player in ipairs(self.players)
	do
		local controller = player:GetController()
		controller:SetEnableControls(enabled)
	end

end


function SoccerServer:SetRedScore(newScore)

	self.redScore = newScore
	self.param:SetIntData(self.redScore)
	GetServerSystem():GetSendStateTable("Map"):SetState("RedScore", self.param)

end


function SoccerServer:GetRedScore()

	return self.redScore

end


function SoccerServer:SetBlueScore(newScore)

	self.blueScore = newScore
	self.param:SetIntData(self.blueScore)
	GetServerSystem():GetSendStateTable("Map"):SetState("BlueScore", self.param)

end


function SoccerServer:GetBlueScore()

	return self.blueScore

end


function SoccerServer:ResetTeamScores()

	self:SetRedScore(0)
	self:SetBlueScore(0)

end


function SoccerServer:GoalScored(goalParams)

	--Goals are only scored while the game is being played
	if self.gameState == self.soccerStates.GS_PLAY then
		--Grab the info about this event
		local teamID = goalParams:GetParameter("TeamID", true):GetStringData()
		local goalID = goalParams:GetParameter("GoalID", true):GetIntData()

		print("Scored into team " .. teamID .. " goal!")

		--Change game states
		self:SetGameState(self.soccerStates.GS_GOAL_SCORED)

		--Update the score
		if teamID == "Red" then
			self:SetBlueScore(self:GetBlueScore() + 1)
		elseif teamID == "Blue" then
			self:SetRedScore(self:GetRedScore() + 1)
		end

		--Emit the goal scored signal
		self.soccerGoalScoredParams:GetOrCreateParameter("TeamID"):SetStringData(teamID)
		self.soccerGoalScoredParams:GetOrCreateParameter("GoalID"):SetIntData(goalID)
		self.soccerGoalScoredSignal:Emit(self.soccerGoalScoredParams)
	end

end


function SoccerServer:PlayerReset(resetParams)

	--A player pressed the reset key, we want to add a delay before they actually
	--get reset so they can't use it to cheat
	local playerKartID = resetParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromObjectID(playerKartID)
	--Make sure this player isn't resetting already
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


function SoccerServer:PlayerRespawned(respawnParams)

	local playerID = respawnParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	player:Reset()

end


function SoccerServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:AddPlayer(player)

end


function SoccerServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:RemovePlayer(player)

	--At least WAIT_SOCCER_PLAYERS players are required for there to be any kind of game
	if self:GetGameState() ~= self.soccerStates.GS_WAIT_FOR_PLAYERS and self:GetNumberOfPlayers() < WAIT_SOCCER_PLAYERS then
		--Go back to waiting
		self:SetGameState(self.soccerStates.GS_WAIT_FOR_PLAYERS)
	end

end


function SoccerServer:GetProcessSlot()

	return self.processSlot

end

--SOCCERSERVER CLASS END