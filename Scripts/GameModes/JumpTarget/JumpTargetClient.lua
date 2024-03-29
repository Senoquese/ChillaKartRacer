UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("JumpTargetStates", "Scripts\\GameModes\\JumpTarget\\")
UseModule("JumpTargetClientManager", "Scripts\\GameModes\\JumpTarget\\")
UseModule("GUIRaceCountdown", "Scripts\\GameModes\\Race\\")
UseModule("GUITimer", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")
UseModule("CamControllerGoTo", "Scripts/Modifiers/CameraControllers/")
UseModule("AchievementManager", "Scripts/")
UseModule("SyncedSpring", "Scripts/SyncedObjects/Weapons/")

--JUMPTARGETCLIENT CLASS START

class 'JumpTargetClient' (IGameMode)

function JumpTargetClient:__init(setMap) super()

	self.map = setMap
	if not IsValid(self.map) then
		error("No map passed to GameMode JumpTarget in init")
	end

	self:InitGUI()

	self.achievements = AchievementManager()

	self.jumpStates = JumpTargetStates()

	self.jumpTargetManager = nil
	self:InitJumpTargets()

	--This is how long the current round will go on for
	self.roundTimer = 0
	--This is how long the round has been going on for
	self.roundClock = WTimer()

    self.gameClock = WTimer()
	self:SetLoadingAllowed(true)

    GetMenuManager():GetRoster():SetScoreSorting(true)

	--This is the global time that the round will start so the countdown is in sync
	self.roundStartTime = 0
	--Is the countdown GUI currently active?
	self.countdownActive = false

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Get reference to the playerCam
	self.camera = GetCamera()
	self.cameraClock = WTimer()

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

	self:InitMapObjects()

	self:LoadMapSettings()

	--The observe positions should be valid at this point
	self.gotoCamController = CamControllerGoTo(self.observeCamPos, self.observeCamLookAt, GetCamera())
	self.gotoCamControllerAdded = false

	--Init state last after all values have been initialized
	self:InitState()
	--Init player state after initing main state
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		self:InitPlayerState(player)
		i = i + 1
	end
	
	-- Find track music
    local objIter = GetClientWorld():GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetTypeName() == "SoundSource" and worldObject:GetName() == "Soundtrack" then
			self.mapMusic = ToSoundSource(worldObject)
			break
		end
		objIter:Next()
	end

end


function JumpTargetClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("JumpTargetClient", "IBase", "The client game mode manager for JumpTarget")

end


function JumpTargetClient:InitGameMode()

end


function JumpTargetClient:UnInitGameMode()

	self:UnInitGUI()
	self:UnInitState()
	self:UnInitMapObjects()

end


function JumpTargetClient:InitState()

	self.playerStateSlot = self:CreateSlot("PlayerStateSlot", "PlayerStateSlot")
	self.playerScoreSlot = self:CreateSlot("PlayerScoreSlot", "PlayerScoreSlot")
	self.playerScoreTargetSlot = self:CreateSlot("PlayerScoreTargetSlot", "PlayerScoreTargetSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.roundStartTimeSlot = self:CreateSlot("RoundStartTimeSlot", "RoundStartTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RoundStartTime", self.roundStartTimeSlot)

	--Jump settings
	self.roundTimerSlot = self:CreateSlot("RoundTimerSlot", "RoundTimerSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RoundTimer", self.roundTimerSlot)

end


function JumpTargetClient:UnInitState()

end


function JumpTargetClient:InitPlayerState(player)

	--Default values before watching their state in case their states is already known to the table
	player.userData.state = self.jumpStates.PS_PLAY
	player.userData.score = 0

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Score", self.playerScoreSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_ScoreTarget", self.playerScoreTargetSlot)

	--Update the roster GUI
	self.rosterDirty = true

end


function JumpTargetClient:UnInitPlayerState(player)

	--Update the roster GUI
	self.rosterDirty = true

end


function JumpTargetClient:InitGUI()

	self.countdownGUI = GUIRaceCountdown()
	self.countdownGUI:SetVisible(false)
	self.timerGUI = GUITimer()
	self.raceStandings = GUIRaceStandings()
	self.raceStandings:SetVisible(false)

	--Does the roster need to be updated?
	self.rosterDirty = true

	--We will control the roster
	GetMenuManager():GetRoster():SetManuallyControlled(true)

end


function JumpTargetClient:UnInitGUI()

	self.countdownGUI:UnInit()
	self.countdownGUI = nil

	self.timerGUI:UnInit()
	self.timerGUI = nil

	self.raceStandings:UnInit()
	self.raceStandings = nil

	--We no longer control the roster
	if IsValid(GetMenuManager()) and IsValid(GetMenuManager():GetRoster()) then
		GetMenuManager():GetRoster():SetManuallyControlled(false)
	end

end


function JumpTargetClient:InitMapObjects()

	--Find the JumpCameraSensor in the map
	self.camSensor = self.map:GetMapObject("JumpCameraSensor", true)
	self.camSensorCallbackSlot = self:CreateSlot("CamSensorCallbackSlot", "CamSensorCallbackSlot")
	self.camSensor:Get():GetSignal("SensorCallback", true):Connect(self.camSensorCallbackSlot)

	self.playerRespawnedSlot = self:CreateSlot("PlayerRespawnedSlot", "PlayerRespawnedSlot")
	GetClientManager():GetSignal("PlayerRespawned"):Connect(self.playerRespawnedSlot)

end


function JumpTargetClient:UnInitMapObjects()

	--DON'T uninit a map object, the map will do that for us
	self.camSensor = nil

end


function JumpTargetClient:InitJumpTargets()

	--Init the checkpoint manager with this map and checkpoints
	self.jumpTargetManager = JumpTargetClientManager(self.map)

end


function JumpTargetClient:UnInitJumpTargets()

	self.jumpTargetManager:UnInit()
	self.jumpTargetManager = nil

end


function JumpTargetClient:LoadMapSettings()

	--Observe camera position
	self.observeCamPos = WVector3()
	local camParam = self.map:GetSetting("ObserveCamPosX", false)
	if IsValid(camParam) then
		self.observeCamPos.x = camParam:GetFloatData()
	end
	camParam = self.map:GetSetting("ObserveCamPosY", false)
	if IsValid(camParam) then
		self.observeCamPos.y = camParam:GetFloatData()
	end
	camParam = self.map:GetSetting("ObserveCamPosZ", false)
	if IsValid(camParam) then
		self.observeCamPos.z = camParam:GetFloatData()
	end

	--Observe camera orientation
	self.observeCamLookAt = WVector3()
	camParam = self.map:GetSetting("ObserveCamLookAtX", false)
	if IsValid(camParam) then
		self.observeCamLookAt.x = camParam:GetFloatData()
	end
	camParam = self.map:GetSetting("ObserveCamLookAtY", false)
	if IsValid(camParam) then
		self.observeCamLookAt.y = camParam:GetFloatData()
	end
	camParam = self.map:GetSetting("ObserveCamLookAtZ", false)
	if IsValid(camParam) then
		self.observeCamLookAt.z = camParam:GetFloatData()
	end
    self.origCamLookAt = self.observeCamLookAt
    
    --CameraResetY
    self.cameraResetY = 0
	camParam = self.map:GetSetting("CameraResetY", true)
	if IsValid(camParam) then
		self.cameraResetY = camParam:GetFloatData()
	end

end


function JumpTargetClient:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState
	
	if player == self.mainPlayer then
        if newPlayerState == self.jumpStates.PS_PLAY and self.gameClock:GetTimeSeconds() > 5 then
            self:SetLoadingAllowed(false)
        elseif newPlayerState == self.jumpStates.PS_WAIT_FOR_ROUND_END and self.gameClock:GetTimeSeconds() > 5 then
            self:SetLoadingAllowed(true)
        elseif newPlayerState == self.jumpStates.PS_SHOW_WINNERS and self.gameClock:GetTimeSeconds() > 5 then
            self:SetLoadingAllowed(true)
        end
	end

end


function JumpTargetClient:GetPlayerState(player)

	return player.userData.state

end


function JumpTargetClient:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	--Update the roster with this new score
	self.rosterDirty = true

end


function JumpTargetClient:GetPlayerScore(player)

	return player.userData.score

end


function JumpTargetClient:Process()

	local frameTime = GetFrameTime()

	if self.gameState == self.jumpStates.GS_COUNTDOWN then
		self:ProcessStateCountdown(frameTime)
	elseif self.gameState == self.jumpStates.GS_PLAY then
		self:ProcessStatePlay(frameTime)
	elseif self.gameState == self.jumpStates.GS_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
	end

	self:ProcessGUI(frameTime)
	self:ProcessCamera(frameTime)
	self.jumpTargetManager:Process(frameTime)

end


function JumpTargetClient:ProcessGUI(frameTime)

	self.countdownGUI:Process(frameTime)
	self:ProcessRoster(frameTime)

end


function JumpTargetClient:ProcessRoster(frameTime)

	if self.rosterDirty then
		local rosterList = { }
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		local i = 1
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			local setColor = "B9FD01"
			if player:IsLocalPlayer() then
				setColor = "FFFFFF"
			end
			local playerData = { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor, 
								 score = player.userData.score, ping = 0, kick = 0, audioMute = 0, visualMute = 0 }
			table.insert(rosterList, playerData)
			i = i + 1
		end
		table.sort(rosterList, function(playerA, playerB) return playerA.score > playerB.score end)
		GetMenuManager():GetRoster():UpdateRoster(rosterList)
		self.rosterDirty = false
	end

end


function JumpTargetClient:ProcessCamera(frameTime)

end


function JumpTargetClient:ShowStandingsGUI(show)

	if show then
		--Update the standings
		local currentStandings = { }
		local i = 1
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			table.insert(currentStandings, { player, player.userData.score })
			i = i + 1
		end
		self.raceStandings:ShowStandings(currentStandings, false)
	else
		self.raceStandings:HideStandings()
	end
	self.timerGUI:SetVisible(not show)

end


function JumpTargetClient:InitStateCountdown()

    print("InitStateCountdown: roundTimer:"..self.roundTimer)
	self.timerGUI:SetTime(self.roundTimer)

	self.countdownActive = false
	self:SetLoadingAllowed(true)
	
	self.mainPlayer:SetGUIVisible(true)

end


function JumpTargetClient:UnInitStateCountdown()

	--Nothing to uninit here
	self:SetLoadingAllowed(false)
	
	self.mainPlayer:SetGUIVisible(true)

end


function JumpTargetClient:InitStatePlay()

    print("InitStatePlay: roundTimer:"..self.roundTimer)
	self.roundClock:Reset()
	self.timerGUI:SetTime(self.roundTimer)
	
	self.mainPlayer:SetGUIVisible(true)

end


function JumpTargetClient:UnInitStatePlay()

	--Nothing to uninit here

end


function JumpTargetClient:InitStateShowWinners()

	self.timerGUI:SetTime(0)

    -- Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end
    
    self.mainPlayer:SetGUIVisible(false)

	--BRIAN TODO: String table?
	GetMenuManager():GetChat():AddMessage("#00ffda", "GAME OVER!")

	self:ShowStandingsGUI(true)

    --BRIAN TODO: Why is this nil sometimes? http://www.nimblebit.com/forums/viewtopic.php?f=20&t=293&p=2311#p2311
    if IsValid(self.mainPlayer.userData.score) then
	    self.achievements:UpdateStat(self.achievements.STAT_TARGET_POINTS, self.mainPlayer.userData.score)
	end

	-- play a win or lose sound
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

function JumpTargetClient:GetSortedRoster()
    local rosterList = { }
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		table.insert(rosterList, player)
		i = i + 1
	end
	table.sort(rosterList, function(playerA, playerB) return playerA.userData.score > playerB.userData.score end)
	return rosterList
end

function JumpTargetClient:UnInitStateShowWinners()

	self:ShowStandingsGUI(false)
	-- Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)

end


--Countdown, game is about to start
function JumpTargetClient:ProcessStateCountdown(frameTime)

	--The countdown doesn't start until after the time in self.roundStartTime
	if self.roundStartTime > 0 and GetClientSystem():GetTime() > self.roundStartTime and not self.countdownActive then
		self.countdownGUI:SetVisible(true)
		self.countdownGUI:Start(self.roundStartTime+3)
		self.countdownActive = true
		self.roundEndTime = self.roundStartTime+self.roundTimer
		self.roundStartTime = 0
	end

    self:ProcessClock(frameTime)

end

function JumpTargetClient:ProcessClock(frameTime)

    if IsValid(self.roundEndTime) then
        --roundStartTime + 3 because of the countdown
        local time = self.roundEndTime - GetClientSystem():GetTime()
        if time < 0 then
            time = 0
        end
        self.timerGUI:SetTime(time)
	end

end

function JumpTargetClient:ProcessStatePlay(frameTime)

	self:ProcessClock(frameTime)
	if IsValid(self.mainPlayer) and IsValid(self.mainPlayer:GetController()) then
	    local playerPos = self.mainPlayer:GetController():GetPosition()
	    if playerPos.y < self.cameraResetY then
	        self.gotoCamController.gotoLookAt = self.origCamLookAt
	    else
	        self.gotoCamController.gotoLookAt = playerPos
	    end
	end

end


function JumpTargetClient:ProcessStateShowWinners(frameTime)
    if self.raceStandings:GetVisible() then
        local mm = GetMenuManager()
        local guiOver = mm.guiEscapeMenu:GetVisible() or mm.guiServer:GetVisible() or mm.guiSettings:GetVisible() or mm.guiServerBrowser:GetVisible() or mm.guiRoster:GetVisible()
        if guiOver then
            self.raceStandings:Hide3DControllers()
        else
            self.raceStandings:Show3DControllers()
        end
    end
end


function JumpTargetClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState
	print("%%% New JumpTarget gamestate: " .. self.jumpStates:GameStateToString(self.gameState))

	--UnInit old state
	if oldState == self.jumpStates.GS_COUNTDOWN then
		self:UnInitStateCountdown()
	elseif oldState == self.jumpStates.GS_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.jumpStates.GS_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.jumpStates.GS_COUNTDOWN then
		self:InitStateCountdown()
	elseif self.gameState == self.jumpStates.GS_PLAY then
		self:InitStatePlay()
	elseif self.gameState == self.jumpStates.GS_SHOW_WINNERS then
		self:InitStateShowWinners()
	end

end


function JumpTargetClient:GetGameInResultsMode()

    if IsValid(self.raceStandings) and self.raceStandings:GetVisible() then
        return true
    end
    return false

end


function JumpTargetClient:RoundTimerSlot(timerParams)

	self.roundTimer = timerParams:GetParameterAtIndex(0, true):GetFloatData()

end


function JumpTargetClient:RoundStartTimeSlot(startTimeParams)

	self.roundStartTime = startTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end


function JumpTargetClient:PlayerStateSlot(playerStateParams)

	local playerID = ExtractPlayerIDFromState(playerStateParams:GetParameter(0, true))
	local newPlayerState = playerStateParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerState(player, newPlayerState)
	print("%%% Player " .. player:GetName() .. " changed to state: " .. self.jumpStates:PlayerStateToString(newPlayerState))

end


function JumpTargetClient:PlayerScoreSlot(scoreParams)

	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScore = scoreParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerScore(player, playerScore)

end


function JumpTargetClient:PlayerScoreTargetSlot(scoreParams)

	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScoreTargetName = scoreParams:GetParameter(0, true):GetStringData()

	local player = GetPlayerManager():GetPlayerFromID(playerID)

	--Play a celebration particle effect at this targets position
	local jumpTarget = self.jumpTargetManager:GetJumpTarget(playerScoreTargetName)
	if IsValid(jumpTarget) then
		local celebrationPoint = jumpTarget:GetPosition()
		GetParticleSystem():AddEffect("targethit", celebrationPoint)
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/targethit.wav", WVector3(), 0.6, 10, false, SoundSystem.HIGH)
	end

end


function JumpTargetClient:GetProcessSlot()

	return self.processSlot

end


function JumpTargetClient:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:InitPlayerState(player)

end


function JumpTargetClient:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:UnInitPlayerState(player)

end


function JumpTargetClient:CamSensorCallbackSlot(sensorParams)

	if self.gameState == self.jumpStates.GS_PLAY then
		local playerID = sensorParams:GetParameter("Player", true):GetIntData()
		local player = GetPlayerManager():GetPlayerFromID(playerID)

        if IsValid(player) and player:IsLocalPlayer() and not self.gotoCamControllerAdded then
            self.gotoCamControllerAdded = true
            GetCameraManager():AddController(self.gotoCamController, 3)
        end
	end

end


function JumpTargetClient:PlayerRespawnedSlot(respawnedParams)

	local playerID = respawnedParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	if IsValid(player) and player:IsLocalPlayer() then
	    self.gotoCamControllerAdded = false
		GetCameraManager():RemoveController(self.gotoCamController)
	end

end

--JUMPTARGETCLIENT CLASS END