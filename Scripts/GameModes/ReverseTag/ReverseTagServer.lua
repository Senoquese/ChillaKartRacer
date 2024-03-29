UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("SpawnPointManager", "Scripts/")
UseModule("ReverseTagStates", "Scripts\\GameModes\\ReverseTag\\")

local WAIT_TAG_PLAYERS = 0
local setWait = function (value) WAIT_TAG_PLAYERS = value end
local getWait = function () return WAIT_TAG_PLAYERS end
DefineVar("WAIT_TAG_PLAYERS", setWait, getWait)

local TAG_WIN_SCORE = 150
local setWinScore = function (value) TAG_WIN_SCORE = value end
local getWinScore = function () return TAG_WIN_SCORE end
DefineVar("TAG_WIN_SCORE", setWinScore, getWinScore)

local TAG_PLAYER_RESET_TIMER = 3
local setReset = function (value) TAG_PLAYER_RESET_TIMER = value end
local getReset = function () return TAG_PLAYER_RESET_TIMER end
DefineVar("TAG_PLAYER_RESET_TIMER", setReset, getReset)

local TAG_BOOST_GROWTH = 4
local setTagBoost = function (value) TAG_BOOST_GROWTH = value end
local getTagBoost = function () return TAG_BOOST_GROWTH end
DefineVar("TAG_BOOST_GROWTH", setTagBoost, getTagBoost)

local TAG_SWITCH_MIN = 45
local TAG_SWITCH_MAX = 75

local IT_PENALTY_TICK = -5
local RESPAWN_PENALTY = -10

--REVERSETAGSERVER CLASS START

class 'ReverseTagServer' (IGameMode)

function ReverseTagServer:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode ReverseTagServer in init")
	end

    --BRIAN TODO: Test code only, this AI type is broke right now
	GetServerManager():SetCurrentBotType("ReverseTagBot")

	--This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

	self.resettingPlayers = { }

	self.invulTimer = 3
	self:InitState()

	self.tagStates = ReverseTagStates()

	--First wait for at least 1 person
	self.gameState = nil
	self:SetGameState(self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS)

	self.invulStartTime = 0

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

	--This is emitted when a new player is IT with their ID
	self.playerITSignal = self:CreateSignal("PlayerIT")
	self.playerITParams = Parameters()

	--Which player is IT? this will tell us
	self.ITPlayer = nil

	--How much time to wait before adding more points
	self.addPointsTimer = 1
	self.addPointsClock = WTimer()
	--How many points to add to the score per addPointsTimer
	self.pointsPerTime = 10
	--How long to wait before switching play modes
	self.playSwitchMinSeconds = TAG_SWITCH_MIN
	self.playSwitchMaxSeconds = TAG_SWITCH_MAX
	self.playSwitchTimer = math.random(self.playSwitchMinSeconds,self.playSwitchMaxSeconds)
	self.playSwitchClock = WTimer()
	--default the map extents to 70 in case the map doesnt define any
	self.mapExtents = 70
	--The clock to keep track of how long the winners have been shown
	self.showWinnersClock = WTimer()
	self.showWinnersTimer = 10

    --Need to keep track of all the players inside the IT sensor
	self.playersInItZone = { }
	--Measures how long a player has not been IT
	self.playerNotITTimer = WTimer(0.25)

	self.ITRespawnPos = WVector3()
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


function ReverseTagServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("ReverseTagServer", "IGameMode", "Manages the reverse tag game mode")

end


function ReverseTagServer:InitGameMode()

end


function ReverseTagServer:UnInitGameMode()

	self:UnInitState()
	self:UnInitGame()

end


function ReverseTagServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState

	print("%%% New Tag gamestate: " .. self.tagStates:GameStateToString(self.gameState))

	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)

	--UnInit old state
	if oldState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.tagStates.GAME_STATE_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		--self:SetGameRunning(false)
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.tagStates.GAME_STATE_PLAY and oldState == GAME_STATE_SHOW_WINNERS then
		--self:SetGameRunning(true)
		self:InitStatePlay()
	elseif self.gameState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		--self:SetGameRunning(false)
		self:InitStateShowWinners()
	end

    self:SetGameRunning(self.gameState == self.tagStates.GAME_STATE_PLAY or self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE)

	--Update the states of all the current players based on this new game state
	self:UpdatePlayerStates()

end


function ReverseTagServer:GetGameState()

	return self.gameState

end


function ReverseTagServer:SetPlayerState(player, playerState)

	player.userData.state = playerState
	self.param:SetIntData(player.userData.state)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_State", self.param)

end


function ReverseTagServer:GetPlayerScore(player)

	return player.userData.score

end


function ReverseTagServer:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	self.param:SetIntData(player.userData.score)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Score", self.param)

end


function ReverseTagServer:GetPlayerState()

	return player.userData.state

end


--Update all the current player's states based on the current game state
function ReverseTagServer:UpdatePlayerStates()

	for index, player in ipairs(self.players)
	do
		self:UpdatePlayerState(player)
	end

end


--Update the passed in player's state based on the current game state
function ReverseTagServer:UpdatePlayerState(forPlayer)

	--Based on the current game state, set this player's state
	if self:GetGameState() == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the game to start
		self:SetPlayerState(forPlayer, self.tagStates.PLAYER_STATE_NOT_IT)

	--elseif self:GetGameState() == self.tagStates.GAME_STATE_PLAY
		--The game has started
		--self:SetPlayerState(forPlayer, self.tagStates.PLAYER_STATE_NOT_IT)

	elseif self:GetGameState() == self.tagStates.GAME_STATE_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(forPlayer, self.tagStates.PLAYER_STATE_SHOW_WINNERS)
		self:SetPlayerState(forPlayer, self.tagStates.PLAYER_STATE_NOT_IT)
	end

end


function ReverseTagServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == addPlayer:GetUniqueID() then
			print("%%% Attempt was made in ReverseTagServer:AddPlayer() to add an existing player")
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

	--Init this player's state
	self:InitPlayerState(addPlayer)

	--This will set this player's state based on the current game state
	if self:GetGameState() == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the game to start
		self:SetPlayerState(addPlayer, self.tagStates.PLAYER_STATE_NOT_IT)

	elseif self:GetGameState() == self.tagStates.GAME_STATE_PLAY then
		self:SetPlayerState(addPlayer, self.tagStates.PLAYER_STATE_NOT_IT)

	elseif self:GetGameState() == self.tagStates.GAME_STATE_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(addPlayer, self.tagStates.PLAYER_STATE_SHOW_WINNERS)
	end

	table.insert(self.players, addPlayer)

end


function ReverseTagServer:RemovePlayer(removePlayer)

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
		print("%%% Attempt was made in ReverseTagServer:RemovePlayer() to remove a player we don't know about")
	end

	--self:DestroyPlayerController(removePlayer, DestroyBallController)
	self:DestroyPlayerController(removePlayer, DestroyKartController)

end


function ReverseTagServer:GetNumberOfPlayers()

	return #self.players

end


function ReverseTagServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("InvulStartTime")

	--Tag settings
	GetServerSystem():GetSendStateTable("Map"):NewState("InvulTimer")
	self.param:SetIntData(self.invulTimer)
	GetServerSystem():GetSendStateTable("Map"):SetState("InvulTimer", self.param)
	print("%%% InvulTimer: " .. tostring(self.invulTimer))

    GetServerSystem():GetSendStateTable("Map"):NewState("TagWinScore")
	self.param:SetIntData(TAG_WIN_SCORE)
	GetServerSystem():GetSendStateTable("Map"):SetState("TagWinScore", self.param)
	print("%%% TagWinScore: " .. tostring(TAG_WIN_SCORE))

end


function ReverseTagServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("InvulStartTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("InvulTimer")

end


function ReverseTagServer:InitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Score")

	--Init the data for this client
	player.userData.state = nil
	player.userData.score = 0

end


function ReverseTagServer:UnInitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Score")

end


function ReverseTagServer:LoadMapSettings(fromMap)

	--Map Extents
	local mapExtentsParam = self.map:GetSetting("MapExtents", false)
	if IsValid(mapExtentsParam) then
		self.mapExtents = mapExtentsParam:GetFloatData()
	end

	--IT Spawn Position
	local ITSpawnPos = self.map:GetSetting("ITSpawnPosition", false)
	if IsValid(ITSpawnPos) then
	    self.ITRespawnPos = ITSpawnPos:GetWVector3Data()
	    if IsValid(self.ITSensor) then
			self.ITSensor:SetPosition(self.ITRespawnPos)
		end
	    print("self.ITRespawnPos: " .. tostring(self.ITRespawnPos))
	end

end


function ReverseTagServer:InitGame()

    print("Init Game")

	self.objectHitTagSlot = self:CreateSlot("ObjectHitTag", "ObjectHitTag")
	self.objectEndHitTagSlot = self:CreateSlot("ObjectEndHitTag", "ObjectEndHitTag")

	self.ITSensor = BulletSensor()
	self.ITSensor:SetName("ITSensor")
	local params = Parameters()
	params:AddParameter(Parameter("Shape", "Cube"))
	params:AddParameter(Parameter("Dimensions", WVector3(10, 10, 10)))
	params:AddParameter(Parameter("Position", self.ITRespawnPos))
	self.ITSensor:Init(params)

	self.ITSensor:GetSignal("StartCollision", true):Connect(self.objectHitTagSlot)
	self.ITSensor:GetSignal("EndCollision", true):Connect(self.objectEndHitTagSlot)

	--Connect to the signal to receive info about collisions (for the Vehicle vs Vehicle collisions)
	self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")
	self.collisionEndSlot = self:CreateSlot("BulletCollisionEnd", "BulletCollisionEnd")
	GetBulletPhysicsSystem():GetSignal("StartCollision", true):Connect(self.collisionStartSlot)
	GetBulletPhysicsSystem():GetSignal("EndCollision", true):Connect(self.collisionEndSlot)

end


function ReverseTagServer:UnInitGame()

	if IsValid(self.ITSensor) then
		self.ITSensor:UnInit()
		self.ITSensor = nil
	end

end


function ReverseTagServer:Process()

	local frameTime = GetFrameTime()

	self.ITSensor:Process(frameTime)

	if self.gameState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers(frameTime)
	elseif self.gameState == self.tagStates.GAME_STATE_PLAY or self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
		self:ProcessStatePlay(frameTime)
	elseif self.gameState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
	end

	self:ProcessResettingPlayers(frameTime)
	self:ProcessPlayerBoosts(frameTime)

    --When there is no IT player and there are players in the IT zone, give IT to one of them
    if self:GetIT() == nil and self.playerNotITTimer:IsTimerUp() then
        for index, playerObjID in ipairs(self.playersInItZone) do
            local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(playerObjID)
            if IsValid(hitPlayer) then
                self:SetIT(hitPlayer)
                break
            end
        end
    end

end


function ReverseTagServer:ProcessResettingPlayers(frameTime)

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock
		if resetPlayer[2]:GetTimeSeconds() > TAG_PLAYER_RESET_TIMER then
			--Index 1 is the actual player object
			GetServerManager():RespawnPlayer(resetPlayer[1]:GetUniqueID())
			table.remove(self.resettingPlayers, index)
			--If there are more to be reset, we will catch them next time
			return
		end
	end

end


function ReverseTagServer:ProcessPlayerBoosts(frameTime)

	for playerIndex, player in ipairs(self.players) do
	    if IsValid(player:GetController()) then
	        --[[
            local newBoostPercent = player:GetController():GetBoostPercent()
            local boostGrowth = (player:GetController():GetBoostBPS() / TAG_BOOST_GROWTH) * frameTime
            --The IT player gets half as much boost as everyone else
            if self.ITPlayer == player then
                boostGrowth = boostGrowth / 4
            end
            newBoostPercent = newBoostPercent + boostGrowth
            player:GetController():SetBoostPercent(newBoostPercent)
            --]]
            if self.ITPlayer == player then
                if self.gameState == self.tagStates.GAME_STATE_PLAY then
                    player:GetController():SetBoostPercent(0)
                elseif self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
                    player:GetController():SetBoostPercent(100)
                end
            else
                if self.gameState == self.tagStates.GAME_STATE_PLAY then
                    player:GetController():SetBoostPercent(100)
                elseif self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
                    player:GetController():SetBoostPercent(0)
                end
            end
        end
	end

end


function ReverseTagServer:InitStateWaitForPlayers()

	--Nothing to init here

end


function ReverseTagServer:UnInitStateWaitForPlayers()

	--Nothing to uninit here

end


function ReverseTagServer:InitStatePlay()

	--Reset all the players scores
	for index, player in ipairs(self.players)
	do
		self:SetPlayerScore(player, 0)
	end

	--Notify the base IGameMode that the game has reset
	self:GameReset()

end


function ReverseTagServer:UnInitStatePlay()

	--Nothing to uninit here

end


function ReverseTagServer:InitStateShowWinners()
    print("InitStateShowWinners()")
	self.showWinnersClock:Reset()

	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(false)
		player:SetControllerEnabled(false)
		self:SetPlayerScore(player,0)
	end

end


function ReverseTagServer:UnInitStateShowWinners()

	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(true)
		player:SetControllerEnabled(true)
	end

    -- clear items
    GetWeaponManagerServer():RemoveWeapons(nil)

end


--Waiting for more players
function ReverseTagServer:ProcessStateWaitForPlayers(frameTime)

	--At least WAIT_TAG_PLAYERS players are required to start the game
	if self:GetNumberOfPlayers() > WAIT_TAG_PLAYERS then
		--We have at least WAIT_TAG_PLAYERS players, start the countdown
		self:SetGameState(self.tagStates.GAME_STATE_PLAY)
	end

end


function ReverseTagServer:ProcessStatePlay(frameTime)

	if self:GetIT() then
		if self.addPointsClock:GetTimeSeconds() > self.addPointsTimer then
			--Reset clockno,
			self.addPointsClock:Reset()
			--Keep track of scores
			--Get players distance to origin, used in calculating points
			local distance = 1
			local playerPosition = self:GetIT():GetPosition()
			distance = playerPosition:Distance(self.ITRespawnPos)
			--Clamp it, dont go below 1
			if distance < 1 then
				distance = 1
			end
			--Clamp it, dont go above self.mapExtents - 1
			--they will always get at least get one point
			if distance > self.mapExtents then
				distance = self.mapExtents - 1
			end
			--Calculate the percent based on the distance
			distance = distance / self.mapExtents
			--Reverse the percentage
			--distance = 1 - distance
			
			-- TEST
			self.addPointsTimer = 0.2 + distance
			
			local points = math.abs(--[[self.pointsPerTime * distance--]]1)
			if self:GetGameState() == self.tagStates.GAME_STATE_PLAY_REVERSE then
			    points = IT_PENALTY_TICK
			    self.addPointsTimer = 3
			end
			if self:GetPlayerScore(self:GetIT()) < 0 then
			    self:SetPlayerScore(self:GetIT(), 0)
			end
            local newScore = math.floor(self:GetPlayerScore(self:GetIT()) + points)
			if newScore < 0 and self:GetGameState() == self.tagStates.GAME_STATE_PLAY_REVERSE then
			    self:SetPlayerScore(self:GetIT(), 0)
			    -- Score has drained!
			    self:SetIT(nil)
			    self.playSwitchClock:Reset()
			    self.playSwitchTimer = math.random(self.playSwitchMinSeconds,self.playSwitchMaxSeconds)
			    self:SetGameState(self.tagStates.GAME_STATE_PLAY)
			    newScore = 0
			else
                self:SetPlayerScore(self:GetIT(), newScore)
            end
		end
		-- test whether to flip game modes
		if self.playSwitchClock:GetTimeSeconds() > self.playSwitchTimer then
		    self.playSwitchClock:Reset()
		    if self:GetGameState() == self.tagStates.GAME_STATE_PLAY then
		        self.playSwitchTimer = math.random(self.playSwitchMinSeconds/2,self.playSwitchMaxSeconds/2)
		        self:SetGameState(self.tagStates.GAME_STATE_PLAY_REVERSE)
		    else
		        self.playSwitchTimer = math.random(self.playSwitchMinSeconds,self.playSwitchMaxSeconds)
		        self:SetGameState(self.tagStates.GAME_STATE_PLAY)
		    end
		end
	end

	--Find out if the game is over
	local gameOver = false

	for index, player in ipairs(self.players) do
		--If at least one player is over the TAG_WIN_SCORE, game over
		local playerScore = self:GetPlayerScore(player)
		if playerScore > TAG_WIN_SCORE or playerScore == TAG_WIN_SCORE then
			gameOver = true
			break
		end
	end

	if gameOver then
		self:SetGameState(self.tagStates.GAME_STATE_SHOW_WINNERS)
	end

end


function ReverseTagServer:ProcessStateShowWinners(frameTime)

	--After giving the clients time to review the winners list, start the countdown again
	if self.showWinnersClock:GetTimeSeconds() > self.showWinnersTimer then
		self:RespawnAllPlayers()
		self:SetGameState(self.tagStates.GAME_STATE_PLAY)
	end

end


--This will respawn all the players and reset them
function ReverseTagServer:RespawnAllPlayers()

    self:SetGameState(self.tagStates.GAME_STATE_PLAY)

	for index, player in ipairs(self.players)
	do
		GetServerManager():RespawnPlayer(player:GetUniqueID())
	end

	GetServerManager():ResetAllPlayers()

end


function ReverseTagServer:ObjectHitTag(sensorParams)

    local collideObjectID = sensorParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)

    if IsValid(hitPlayer) then
        table.insert(self.playersInItZone, collideObjectID)
	    --The hit sensor is only enabled if no player is IT
	    if self:GetIT() == nil then
		    --This player is the new IT!
			self:SetIT(hitPlayer)
		end
	end

end


function ReverseTagServer:ObjectEndHitTag(sensorParams)

    local collideObjectID = sensorParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	if IsValid(hitPlayer) then
	    for index, playerObjID in ipairs(self.playersInItZone) do
	        if playerObjID == collideObjectID then
	            table.remove(self.playersInItZone, index)
	            break
	        end
	    end
	end

end


function ReverseTagServer:BulletCollisionStart(collParams)

	local objectAID = collParams:GetParameter("ObjectAID", true):GetIntData()
	local objectBID = collParams:GetParameter("ObjectBID", true):GetIntData()

	local playerA = nil
	local playerB = nil
	for index, player in ipairs(self.players) do
		--Is the enter object a controller?
		if player:GetController():DoesOwn(objectAID) then
			playerA = player
		end
	end
	for index, player in ipairs(self.players) do
		--Is the enter object a controller?
		if player:GetController():DoesOwn(objectBID) then
			playerB = player
		end
	end

	--Only do the tag checks if the tag check timer is up
	--and if a collision object isn't the world
	if not IsValid(self:GetIT()) or (GetServerSystem():GetTime() > self.invulStartTime + self.invulTimer) and
	   IsValid(playerA) and IsValid(playerB) then
		--Is playerA IT?
		if self:GetIT() and self:GetIT():GetUniqueID() == playerA:GetUniqueID() then
			--playerB is IT!
			self:SetIT(playerB)
		--Is playerB IT?
		elseif self:GetIT() and self:GetIT():GetUniqueID() == playerB:GetUniqueID() then
			--playerA is IT!
			self:SetIT(playerA)
		end
	end

end


function ReverseTagServer:BulletCollisionEnd(collParams)

end


function ReverseTagServer:SetIT(newITPlayer)

    --flip game mode if nobody is it
    if not newITPlayer then
        self.playerNotITTimer:Reset()
        if self:GetGameState() == self.tagStates.GAME_STATE_PLAY_REVERSE then
		    self:SetGameState(self.tagStates.GAME_STATE_PLAY)
		end   
    end

	--First, the old player is no longer IT
	if IsValid(self.ITPlayer) then
		self:SetPlayerState(self.ITPlayer, self.tagStates.PLAYER_STATE_NOT_IT)
	else
	    -- IT is being picked up
	    self.playSwitchClock:Reset()
    end

	self.ITPlayer = newITPlayer

	local ITID = 0
	if self.ITPlayer then
		ITID = self.ITPlayer:GetUniqueID()
		self:SetPlayerState(self.ITPlayer, self.tagStates.PLAYER_STATE_IT)
		GetConsole():Print("Player: " .. self.ITPlayer:GetName() .. " is IT!!")
		--Reset the invul timer
		self.invulStartTime = GetServerSystem():GetTime()
		self.param:SetFloatData(self.invulStartTime)
		GetServerSystem():GetSendStateTable("Map"):SetState("InvulStartTime", self.param)
	else
		GetConsole():Print("Nobody is IT")
		-- Switch back to GAME_STATE_PLAY
	end

	self.playerITParams:GetOrCreateParameter(0):SetIntData(ITID)
	self.playerITSignal:Emit(self.playerITParams)

end


--Will return the Player that is currently IT, nil if nobody is IT
function ReverseTagServer:GetIT()

	return self.ITPlayer

end


function ReverseTagServer:PlayerReset(resetParams)

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


function ReverseTagServer:PlayerRespawned(respawnParams)

	local playerID = respawnParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

    --Cancel any existng reset request
    for index, resetPlayer in pairs(self.resettingPlayers) do
		if resetPlayer[1] == player then
			table.remove(self.resettingPlayers, index)
			break
		end
	end

	--If the player who has just respawned is IT, remove IT from them
	if player == self:GetIT() and self:GetGameState() == self.tagStates.GAME_STATE_PLAY then
		self:SetIT(nil)
	end

    --Penalize the player
    self:SetPlayerScore(player, self:GetPlayerScore(player)+RESPAWN_PENALTY)
	player:Reset()

end


function ReverseTagServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:AddPlayer(player)

end


function ReverseTagServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	--Check if the player who has left is the IT player
	if IsValid(self.ITPlayer) and (self.ITPlayer:GetUniqueID() == player:GetUniqueID()) then
		self:SetIT(nil)
	end
	self:RemovePlayer(player)

	--At least WAIT_TAG_PLAYERS players are required for there to be any kind of game
	if self:GetGameState() ~= self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS and self:GetNumberOfPlayers() < WAIT_TAG_PLAYERS + 1 then
		--Go back to waiting
		self:SetGameState(self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS)
	end

end


function ReverseTagServer:GetProcessSlot()

	return self.processSlot

end

--REVERSETAGSERVER CLASS END