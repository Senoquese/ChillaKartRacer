UseModule("IGameMode", "Scripts/GameModes/")
UseModule("SumoStates", "Scripts\\GameModes\\Sumo\\")
UseModule("GUITimer", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceCountdown", "Scripts\\GameModes\\Race\\")

--SUMOCLIENT CLASS START

class 'SumoClient' (IGameMode)

function SumoClient:__init(setMap) super()

    self.achievements = AchievementManager()

	self.map = setMap
	if not IsValid(self.map) then
		error("No map passed to GameMode Sumo in init")
	end

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetClientWorld():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

    GetMenuManager():GetNameTagManager():SetForceAllVisible(true)

    self:SetLoadingAllowed(true)

    --This is the global time that the round will start so the countdown is in sync
	self.roundStartTime = 0
	--Is the countdown GUI currently active?
	self.countdownActive = false

    self:InitGUI()
    self.mainPlayer:SetGUIVisible(true)

    GetMenuManager():GetRoster():SetScoreSorting(true)

    self.gameStates = SumoStates()
	
	--Find track music
    local objIter = GetClientWorld():GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetTypeName() == "SoundSource" and worldObject:GetName() == "Soundtrack" then
			self.mapMusic = ToSoundSource(worldObject)
			break
		end
		objIter:Next()
	end

	self.stateFuncs = { }
    self.gameStates:InitStateFuncs(self, self.stateFuncs)

	self.gameState = nil

	self:InitState()

	--Init player state after initing main state
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:InitPlayerState(player)
		i = i + 1
	end

end


function SumoClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("SumoClient", "IGameMode", "Manages the Sumo game mode")

end


function SumoClient:InitGameMode()

    self.mainPlayer:SetGUIVisible(true)
    
end


function SumoClient:UnInitGameMode()

    self:UnInitGUI()
    
end


function SumoClient:InitStateWaitForPlayers()

    self.mainPlayer:SetGUIVisible(true)
    self.warmupGUI:SetVisible(true)
    self.timerGUI:SetVisible(false)

end


function SumoClient:UnInitStateWaitForPlayers()

    self.warmupGUI:SetVisible(false)

end


function SumoClient:ProcessStateWaitForPlayers()

end


function SumoClient:InitStatePlay()

    self.timerGUI:SetVisible(true)

end


function SumoClient:UnInitStatePlay()

end


function SumoClient:ProcessStatePlay()

end


function SumoClient:InitStateCountdown()

    self.countdownActive = false
    self.timerGUI:SetVisible(false)
    self.mainPlayer:SetGUIVisible(true)

end


function SumoClient:UnInitStateCountdown()

end


function SumoClient:ProcessStateCountdown()

    --The countdown doesn't start until after the time in self.roundStartTime
	if GetClientSystem():GetTime() > self.roundStartTime and not self.countdownActive and self:GetPlayerState(self.mainPlayer) == self.gameStates.PS_COUNTDOWN then
		self.countdownGUI:Start(self.roundStartTime + 3)
		self.countdownActive = true
	end

end


function SumoClient:InitStateShowWinners()

    self.timerGUI:SetTime(0)

    --Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end
    
    self.mainPlayer:SetGUIVisible(false)

	--BRIAN TODO: String table?
	GetMenuManager():GetChat():AddMessage("#00ffda", "GAME OVER!")

	self:ShowStandingsGUI(true)

	--play a win or lose sound
    local sortedResults = self:GetSortedRoster()
    local winningPlayer = sortedResults[1]
    local secondPlayer = nil
    local thirdPlayer = nil
    if #sortedResults > 1 then
        secondPlayer = sortedResults[2]
    end
    if #sortedResults > 2 then
        thirdPlayer = sortedResults[3]
    end
    if winningPlayer == self.mainPlayer then
        self.achievements:UpdateStat(self.achievements.STAT_FINISHES_1ST, 1)
    elseif secondPlayer == self.mainPlayer then
        self.achievements:UpdateStat(self.achievements.STAT_FINISHES_2ND, 1)
    elseif thirdPlayer == self.mainPlayer then
        self.achievements:UpdateStat(self.achievements.STAT_FINISHES_3RD, 1)
    end
    if winningPlayer == self.mainPlayer then
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/win.wav", WVector3(), 0.2, 10, false, SoundSystem.MEDIUM)
    else
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/fail.wav", WVector3(), 0.2, 10, false, SoundSystem.MEDIUM)
    end

    self:CheckGentlemansWager()
	self:CheckPirateParty()
    self:CheckWargames()
    self:CheckInspectorKemp()
    self:CheckTermination()

end


function SumoClient:UnInitStateShowWinners()

    self:ShowStandingsGUI(false)
	--Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)

end


function SumoClient:ProcessStateShowWinners()

    if self.standings:GetVisible() then
        local mm = GetMenuManager()
        local guiOver = mm.guiEscapeMenu:GetVisible() or mm.guiServer:GetVisible() or mm.guiSettings:GetVisible() or mm.guiServerBrowser:GetVisible() or mm.guiRoster:GetVisible()
        if guiOver then
            self.standings:Hide3DControllers()
        else
            self.standings:Show3DControllers()
        end
    end

end


function SumoClient:Process()

    local frameTime = GetFrameTime()
    self:ProcessGUI(frameTime)

    self.stateFuncs[self.gameState][self.gameStates.PROCESS_FUNC](self)

end


function SumoClient:InitGUI()

	self.timerGUI = GUITimer()
	self.timerGUI:SetVisible(true)
	self.standings = GUIRaceStandings()
	self.standings:SetVisible(false)
	self.countdownGUI = GUIRaceCountdown()

	self.warmupGUI = GetMyGUISystem():LoadLayout("warmup.layout", "Warmup_")
    self.warmupGUI:SetVisible(false)

	--Does the roster need to be updated?
	self.rosterDirty = true

end


function SumoClient:UnInitGUI()

	self.timerGUI:UnInit()
	self.timerGUI = nil

	self.standings:UnInit()
	self.standings = nil

	self.countdownGUI:UnInit()
	self.countdownGUI = nil

	GetMyGUISystem():UnloadLayout(self.warmupGUI)
	self.warmupGUI = nil

end


function SumoClient:ProcessGUI(frameTime)

	self:ProcessRoster()
	if IsValid(self.gameEndTime) then
        local time = self.gameEndTime - GetClientSystem():GetTime()
        if time < 0 then
            time = 0
        end
        self.timerGUI:SetTime(time)
	end
	if self.gameState == self.gameStates.GS_PLAY and not self.mainPlayer:GetGUIVisible() then
        self.mainPlayer:SetGUIVisible(true)
    elseif self.gameState == self.gameStates.GS_SHOW_WINNERS and self.mainPlayer:GetGUIVisible() then
        self.mainPlayer:SetGUIVisible(false)
    end

    self.countdownGUI:Process(frameTime)

end


function SumoClient:InitState()

	self.playerScoreSlot = self:CreateSlot("PlayerScoreSlot", "PlayerScoreSlot")
	self.playerStateSlot = self:CreateSlot("PlayerStateSlot", "PlayerStateSlot")
	self.playerFalloutOrderSlot = self:CreateSlot("PlayerFalloutOrderSlot", "PlayerFalloutOrderSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.gameEndTimeSlot = self:CreateSlot("GameEndTimeSlot", "GameEndTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameEndTime", self.gameEndTimeSlot)

    self.roundStartTimeSlot = self:CreateSlot("RoundStartTimeSlot", "RoundStartTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RoundStartTime", self.roundStartTimeSlot)

end


function SumoClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState

    if IsValid(oldState) then
        print("Old game state: " .. self.gameStates:GameStateToString(oldState))
    end
    print("New game state: " .. self.gameStates:GameStateToString(self.gameState))

	--First uninit old state
	if IsValid(oldState) then
	    self.stateFuncs[oldState][self.gameStates.UNINIT_FUNC](self)
	end

	--Now init new state
	self.stateFuncs[self.gameState][self.gameStates.INIT_FUNC](self)

end


function SumoClient:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState

    --Based on the player state, manage their controller
	if player.userData.state == self.gameStates.PS_WAIT_FOR_PLAYERS then
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.gameStates.PS_COUNTDOWN then
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.gameStates.PS_PLAY then
	    player:GetController().boostBurned = 0
	    player:GetController().weaponsUsed = false
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.gameStates.PS_SHOW_WINNERS then
		player:SetControllerEnabled(true)
		--Check for pacifist
        if player == self.mainPlayer then
            if player.userData.place == 1 and player:GetController().weaponsUsed == false then
                self.achievements:Unlock(self.achievements.AVMT_PACIFIST)
            end
        end
	elseif player.userData.state == self.gameStates.PS_WAIT_FOR_ROUND_END then
		player:SetControllerEnabled(false)
	end

	if player == self.mainPlayer then
	    --self.spectatorGUI:SetVisible(false)
		if self:GetPlayerState(self.mainPlayer) == self.gameStates.PS_WAIT_FOR_PLAYERS then
			--Load all we want before the round starts
			self:SetLoadingAllowed(true)
		end

		if self:GetPlayerState(self.mainPlayer) == self.gameStates.PS_PLAY or 
           self:GetPlayerState(self.mainPlayer) == self.gameStates.PS_COUNTDOWN then
			--Loading now would interrupt gameplay
			self:SetLoadingAllowed(false)

			self.mainPlayer:SetGUIVisible(true)
		end

		if self:GetPlayerState(self.mainPlayer) == self.gameStates.PS_SHOW_WINNERS then
			--Load all we want when the winners are being shown as nobody is playing
			self:SetLoadingAllowed(true)

            --[[self.spectatorManager:SetEnabled(false)
			GetCameraManager():AddController(self.camFreeMove, 2)
			GetCamera():SetPosition(self.observeCamPos)
			GetCamera():GetLookAt():SetPosition(self.observeCamLookAt)--]]

			if self.mainPlayer.userData.place == 1 then
			    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/win.wav", WVector3(), 0.2, 10, false, SoundSystem.HIGH)
			    if GetClientManager().indieSlider then
			        self.achievements:Unlock(self.achievements.AVMT_INDIE_GAMER)
			    end
			end
		else
			--GetCameraManager():RemoveController(self.camFreeMove)
		end

        --[[--Spectator states
        if self:IsPlayerSpectating(self.mainPlayer) then
			--It is okay to load while the player is spectating as it won't screw up their gameplay
            self:SetLoadingAllowed(true)
            
            self.spectatorTimer:Reset()
        end--]]
	end

end


function SumoClient:GetPlayerState(player)

	return player.userData.state

end


function SumoClient:GameEndTimeSlot(endTimeParams)

	self.gameEndTime = endTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end


function SumoClient:RoundStartTimeSlot(startTimeParams)

	self.roundStartTime = startTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end


function SumoClient:PlayerScoreSlot(scoreParams)

	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScore = scoreParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerScore(player, playerScore)

end


function SumoClient:PlayerStateSlot(stateParams)

    local playerID = ExtractPlayerIDFromState(stateParams:GetParameter(0, true))
	local playerState = stateParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerState(player, playerState)

end


function SumoClient:PlayerFalloutOrderSlot(orderParams)

    local playerID = ExtractPlayerIDFromState(orderParams:GetParameter(0, true))
	local playerFalloutOrder = orderParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerFalloutOrder(player, playerFalloutOrder)

end


function SumoClient:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	--Update the roster with this new score
	self.rosterDirty = true

end


function SumoClient:GetPlayerScore(player)

	return player.userData.score

end


function SumoClient:SetPlayerFalloutOrder(player, playerFalloutOrder)

    print("Player named " .. player:GetName() .. " fell out at order: " .. tostring(playerFalloutOrder))
    player.userData.falloutOrder = playerFalloutOrder

end


function SumoClient:GetPlayerFalloutOrder(player)

    return player.userData.falloutOrder

end


function SumoClient:ProcessRoster()

	if self.rosterDirty then
		local rosterList = { }
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		local i = 1
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			local setColor = "FFFFFF"
			local playerData = { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor, 
								 score = player.userData.score, ping = 0, kick = 0, audioMute = 0, visualMute = 0 }
			table.insert(rosterList, playerData)
			i = i + 1
		end

		GetMenuManager():GetRoster():UpdateRoster(rosterList)
		self.rosterDirty = false
	end

end


function SumoClient:GetProcessSlot()

	return self.processSlot

end


function SumoClient:ShowStandingsGUI(show, excludePlayerID)

	if show then
		--Update the standings
		local currentStandings = { }
		local i = 1
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			player:SetControllerEnabled(false)
			if player.userData.falloutOrder ~= 0 and player:GetUniqueID() ~= excludePlayerID then
			    table.insert(currentStandings, { player, player.userData.falloutOrder })
			end
			i = i + 1
		end
		self.standings:ShowStandings(currentStandings, false)
	else
		self.standings:HideStandings()
	end
	self.timerGUI:SetVisible(not show)

end


function SumoClient:GetSortedRoster()

    local rosterList = { }
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		table.insert(rosterList, player)
		i = i + 1
	end
	table.sort(rosterList, function(playerA, playerB) return playerA.userData.falloutOrder > playerB.userData.falloutOrder end)
	return rosterList

end


function SumoClient:InitPlayerState(player)

	--Default values before watching their state in case their states is already known to the table
	player.userData.state = self.gameStates.PS_WAIT_FOR_PLAYERS
	player.userData.score = 0

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Score", self.playerScoreSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_FalloutOrder", self.playerFalloutOrderSlot)

	--Update the roster GUI
	self.rosterDirty = true

end


function SumoClient:ClientConnected(connectParams)

    local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	print("ClientConnected: " .. player:GetName())
    self:InitPlayerState(player)
	self.rosterDirty = true

end


function SumoClient:ClientDisconnected(disconnectParams)

    local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
    local player = GetPlayerManager():GetPlayerFromID(playerID)
	print("ClientDisconnected: " .. player:GetName())
	self.rosterDirty = true
	if self.gameState == self.gameStates.GS_SHOW_WINNERS then
	    --Update the winners screen to remove this player
	    self:ShowStandingsGUI(true, playerID)
	end

end

--SUMOCLIENT CLASS END