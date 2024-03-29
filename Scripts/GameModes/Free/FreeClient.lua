UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("GUITimer", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")
UseModule("FreeStates", "Scripts\\GameModes\\Free\\")
UseModule("AchievementManager", "Scripts/")

--FreeClient CLASS START

class 'FreeClient' (IGameMode)

function FreeClient:__init(setMap) super()

    self.achievements = AchievementManager()

	self.map = setMap
	if not IsValid(self.map) then
		error("No map passed to GameMode Free in init")
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
    
    self:InitGUI()
    self.mainPlayer:SetGUIVisible(true)
    
    GetMenuManager():GetRoster():SetScoreSorting(true)
    
    self.gameStates = FreeStates()
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


function FreeClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("FreeClient", "IGameMode", "Manages the free game mode")

end

function FreeClient:InitGameMode()

    self.mainPlayer:SetGUIVisible(true)
    
end


function FreeClient:UnInitGameMode()

    self:UnInitGUI()
    
end



function FreeClient:Process()
    
    self:ProcessGUI()

end

function FreeClient:InitGUI()

	self.timerGUI = GUITimer()
	self.timerGUI:SetVisible(true)
	self.raceStandings = GUIRaceStandings()
	self.raceStandings:SetVisible(false)

	--Does the roster need to be updated?
	self.rosterDirty = true

end

function FreeClient:UnInitGUI()

	self.timerGUI:UnInit()
	self.timerGUI = nil

	self.raceStandings:UnInit()
	self.raceStandings = nil

end

function FreeClient:ProcessGUI()

	self:ProcessRoster()
	--self.countdownGUI:Process()
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
    
    if self.gameState == self.gameStates.GS_SHOW_WINNERS then
        self:ProcessStateShowWinners()
    end

end

function FreeClient:InitState()

	self.playerScoreSlot = self:CreateSlot("PlayerScoreSlot", "PlayerScoreSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.gameEndTimeSlot = self:CreateSlot("GameEndTimeSlot", "GameEndTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameEndTime", self.gameEndTimeSlot)

	--Jump settings
	self.roundTimerSlot = self:CreateSlot("RoundTimerSlot", "RoundTimerSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RoundTimer", self.roundTimerSlot)

end

function FreeClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState

	--UnInit old state
	if oldState == self.gameStates.GS_PLAY then
		--self:UnInitStatePlay()
	elseif oldState == self.gameStates.GS_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
    if self.gameState == self.gameStates.GS_PLAY then
		--self:InitStatePlay()
	elseif self.gameState == self.gameStates.GS_SHOW_WINNERS then
		self:InitStateShowWinners()
	end

end

function FreeClient:GameEndTimeSlot(endTimeParams)

	self.gameEndTime = endTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end

function FreeClient:RoundTimerSlot(timerParams)

	self.roundTimer = timerParams:GetParameterAtIndex(0, true):GetFloatData()

end

function FreeClient:PlayerScoreSlot(scoreParams)
    print("PlayerScoreSlot")
	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScore = scoreParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerScore(player, playerScore)

end

function FreeClient:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore
	--Update the roster with this new score
	self.rosterDirty = true

end

function FreeClient:GetPlayerScore(player)

	return player.userData.score

end

function FreeClient:ProcessRoster()

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


function FreeClient:GetProcessSlot()

	return self.processSlot

end

function FreeClient:ShowStandingsGUI(show)

	if show then
		--Update the standings
		local currentStandings = { }
		local i = 1
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			player:SetControllerEnabled(false)
			table.insert(currentStandings, { player, player.userData.score })
			i = i + 1
		end
		self.raceStandings:ShowStandings(currentStandings, false)
	else
		self.raceStandings:HideStandings()
	end
	self.timerGUI:SetVisible(not show)

end

function FreeClient:ProcessStateShowWinners(frameTime)
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

function FreeClient:InitStateShowWinners()

	self.timerGUI:SetTime(0)

    -- Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end
    
    self.mainPlayer:SetGUIVisible(false)

	--BRIAN TODO: String table?
	GetMenuManager():GetChat():AddMessage("#00ffda", "GAME OVER!")

	self:ShowStandingsGUI(true)

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


function FreeClient:GetSortedRoster()
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


function FreeClient:UnInitStateShowWinners()

	self:ShowStandingsGUI(false)
	-- Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)

end

function FreeClient:InitPlayerState(player)

    print("InitPlayerState: "..player:GetName())

	--Default values before watching their state in case their states is already known to the table
	--player.userData.state = self.jumpStates.PS_PLAY
	player.userData.score = 0

	--GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Score", self.playerScoreSlot)
	--GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_ScoreTarget", self.playerScoreTargetSlot)
	--GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_ScoreTarget", self.playerScoreTargetSlot)

	--Update the roster GUI
	self.rosterDirty = true

end

function FreeClient:ClientConnected(connectParams)

    local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	print("ClientConnected: "..player:GetName())
    self:InitPlayerState(player)
	self.rosterDirty = true

end


function FreeClient:ClientDisconnected(disconnectParams)

	self.rosterDirty = true

end

--FreeClient CLASS END