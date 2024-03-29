UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("AchievementManager", "Scripts/")
UseModule("SoccerStates", "Scripts\\GameModes\\Soccer\\")
UseModule("GUIRaceCountdown", "Scripts\\GameModes\\Race\\")
UseModule("GUIScoreTimer", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")

--SOCCERCLIENT CLASS START

class 'SoccerClient' (IGameMode)

function SoccerClient:__init(setMap) super()

	self.map = setMap
	if not IsValid(self.map) then
		error("No map passed to GameMode Soccer in init")
	end

    self.achievements = AchievementManager()
    self.shutout = 0
    self.redComeback = false
    self.blueComeback = false

	self.observeCamPos = WVector3()
	self.observeCamLookAt = WVector3(0, 0, 1)

	self:InitGUI()

	self.soccerStates = SoccerStates()
	self.gameState = self.soccerStates.GS_WAIT_FOR_PLAYERS

	--This when the countdown will begin
	self.countdownStartTime = 0

	--This is how long the round has been going on for
	self.gameClock = WTimer()

	--This is the global time that the game will end so the game timer is in sync
	self.gameEndTime = 0
	--Is the countdown GUI currently active?
	self.countdownActive = false

    self.lastRedScore = -1
    self.lastBlueScore = -1	
	self.scoreTimerGUI:ShowBlueScored(false)
	self.scoreTimerGUI:ShowRedScored(false)

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetClientWorld():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Get reference to the playerCam
	self.camera = GetCamera()

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

	--All name tags remain visible at all times in soccer
	--so that player colors can be seen for teams
	GetMenuManager():GetNameTagManager():SetForceAllVisible(true)

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


function SoccerClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("SoccerClient", "IGameMode", "Manages the soccer game mode")

end


function SoccerClient:InitGameMode()

end


function SoccerClient:UnInitGameMode()

	self:UnInitGUI()
	self:UnInitState()

end


function SoccerClient:InitState()

    self.playerStateSlot = self:CreateSlot("PlayerStateSlot", "PlayerStateSlot")
	self.playerScoreSlot = self:CreateSlot("PlayerScoreSlot", "PlayerScoreSlot")
	self.playerTeamSlot = self:CreateSlot("PlayerTeamSlot", "PlayerTeamSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.countdownStartTimeSlot = self:CreateSlot("CountdownStartTimeSlot", "CountdownStartTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("CountdownStartTime", self.countdownStartTimeSlot)

	self.gameEndTimeSlot = self:CreateSlot("GameEndTimeSlot", "GameEndTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameEndTime", self.gameEndTimeSlot)

	self.blueScoreSlot = self:CreateSlot("BlueScoreSlot", "BlueScoreSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("BlueScore", self.blueScoreSlot)

	self.redScoreSlot = self:CreateSlot("RedScoreSlot", "RedScoreSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RedScore", self.redScoreSlot)

    self.scoreTimerGUI:ShowBlueScored(false)
	self.scoreTimerGUI:ShowRedScored(false)
	self.scoreTimerGUI:HideWin()

end


function SoccerClient:UnInitState()

end

function SoccerClient:InitSoccerBall()

    print("LOOKING FOR THE BALL")

	local objIter = GetClientWorld():GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetTypeName() == "ScriptObject" then
			local scriptObject = ToScriptObject(worldObject)
			if scriptObject:GetScriptObjectTypeName() == "SyncedBall" then
			    self.ball = scriptObject:Get()
			end
		end
		objIter:Next()
	end

end

function SoccerClient:InitPlayerState(player)

    print("Initing state for player named: " .. player:GetName() .. " in SoccerClient")

	--Default values before watching their state in case their states is already known to the table
	player.userData.state = self.soccerStates.PS_NOT_PLAYING
	player.userData.score = 0
	player.userData.teamID = ""

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Score", self.playerScoreSlot)

	print("Watching team state for player named: " .. player:GetName() .. " in SoccerClient")

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Team", self.playerTeamSlot)

	print("Done watching team state for player named: " .. player:GetName() .. " in SoccerClient")

	--Set the flag to update the roster later
	self.rosterDirty = true
    
end


function SoccerClient:UnInitPlayerState(player)

	--Set the flag to update the roster later
	self.rosterDirty = true

end


function SoccerClient:InitGUI()

	self.countdownGUI = GUIRaceCountdown()
	self.scoreTimerGUI = GUIScoreTimer()
	--self.standings = GUIRaceStandings()
	--self.standings:SetVisible(false)
	
    --GUI Overlay point to arrow indicator init
	self.overlayITIndicator = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "arrow2b.mesh"))
	self.overlayITIndicator:SetName("ITOverlayIndicator")
	self.overlayITIndicator:Init(params)
	self.overlayITIndicator:SetCastShadows(false)
	self.overlayITIndicator:SetReceiveShadows(false)
	self.overlayITIndicator:SetScale(WVector3(0.5, 0.5, 0.5))
	self.overlayITIndicator:SetOverlay(true, false)
	self.overlayITIndicator:SetPosition(WVector3(0, 0.3, -1))

	--Does the roster need to be updated?
	self.rosterDirty = true

	--We will control the roster
	GetMenuManager():GetRoster():SetManuallyControlled(true)
	
	self.scoreTimerGUI:ShowBlueScored(false)
	self.scoreTimerGUI:ShowRedScored(false)

end


function SoccerClient:UnInitGUI()

	self.countdownGUI:UnInit()
	self.countdownGUI = nil

	self.scoreTimerGUI:UnInit()
	self.scoreTimerGUI = nil

	--self.standings:UnInit()
	--self.standings = nil

    self.overlayITIndicator:UnInit()
	self.overlayITIndicator = nil

	--We no longer control the roster
	GetMenuManager():GetRoster():SetManuallyControlled(false)

end


function SoccerClient:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState

    if player == self.mainPlayer then
        if newPlayerState == self.soccerStates.PS_PLAYING then
		    self:SetLoadingAllowed(false)
        elseif newPlayerState == self.soccerStates.PS_NOT_PLAYING then
            self:SetLoadingAllowed(true)
        elseif newPlayerState == self.soccerStates.PS_SHOW_WINNERS then
            self:SetLoadingAllowed(true)
        end
    end

end


function SoccerClient:GetPlayerState(player)

	return player.userData.state

end


function SoccerClient:SetPlayerScore(player, playerScore)

	player.userData.score = playerScore

	self.rosterDirty = true

end


function SoccerClient:GetPlayerScore(player)

	return player.userData.score

end

function SoccerClient:PaintKart(player)

    if player.userData.teamID == "Red" then
		GetMenuManager():GetNameTagManager():SetPlayerColor(player:GetUniqueID(), 1, 0, 0)
		if player:GetUniqueID() == GetPlayerManager():GetLocalPlayer():GetUniqueID() then
            self.scoreTimerGUI:SetTeam(true)
        end
        if --[[player ~= GetPlayerManager():GetLocalPlayer() and--]] IsValid(player:GetController()) and IsValid(player:GetController().graphicalKart) then
          
            player:GetController().graphicalKart:SetKartColor("Color1", 1, 0, 0, 1)
            player:GetController().graphicalKart:SetKartColor("Color2", 1, 0, 0, 1)
            player:GetController().graphicalKart:SetKartColor("Color3", 1, 0, 0, 1)
            player:GetController().graphicalKart:SetKartColor("Color4", 1, 0, 0, 1)
            player.userData.painted = true
        end
	elseif player.userData.teamID == "Blue" then
        GetMenuManager():GetNameTagManager():SetPlayerColor(player:GetUniqueID(), 65/255, 150/255, 1)
		if player:GetUniqueID() == GetPlayerManager():GetLocalPlayer():GetUniqueID() then
            self.scoreTimerGUI:SetTeam(false)
        end
        if --[[player ~= GetPlayerManager():GetLocalPlayer() and--]] IsValid(player:GetController()) and IsValid(player:GetController().graphicalKart) then
            player:GetController().graphicalKart:SetKartColor("Color1", 65/255, 150/255, 1, 1)
            player:GetController().graphicalKart:SetKartColor("Color2", 65/255, 150/255, 1, 1)
            player:GetController().graphicalKart:SetKartColor("Color3", 65/255, 150/255, 1, 1)
            player:GetController().graphicalKart:SetKartColor("Color4", 65/255, 150/255, 1, 1)
            player.userData.painted = true
        end
	end

end

function SoccerClient:SetPlayerTeam(player, playerTeam)

    print("SoccerClient:SetPlayerTeam("..player:GetName()..", "..playerTeam..")")

	player.userData.teamID = playerTeam
    player.userData.painted = false

	self:PaintKart(player)

	self.rosterDirty = true

end


function SoccerClient:GetPlayerTeam(player)

	return player.userData.teamID

end


function SoccerClient:Process()

	PUSH_PROFILE("SoccerClient:Process()")

	local updateTimer = true
	if self.gameState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers()
		updateTimer = false
	elseif self.gameState == self.soccerStates.GS_COUNTDOWN then
		self:ProcessStateCountdown()
	elseif self.gameState == self.soccerStates.GS_PLAY then
		self:ProcessStatePlay()
	elseif self.gameState == self.soccerStates.GS_GOAL_SCORED then
		self:ProcessStateGoalScored()
	elseif self.gameState == self.soccerStates.GS_SHOW_WINNERS then
		self:ProcessStateShowWinners()
		updateTimer = false
	end

	if updateTimer then
		self.scoreTimerGUI:SetTime(self.gameEndTime - GetClientSystem():GetTime()+1)
	end

    -- check if we need to paint our kart
    
    --print("mainPaint: "..tostring(self.mainPlayer.userData.painted))
    if not IsValid(self.lastPaint) or GetClientSystem():GetTime() - self.lastPaint > 2 then
        local i = 1
        local numPlayers = GetPlayerManager():GetNumberOfPlayers()
        while i <= numPlayers do
            local player = GetPlayerManager():GetPlayer(i)
            if --[[player.userData.painted == false and--]] IsValid(player:GetController()) then
                --print("FORCING PAINT")
                self:PaintKart(player)
            end
            i = i + 1
        end
        self.lastPaint = GetClientSystem():GetTime()
    end

	self:ProcessGUI()

	POP_PROFILE("SoccerClient:Process()")

end


function SoccerClient:ProcessGUI()

	self:ProcessRoster()

	self.countdownGUI:Process()

end


function SoccerClient:ProcessRoster()

	if self.rosterDirty then
		local rosterList = { }
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		local i = 1
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			local setColor = "FFFFFF"
			if self:GetPlayerTeam(player) == "Blue" then
				setColor = "4196ff"
			elseif self:GetPlayerTeam(player) == "Red" then
				setColor = "FF0000"
			end
			local playerData = { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor, 
								 score = player.userData.score, teamID = player.userData.teamID, ping = 0, kick = 0, audioMute = 0, visualMute = 0 }
			table.insert(rosterList, playerData)
			i = i + 1
		end
		--Sort the Red players first
		--BRIAN TODO: SoccerClient.lua:271: invalid order function for sorting
		--table.sort(rosterList, function(playerA, playerB) if (playerA.teamID == "Red") then return true else return false end end)
		GetMenuManager():GetRoster():UpdateRoster(rosterList)
		self.rosterDirty = false
	end

end

--[[
function SoccerClient:ShowStandingsGUI(show)

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
		self.standings:ShowStandings(currentStandings, false)
	else
		self.standings:HideStandings()
	end

end
--]]

function SoccerClient:InitStateWaitForPlayers()

	--Nothing to init here
	self.mainPlayer:SetGUIVisible(true)

end


function SoccerClient:UnInitStateWaitForPlayers()

	--Nothing to uninit here
	self.mainPlayer:SetGUIVisible(true)

end


function SoccerClient:InitStateCountdown()

	self.countdownActive = false
	self.mainPlayer:SetGUIVisible(true)

end


function SoccerClient:UnInitStateCountdown()

	--Nothing to uninit here
	self.mainPlayer:SetGUIVisible(true)

end


function SoccerClient:InitStatePlay()

	--Nothing to init here
	self.mainPlayer:SetGUIVisible(true)
	
end


function SoccerClient:UnInitStatePlay()

	--Nothing to uninit here

end


function SoccerClient:InitStateGoalScored()

	--Nothing to init here

end


function SoccerClient:UnInitStateGoalScored()

	--Nothing to uninit here

end


function SoccerClient:InitStateShowWinners()

    local timeLeft = self.gameEndTime - GetClientSystem():GetTime()+1
    print("Time left at win: "..timeLeft)

	self.scoreTimerGUI:SetTime(0)

	--BRIAN TODO: String table?
	GetMenuManager():GetChat():AddMessage("#00ffda","GAME OVER!")

    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/buzzer.wav", WVector3(), 1.0, 10, false, SoundSystem.HIGH)

    self.scoreTimerGUI:ShowBlueScored(false)
	self.scoreTimerGUI:ShowRedScored(false)

	--self:ShowStandingsGUI(true)
	if self.lastRedScore == self.lastBlueScore then
	
	else
        self.scoreTimerGUI:ShowWin(self.lastRedScore > self.lastBlueScore)
    end
	
	-- Track shutouts for achievement
	local winningTeam = nil
	local loserScore = 0
	if self.lastRedScore > self.lastBlueScore then
	    winningTeam = "Red"
	    loserScore = self.lastBlueScore
	else
	    winningTeam = "Blue"
	    loserScore = self.lastRedScore
	end
	if IsValid(self.mainPlayer.userData.teamID) then
	    print("Player Team: " .. self.mainPlayer.userData.teamID)
	else
	    print("Player has no team")
	end
	print("Winning Team: " .. winningTeam)
	print("Loser Score: " .. loserScore)
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	if numPlayers > 1 then
        if self.mainPlayer.userData.teamID ~= winningTeam then
            self.shutout = 0
        elseif self.mainPlayer.userData.teamID == winningTeam then
            if loserScore == 0 then
                self.shutout = self.shutout + 1
            end
            if timeLeft < 0 then
                self.achievements:Unlock(self.achievements.AVMT_NAIL_BITER)
            end
        else
            self.shutout = 0
        end
        print("Shutout count: "..self.shutout)
        if self.shutout == 2 then
            self.achievements:Unlock(self.achievements.AVMT_COMPLETE_SHUTOUT)
        end
    end
	
	-- Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end
    
    self.mainPlayer:SetGUIVisible(false)

    self:CheckGentlemansWager()
	self:CheckPirateParty()
	self:CheckWargames()
	self:CheckInspectorKemp()
	self:CheckTermination()

    --Check for comeback
    print("redComeback: "..tostring(self.redComeback))
    print("blueComeback: "..tostring(self.blueComeback))
    if self.redComeback and winningTeam == "Red" and self.mainPlayer.userData.teamID == "Red" and numPlayers > 1 then
        self.achievements:Unlock(self.achievements.AVMT_COMEBACK)
    end
    if self.blueComeback and winningTeam == "Blue" and self.mainPlayer.userData.teamID == "Blue" and numPlayers > 1 then
        self.achievements:Unlock(self.achievements.AVMT_COMEBACK)
    end
    self.redComeback = false
    self.blueComeback = false

	--BRIAN TODO: Need a better way to do this, GetController doesnt exist anymore
	--GetCameraManager():GetController("FreeMovement"):SetForcePosition(self.observeCamPos)
	--GetCameraManager():GetController("FreeMovement"):SetForceLookAt(self.observeCamLookAt)

end


function SoccerClient:UnInitStateShowWinners()

	--self:ShowStandingsGUI(false)
	self.scoreTimerGUI:HideWin()
	
	-- Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)

end


--Waiting for more players
function SoccerClient:ProcessStateWaitForPlayers()

end


--Countdown, game is about to start
function SoccerClient:ProcessStateCountdown()

	--The countdown doesn't start until after the time in self.countdownStartTime
	if self.countdownStartTime > 0 and GetClientSystem():GetTime() >= self.countdownStartTime and not self.countdownActive then
		print("SoccerClient:ProcessStateCountdown() countdownGUI:Start: "..tostring(self.countdownStartTime+3))
        self.countdownGUI:Start(self.countdownStartTime+3)
		self.countdownActive = true
		self.countdownStartTime = 0
	end

end


function SoccerClient:ProcessStatePlay()

    if not IsValid(self.ball) then
        self:InitSoccerBall()
        self.overlayITIndicator:SetVisible(false)
    else 

        self.overlayITIndicator:SetVisible(true)
        --Update the overlay indicator of the position of the IT indicator
        local arrowPos = self.mainPlayer:GetPosition()
        local camToIT = self.ball:GetGraphicalPosition() - self.camera:GetPosition()
        camToIT:Normalise()
        local kartToIT = self.ball:GetGraphicalPosition() - self.mainPlayer:GetPosition()
        kartToIT:Normalise()
        arrowPos = arrowPos + camToIT*1.25
        self.overlayITIndicator:SetPosition(arrowPos)
        if kartToIT.x ~= 0 or kartToIT.y ~= 0 or kartToIT.z ~= 0 then
            self.overlayITIndicator:SetDirection(kartToIT)
        end
        
     end

end


function SoccerClient:ProcessStateGoalScored()

end


function SoccerClient:ProcessStateShowWinners()

end


function SoccerClient:GetGameState()

	return self.gameState

end


function SoccerClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState
	print("%%% New Soccer gamestate: " .. self.soccerStates:GameStateToString(self.gameState))

    self.scoreTimerGUI:ShowBlueScored(false)
	self.scoreTimerGUI:ShowRedScored(false)

	--UnInit old state
	if oldState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.soccerStates.GS_COUNTDOWN then
		self:UnInitStateCountdown()
	elseif oldState == self.soccerStates.GS_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.soccerStates.GS_GOAL_SCORED then
		self:UnInitStateGoalScored()
		self.scoreTimerGUI:ShowBlueScored(false)
		self.scoreTimerGUI:ShowRedScored(false)
	elseif oldState == self.soccerStates.GS_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.soccerStates.GS_WAIT_FOR_PLAYERS then
		self:InitStateWaitForPlayers()
		self.overlayITIndicator:SetVisible(false)
	elseif self.gameState == self.soccerStates.GS_COUNTDOWN then
		self:InitStateCountdown()
		self.overlayITIndicator:SetVisible(false)
	elseif self.gameState == self.soccerStates.GS_PLAY then
		self:InitStatePlay()
	elseif self.gameState == self.soccerStates.GS_GOAL_SCORED then
		self:InitStateGoalScored()
		self.overlayITIndicator:SetVisible(false)
	elseif self.gameState == self.soccerStates.GS_SHOW_WINNERS then
		self:InitStateShowWinners()
		self.overlayITIndicator:SetVisible(false)
	end

end


function SoccerClient:GetGameInResultsMode()

    if IsValid(self.scoreTimerGUI) and (self.scoreTimerGUI.redWin:IsVisible() or self.scoreTimerGUI.blueWin:IsVisible()) then
        return true
    end
    return false

end


function SoccerClient:CountdownStartTimeSlot(timeParams)

    self.countdownStartTime = timeParams:GetParameter(0, true):GetFloatData()

    print("SoccerClient: countdownStartTime = "..self.countdownStartTime)
    print("SoccerClient: current client time= "..GetClientSystem():GetTime())

    if self.countdownStartTime < GetClientSystem():GetTime() then
        print("countdownStartTime out of sync")
        self.countdownStartTime = 0
    end

end


function SoccerClient:GameEndTimeSlot(startTimeParams)

	self.gameEndTime = startTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end


function SoccerClient:BlueScoreSlot(scoreParams)

	local blueScore = scoreParams:GetParameterAtIndex(0, true):GetIntData()
	self.scoreTimerGUI:SetRightScore(blueScore)
	if self.lastBlueScore ~= -1 and blueScore > 0 then
        self.scoreTimerGUI:ShowBlueScored(true)
    end
    self.lastBlueScore = blueScore
    
    -- check for comeback
    if self.lastBlueScore - self.lastRedScore >= 2 then
        self.redComeback = true
        print("Red comeback possible")
    end
end


function SoccerClient:RedScoreSlot(scoreParams)

	local redScore = scoreParams:GetParameterAtIndex(0, true):GetIntData()
	self.scoreTimerGUI:SetLeftScore(redScore)
	if self.lastRedScore ~= -1 and redScore > 0 then
        self.scoreTimerGUI:ShowRedScored(true)
    end
    self.lastRedScore = redScore

    -- check for comeback
    if self.lastRedScore - self.lastBlueScore >= 2 then
        self.blueComeback = true
        print("Blue comeback possible")
    end
end


function SoccerClient:PlayerStateSlot(playerStateParams)

	local playerID = ExtractPlayerIDFromState(playerStateParams:GetParameter(0, true))
	local newPlayerState = playerStateParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	--BRIAN TODO: Why is a nil player here possible??
	if IsValid(player) then
		self:SetPlayerState(player, newPlayerState)
		print("%%% Player " .. player:GetName() .. " changed to state: " .. self.soccerStates:PlayerStateToString(newPlayerState))
	end

end


function SoccerClient:PlayerScoreSlot(scoreParams)

	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScore = scoreParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerScore(player, playerScore)

end


function SoccerClient:PlayerTeamSlot(teamParams)

	local playerID = ExtractPlayerIDFromState(teamParams:GetParameter(0, true))
	local playerTeamID = teamParams:GetParameterAtIndex(0, true):GetStringData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

    print("SoccerClient:PlayerTeamSlot:"..tostring(playerID)..","..tostring(playerTeamID)..","..player:GetName())

    if not IsValid(playerTeamID) or not (playerTeamID == "Red" or playerTeamID == "Blue") then
        error("Invalid Player Team")
    end

    self:SetPlayerTeam(player, playerTeamID)

end


function SoccerClient:GetProcessSlot()

	return self.processSlot

end


function SoccerClient:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:InitPlayerState(player)

end


function SoccerClient:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	self:UnInitPlayerState(player)

end

--SOCCERCLIENT CLASS END