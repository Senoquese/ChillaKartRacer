UseModule("IGameMode", "Scripts/GameModes/")
UseModule("SumoStates", "Scripts\\GameModes\\Sumo\\")

local WAIT_PLAYERS = 1

--SUMOSERVER CLASS START

class 'SumoServer' (IGameMode)

local ROUND_TIMER = 60 * 2.0

function SumoServer:__init(setMap) super()

    GetServerManager():SetCurrentBotType("SumoBot")

    self.resettingPlayers = { }

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode SumoServer in init")
	end

	local timeLimitSetting = self.map:GetSetting("TimeLimit", false)
	if IsValid(timeLimitSetting) then
	    ROUND_TIMER = timeLimitSetting:GetFloatData()
	end

	self.movers = { }
	self:InitMovers(self.movers)

	self.gameStates = SumoStates()

    self.gameClock = WTimer()
    self.stateClock = WTimer()
    self.showWinnersTimer = WTimer(10)
    self.waitForPlayersTimer = WTimer(10)
    self.roundStartTime = 0
    self.countdownActive = false
    self.sumoCountdownTimer = 3

    self.giveWeaponTimer = WTimer(3)

    --This parameter can be used for any purpose instead of creating a new one everytime
	self.param = Parameter()

    self:InitState()

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

    self.playerFalloutSlot = self:CreateSlot("PlayerFallout", "PlayerFallout")
    --Find the fallout sensor
	local falloutSensorName = self.map:GetSetting("FalloutSensor", false)
	if not IsValid(falloutSensorName) then
	    error("FalloutSensor must be defined in the map settings")
	end
	falloutSensorName = falloutSensorName:GetStringData()
	local objIter = GetNetworkedWorld():GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetName() == falloutSensorName then
			worldObject:GetSignal("SensorCallback", true):Connect(self.playerFalloutSlot)
			break
		end
		objIter:Next()
	end

	--Init all the players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:AddPlayer(player)
		i = i + 1
	end

    --This keeps track of the order players fallout of the map in
    self.falloutOrder = { }

    self.stateFuncs = { }
    self.gameStates:InitStateFuncs(self, self.stateFuncs)

    --First wait for at least 1 person
	self.gameState = nil
	self:SetGameState(self.gameStates.GS_WAIT_FOR_PLAYERS)

end


function SumoServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("SumoServer", "IGameMode", "Manages the reverse tag game mode")

end


function SumoServer:InitMovers(moverList)

    local moverNamePrefixSetting = self.map:GetSetting("MoverNamePrefix", false)
	if not IsValid(moverNamePrefixSetting) then
	    error("MoverNamePrefix must be defined in the map settings")
	end
	self.moverNamePrefix = moverNamePrefixSetting:GetStringData()
	local moverFirstIndexSetting = self.map:GetSetting("MoverFirstIndex", false)
	if not IsValid(moverFirstIndexSetting) then
	    error("MoverFirstIndex must be defined in the map settings")
	end
	self.moverFirstIndex = moverFirstIndexSetting:GetIntData()
	local moverLastIndexSetting = self.map:GetSetting("MoverLastIndex", false)
	if not IsValid(moverLastIndexSetting) then
	    error("MoverLastIndex must be defined in the map settings")
	end
	self.moverLastIndex = moverLastIndexSetting:GetIntData()

	local currMoverIndex = self.moverFirstIndex
	while currMoverIndex >= self.moverLastIndex do
        local objIter = GetNetworkedWorld():GetObjectIterator()
        while not objIter:IsEnd() do
            local worldObject = objIter:Get()
            if worldObject:GetName() == self.moverNamePrefix .. tostring(currMoverIndex) then
                table.insert(moverList, ToScriptObject(worldObject):Get())
                break
            end
            objIter:Next()
        end
        currMoverIndex = currMoverIndex - 1
    end

end


function SumoServer:InitGameMode()

	--There isn't really any kind of game being played here
	self:SetGameRunning(false)

end


function SumoServer:UnInitGameMode()

    self:UnInitState()
	self:UnInitGame()

end


function SumoServer:AddPlayer(addPlayer)

	for index, player in ipairs(self.players) do
		if player:GetUniqueID() == addPlayer:GetUniqueID() then
			print("%%% Attempt was made in SumoServer:AddPlayer() to add an existing player")
			return
		end
	end

    --Spawn a controller for this player
	local spawnPos, spawnOrien = GetSpawnPointManager():GetFreeSpawnPoint()
	if spawnPos == nil or spawnOrien == nil then
		spawnPos = WVector3()
		spawnOrien = WQuaternion()
	end
	self:SpawnPlayerController(addPlayer, CreateKartController, spawnPos, spawnOrien)

	--We want to know when the player is reset so we can respawn them with a delay
	addPlayer:GetSignal("Resetting", true):Connect(self.playerResetSlot)

    self:InitPlayerState(addPlayer)

	table.insert(self.players, addPlayer)

    self.waitForPlayersTimer:Reset()

    if self:GetGameState() ~= self.gameStates.GS_WAIT_FOR_PLAYERS then
        self:SetPlayerState(addPlayer, self.gameStates.PS_WAIT_FOR_ROUND_END)
    end

end


function SumoServer:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	self.param:SetIntData(player.userData.score)

	print("SetPlayerScore: "..player:GetName()..", "..playerScore)

	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_Score", self.param)

end


function SumoServer:GetPlayerScore(player)

    if IsValid(player.userData.score) then
	    return player.userData.score
	else
        return 0
    end

end


function SumoServer:RemovePlayer(removePlayer)

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
		print("%%% Attempt was made in SumoServer:RemovePlayer() to remove a player we don't know about")
	end

	self:DestroyPlayerController(removePlayer, DestroyKartController)

	--At least 2 people are required if the game isn't already waiting
	if self:GetGameState() ~= self.gameStates.GS_WAIT_FOR_PLAYERS and self:GetNumberOfPlayers() < 2 then
		--Go back to waiting
		self:SetGameState(self.gameStates.GS_WAIT_FOR_PLAYERS)
	elseif self:GetGameState() ~= self.gameStates.GS_WAIT_FOR_PLAYERS then
	    --Check if there is only 1 player remaining in the ring
	    self:CheckGameOver()
	end

end


function SumoServer:GetNumberOfPlayers()

	return #self.players

end


function SumoServer:UnInitGame()

	if IsValid(self.ITSensor) then
		self.ITSensor:UnInit()
		self.ITSensor = nil
	end

end


--This will respawn all the players
function SumoServer:RespawnAllPlayers()

	for index, player in ipairs(self.players) do
		GetServerManager():RespawnPlayer(player:GetUniqueID())
	end

	GetServerManager():ResetAllPlayers()

end


function SumoServer:ResetMovers()

    for index, mover in ipairs(self.movers) do
		mover:ResetPathObject()
	end
	print("------------------------- Movers were reset")

end


function SumoServer:PauseMovers()

    --Setting the offset time to less than 0 will cause them to not process
    self:SetMoversOffsetTime(-1)
    print("------------------------- Movers are paused!")

end


function SumoServer:SetMoversOffsetTime(setOffsetTime)

    print("Num movers: " .. tostring(#self.movers))
    for index, mover in ipairs(self.movers) do
		mover:SetOffsetTime(setOffsetTime)
	end
	print("------------------------- Movers offset time is: " .. tostring(setOffsetTime))

end


function SumoServer:SetGameState(newGameState)

	local oldState = self.gameState
	self.gameState = newGameState

	--Reset the state clock
	self.stateClock:Reset()

	--First uninit old state
	if IsValid(oldState) then
	    self.stateFuncs[oldState][self.gameStates.UNINIT_FUNC](self)
	end

	--Now init new state
	self.stateFuncs[self.gameState][self.gameStates.INIT_FUNC](self)

	self:SetGameRunning(self.gameState == self.gameStates.GS_PLAY)

	--Update the states of all the current players based on this new game state
	self:UpdatePlayerStates()

	self.param:SetIntData(self.gameState)
	GetServerSystem():GetSendStateTable("Map"):SetState("GameState", self.param)

end


function SumoServer:GetGameState()

	return self.gameState

end


function SumoServer:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState

	print("%%% Player " .. player:GetName() .. " changed to state: " .. self.gameStates:PlayerStateToString(player.userData.state))

	self.param:SetIntData(player.userData.state)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_State", self.param)

    --Clear boost!
    player:GetController():SetBoostPercent(0) 

	--Based on the player state, manage their controller
	if player.userData.state == self.gameStates.PS_WAIT_FOR_PLAYERS then
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(true)
	elseif player.userData.state == self.gameStates.PS_COUNTDOWN then
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.gameStates.PS_PLAY then
		player:SetControllerEnabled(true)
		player:GetController():SetEnableControls(true)
    elseif player.userData.state == self.gameStates.PS_FALLOUT then
        player:SetControllerEnabled(false)
        player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.gameStates.PS_SHOW_WINNERS then
		player:SetControllerEnabled(false)
		player:GetController():SetEnableControls(false)
	elseif player.userData.state == self.gameStates.PS_WAIT_FOR_ROUND_END then
		player:SetControllerEnabled(false)
		player:GetController():SetEnableControls(false)
	end

end


function SumoServer:GetPlayerState(player)

	return player.userData.state

end


--Update all the current player's states based on the current game state
function SumoServer:UpdatePlayerStates()

	for index, player in ipairs(self.players) do
		self:UpdatePlayerState(player)
	end

end


--Update the passed in player's state based on the current game state
function SumoServer:UpdatePlayerState(forPlayer)

	--Based on the current game state, set this player's state
	if self:GetGameState() == self.gameStates.GS_WAIT_FOR_PLAYERS then
		--There are not enough people in the server for the round to start
		self:SetPlayerState(forPlayer, self.gameStates.PS_WAIT_FOR_PLAYERS)

	elseif self:GetGameState() == self.gameStates.GS_COUNTDOWN then
		--The game is about to start
		self:SetPlayerState(forPlayer, self.gameStates.PS_COUNTDOWN)

	elseif self:GetGameState() == self.gameStates.GS_PLAY then
		--The game has started
		if self:GetPlayerState(forPlayer) ~= self.gameStates.PS_WAIT_FOR_ROUND_END then
            self:SetPlayerState(forPlayer, self.gameStates.PS_PLAY)
        end

	elseif self:GetGameState() == self.gameStates.GS_SHOW_WINNERS then
		--All players see the winners list
		self:SetPlayerState(forPlayer, self.gameStates.PS_SHOW_WINNERS)
	end

end


function SumoServer:InitStateWaitForPlayers()

    self:ResetMovers()
    self:PauseMovers()

end


function SumoServer:UnInitStateWaitForPlayers()

end


function SumoServer:ProcessStateWaitForPlayers()

    --At least WAIT_PLAYERS+1 players are required to start the game
	if self:GetNumberOfPlayers() > WAIT_PLAYERS and self.waitForPlayersTimer:IsTimerUp() then
		--We have at least WAIT_PLAYERS+1 players, start the countdown
		self:SetGameState(self.gameStates.GS_COUNTDOWN)
	end

end


function SumoServer:InitStatePlay()

    self.gameClock:Reset()
    self.gameEndTime = GetServerSystem():GetTime() + ROUND_TIMER
    self.param:SetFloatData(self.gameEndTime)
    GetServerSystem():GetSendStateTable("Map"):SetState("GameEndTime", self.param)

    --The movers should use now as their base time
    self:SetMoversOffsetTime(GetServerSystem():GetTime())

end


function SumoServer:UnInitStatePlay()

end


function SumoServer:ProcessStatePlay()

    if self.gameClock:GetTimeSeconds() >= ROUND_TIMER then
	    self:SetGameState(self.gameStates.GS_SHOW_WINNERS)
	end

	if self.giveWeaponTimer:IsTimerUp() then
	    self.giveWeaponTimer:Reset()
	    --Give all the players still playing a puncher
	    for index, player in ipairs(self.players) do
	        if self:GetPlayerState(player) == self.gameStates.PS_PLAY then
	            print("Giving " .. player:GetName() .. " a puncher")
	            GP(player:GetName())
	        end
	    end
	end

end


function SumoServer:InitStateCountdown()

    GetSpawnPointManager():ResetSpawnPointer()
	self:RespawnAllPlayers()

    --Reset the fallout order for all players
    for index, player in ipairs(self.players) do
        self.param:SetIntData(0)
        GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_FalloutOrder", self.param)
    end
    self.falloutOrder = { }

    --Notify the clients what time the countdown will start at so we are all in sync
	self.roundStartTime = GetServerSystem():GetTime() + 1
	self.param:SetFloatData(self.roundStartTime)
	GetServerSystem():GetSendStateTable("Map"):SetState("RoundStartTime", self.param)

    self:ResetMovers()
    self:PauseMovers()

	--Notify the base IGameMode that the game has reset
	self:GameReset()

end


function SumoServer:UnInitStateCountdown()

end


function SumoServer:ProcessStateCountdown()

    --The countdown doesn't start until after the time in self.roundStartTime
	if GetServerSystem():GetTime() > self.roundStartTime and not self.countdownActive then
		self.stateClock:Reset()
		self.countdownActive = true
	end

	if self.countdownActive then
		if self.stateClock:GetTimeSeconds() > self.sumoCountdownTimer then
			--Countdown finished
			self:SetGameState(self.gameStates.GS_PLAY)
		end
	end

end


function SumoServer:InitStateShowWinners()

	self.showWinnersTimer:Reset()

    --The winner is the only person who hasn't fallen out
    local winner = nil
    local numWinners = 0
    local playerIsWinner = false
	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(false)
		player:SetControllerEnabled(false)
		if self:GetPlayerState(player) == self.gameStates.PS_WAIT_FOR_ROUND_END then
		    print("Player " .. player:GetName() .. " is waiting for round to end in InitStateShowWinners")
		    playerIsWinner = false
		else
            playerIsWinner = true
            for fIndex, fPlayerID in ipairs(self.falloutOrder) do
                --If they have fallen out, they aren't the winner
                if player:GetUniqueID() == fPlayerID then
                    playerIsWinner = false
                    break
                end
            end
        end
		if playerIsWinner then
		    numWinners = numWinners + 1
		    --We need to force them to fallout so we can track the order for displaying
		    --on the results screen
		    self:SetPlayerFallOut(player, true)
		    --There can be only one, if more than one player has survived, it is a draw
		    if numWinners ~= 1 then
		        winner = nil
		    else
		        winner = player
		    end
		end
	end

    --Award a point to the winner
    if IsValid(winner) then
	    self:SetPlayerScore(winner, self:GetPlayerScore(winner) + 1)
	end

end


function SumoServer:UnInitStateShowWinners()

	--Reset all the players scores
	for index, player in ipairs(self.players) do
		local controller = player:GetController()
		controller:SetEnableControls(true)
		controller:SetBoostPercent(0)
		player:SetControllerEnabled(true)
	end

end


function SumoServer:ProcessStateShowWinners()

    --After giving the clients time to review the winners list, start the countdown again
	if self.showWinnersTimer:IsTimerUp() then
		self:SetGameState(self.gameStates.GS_COUNTDOWN)
	end

end


function SumoServer:Process()

	self:ProcessResettingPlayers()

    self.stateFuncs[self.gameState][self.gameStates.PROCESS_FUNC](self)

end


function SumoServer:ProcessResettingPlayers()

	for index, resetPlayer in pairs(self.resettingPlayers) do
		--Index 2 is the reset clock
        --Index 1 is the actual player object
        GetServerManager():RespawnPlayer(resetPlayer[1]:GetUniqueID())
        table.remove(self.resettingPlayers, index)
        --If there are more to be reset, we will catch them next time
        return
	end

end


function SumoServer:PlayerReset(resetParams)

	local playerKartID = resetParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromObjectID(playerKartID)
	if self:GetPlayerState(player) == self.gameStates.PS_WAIT_FOR_PLAYERS then
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

end


function SumoServer:PlayerRespawned(respawnParams)

	local playerID = respawnParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	player:Reset()

end


function SumoServer:PlayerFallout(params)

    local playerID = params:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	local playerState = self:GetPlayerState(player)
	self:SetPlayerFallOut(player)
	if playerState == self.gameStates.PS_PLAY then
	    self:CheckGameOver()
	end

end


function SumoServer:SetPlayerFallOut(player, forceFallout)

    GetWeaponManagerServer():RemoveWeapons(player)
	--If the game hasn't started yet, the plane just respawns the player
	if self:GetGameState() == self.gameStates.GS_WAIT_FOR_PLAYERS then
	    GetServerManager():RespawnPlayer(player:GetUniqueID())
	elseif self:GetPlayerState(player) == self.gameStates.PS_PLAY or forceFallout == true then
        print("Player named " .. player:GetName() .. " fell out!")
        table.insert(self.falloutOrder, player:GetUniqueID())
        --Notify everyone
        self.param:SetIntData(#self.falloutOrder)
	    GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_FalloutOrder", self.param)

        self:SetPlayerState(player, self.gameStates.PS_FALLOUT)
        if player:GetControllerValid() then
            player:GetController():SetPosition(WVector3())
        end
    end

end


function SumoServer:CheckGameOver()

    --Check if there is one or less players left to end the game
    local numPlayersPlaying = 0
    for index, player in ipairs(self.players) do
        if self:GetPlayerState(player) == self.gameStates.PS_PLAY then
            numPlayersPlaying = numPlayersPlaying + 1
        end
    end
    if numPlayersPlaying < 2 and self:GetGameState() ~= self.gameStates.GS_SHOW_WINNERS then
        self:SetGameState(self.gameStates.GS_SHOW_WINNERS)
    end

end


function SumoServer:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:AddPlayer(player)

end


function SumoServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:RemovePlayer(player)

end


function SumoServer:InitState()

	GetServerSystem():GetSendStateTable("Map"):NewState("GameState")
	GetServerSystem():GetSendStateTable("Map"):NewState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):NewState("RoundStartTime")

	GetServerSystem():GetSendStateTable("Map"):NewState("SumoCountdownTimer")
	self.param:SetFloatData(self.sumoCountdownTimer)
	GetServerSystem():GetSendStateTable("Map"):SetState("SumoCountdownTimer", self.param)

end


function SumoServer:UnInitState()

	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameState")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("GameEndTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("RoundStartTime")
	GetServerSystem():GetSendStateTable("Map"):RemoveState("SumoCountdownTimer")

end


function SumoServer:InitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):NewState(tostring(player:GetUniqueID()) .. "_FalloutOrder")
	self.param:SetIntData(0)
	GetServerSystem():GetSendStateTable("Map"):SetState(tostring(player:GetUniqueID()) .. "_FalloutOrder", self.param)

	--Init the data for this client
	player.userData.score = 0
	player.userData.state = self.gameStates.PS_WAIT_FOR_PLAYERS
    
end


function SumoServer:UnInitPlayerState(player)

	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_Score")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_State")
	GetServerSystem():GetSendStateTable("Map"):RemoveState(tostring(player:GetUniqueID()) .. "_FalloutOrder")

end


function SumoServer:GetProcessSlot()

	return self.processSlot

end

--SUMOSERVER CLASS END