UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("ReverseTagStates", "Scripts\\GameModes\\ReverseTag\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")
UseModule("ReverseTagGUI", "Scripts\\GameModes\\ReverseTag\\")
UseModule("AchievementManager", "Scripts/")

--REVERSETAGCLIENT CLASS START

class 'ReverseTagClient' (IGameMode)

function ReverseTagClient:__init(setMap) super()

	self.map = setMap
	if not IsValid(self.map) then
        error("No map passed to GameMode ReverseTag in init")
	end

	self:InitGUI()

	self.tagStates = ReverseTagStates()
	
	self.achievements = AchievementManager()

	self.invulTimer = 3
	self.invulStartTime = 0
	self.invulSwitchClock = WTimer()
	self.invulSwitchTimer = 0.1
	self.tagWinScore = 0
	
	self.modeOverlayClock = WTimer()
	self.modeOverlayTime = 5
	
	self.gameClock = WTimer()
	self:SetLoadingAllowed(true)

    GetMenuManager():GetRoster():SetScoreSorting(true)

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	--Process after the ClientWorld so the player positions are set correctly
	GetClientWorld():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Which player is IT? this variable will tell us
	self.ITPlayer = nil
	self.ITRespawnPos = WVector3()

	--Get reference to the playerCam
	self.camera = GetCamera()

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

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

	self:LoadMapSettings(self.map)
		
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


function ReverseTagClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("ReverseTagClient", "IBase", "The client ReverseTag game mode manager")

end


function ReverseTagClient:InitGameMode()

end


function ReverseTagClient:UnInitGameMode()

	self:UnInitGUI()
	self:UnInitState()

end


function ReverseTagClient:InitState()

	self.playerStateSlot = self:CreateSlot("PlayerStateSlot", "PlayerStateSlot")
	self.playerScoreSlot = self:CreateSlot("PlayerScoreSlot", "PlayerScoreSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.invulStartTimeSlot = self:CreateSlot("InvulStartTimeSlot", "InvulStartTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("InvulStartTime", self.invulStartTimeSlot)
	
	self.tagWinScoreSlot = self:CreateSlot("TagWinScoreSlot", "TagWinScoreSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("TagWinScore", self.tagWinScoreSlot)

	--Tag settings
	self.tagSettingsSlot = self:CreateSlot("TagSettingsSlot", "TagSettingsSlot")
	--InvulTimer
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("InvulTimer", self.tagSettingsSlot)

end


function ReverseTagClient:UnInitState()

end


function ReverseTagClient:InitPlayerState(player)

	--Default values before watching their state in case their states is already known to the table
	player.userData.state = self.tagStates.PLAYER_STATE_NOT_IT
	player.userData.score = 0

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Score", self.playerScoreSlot)

	self.rosterDirty = true

end


function ReverseTagClient:UnInitPlayerState(player)

	self.rosterDirty = true

end


function ReverseTagClient:InitGUI()

	--This is the visual indicator of who is it, displayed above their head
	self.ITIndicator = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "arrow.mesh"))
	self.ITIndicator:SetName("ITIndicator")
	self.ITIndicator:Init(params)
	self.ITIndicator:SetCastShadows(false)
	self.ITIndicator:SetReceiveShadows(false)
	self.ITIndicatorHalfHeight = self.ITIndicator:GetBoundingBox():GetHeight() / 2
	--Set the base scale for later
	self.ITIndicatorBaseScale = 0.1
	--Start out as not an overlay
	self.ITIndicator:SetOverlay(false, false)
	--The idle animation for the IT indicator
	self.ITIndicatorAnim = self.ITIndicator:GetAnimation("idle", true)
	self.ITIndicatorAnim:Play()

    --This is the visual indicator of who is it, displayed above their head
	self.ITBIndicator = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "arrowb.mesh"))
	self.ITBIndicator:SetName("ITBIndicator")
	self.ITBIndicator:Init(params)
	self.ITBIndicator:SetCastShadows(false)
	self.ITBIndicator:SetReceiveShadows(false)
	self.ITBIndicatorHalfHeight = self.ITIndicator:GetBoundingBox():GetHeight() / 2
	--Set the base scale for later
	self.ITBIndicatorBaseScale = 0.1
	--Start out as not an overlay
	self.ITBIndicator:SetOverlay(false, false)
	--The idle animation for the IT indicator
	self.ITBIndicatorAnim = self.ITBIndicator:GetAnimation("idle", true)
	self.ITBIndicatorAnim:Play()
	self.ITBIndicator:SetVisible(false)

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
	
	self.overlayITBIndicator = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "arrow2.mesh"))
	self.overlayITBIndicator:SetName("ITOverlayIndicator")
	self.overlayITBIndicator:Init(params)
	self.overlayITBIndicator:SetCastShadows(false)
	self.overlayITBIndicator:SetReceiveShadows(false)
	self.overlayITBIndicator:SetScale(WVector3(0.5, 0.5, 0.5))
	self.overlayITBIndicator:SetOverlay(true, false)
	self.overlayITBIndicator:SetPosition(WVector3(0, 0.3, -1))

    -- Particles
    self.scoreParticles = {}
    for i=0,11 do
        self.scoreParticles[i] = OGREParticleEffect()
        local boostParams = Parameters()
        if i == 11 then
            boostParams:AddParameter(Parameter("ResourceName", "respawn"))
        else
            boostParams:AddParameter(Parameter("ResourceName", "plus_"..i))
        end
        boostParams:AddParameter(Parameter("Loop", false))
        boostParams:AddParameter(Parameter("StartOnLoad", false))
        self.scoreParticles[i]:SetName("plus_" .. tostring(i) .. "_" .. tostring(GenerateID()))
        self.scoreParticles[i]:Init(boostParams)
    end
    self.testParticle = OGREParticleEffect()
	local boostParams = Parameters()
	boostParams:AddParameter(Parameter("ResourceName", "plus_1"))
	boostParams:AddParameter(Parameter("Loop", false))
	boostParams:AddParameter(Parameter("StartOnLoad", false))

	self.testParticle:SetName("plus_1" .. tostring(GenerateID()))
	self.testParticle:Init(boostParams)

	self.standings = GUIRaceStandings()
	self.standings:SetVisible(false)

	--Does the roster need to be updated?
	self.rosterDirty = true
	
	-- Create our ReverseTagGUI
	self.reverseTagGUI = ReverseTagGUI()

    

end


function ReverseTagClient:UnInitGUI()

	self.ITIndicator:UnInit()
	self.ITIndicator = nil
	
	self.ITBIndicator:UnInit()
	self.ITBIndicator = nil

	self.overlayITIndicator:UnInit()
	self.overlayITIndicator = nil

    self.overlayITBIndicator:UnInit()
	self.overlayITBIndicator = nil

	self.standings:UnInit()
	self.standings = nil

    for i=0,11 do
        if IsValid(self.scoreParticles[i]) then
            self.scoreParticles[i]:UnInit()
            self.scoreParticles[i] = nil
        end
    end

    self.reverseTagGUI:UnInit()
    self.reverseTagGUI = nil

	--We no longer control the roster
	--GetMenuManager():GetRoster():SetManuallyControlled(false)

end


function ReverseTagClient:LoadMapSettings(fromMap)

	--IT Spawn Position
	local ITSpawnPos = self.map:GetSetting("ITSpawnPosition", false)
	if IsValid(ITSpawnPos) then
	    self.ITRespawnPos = ITSpawnPos:GetWVector3Data()
	    self.ITIndicator:SetPosition(self.ITRespawnPos)
	    print("self.ITRespawnPos: " .. tostring(self.ITRespawnPos))
	end

end


function ReverseTagClient:SetPlayerState(player, newPlayerState)

	--Is this player currently IT?
	if self.tagStates:IsPlayerIT(player.userData.state) then
		--Are they no longer IT?
		if not self.tagStates:IsPlayerIT(newPlayerState) then
			self:PlayerIT(0)
		end
	end

	player.userData.state = newPlayerState

	--Is this player the new IT?
	if self.tagStates:IsPlayerIT(player.userData.state) then
		self:PlayerIT(player:GetUniqueID())
		self.reverseTagGUI:SetScoreBarName(player:GetName())
		self.reverseTagGUI:SetScoreBar(player.userData.score/self.tagWinScore)
		--Play the IT change sound
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/bell.wav", player:GetPosition(), 10, 1, false, SoundSystem.HIGH)
	end
	
	if player == self.mainPlayer then
	    if newPlayerState == self.tagStates.PLAYER_STATE_IT and self.gameClock:GetTimeSeconds() > 5 then
            self:SetLoadingAllowed(false)
        elseif newPlayerState == self.tagStates.PLAYER_STATE_NOT_IT and self.gameClock:GetTimeSeconds() > 5 then
            self:SetLoadingAllowed(false)
        elseif newPlayerState == self.tagStates.PLAYER_STATE_SHOW_WINNERS then
            self:SetLoadingAllowed(true)
        end
	end
	
	-- HACK
	--if self.gameClock:GetTimeSeconds() > 5 then
	--    self:SetLoadingAllowed(true)
	--end

end


function ReverseTagClient:GetPlayerState(player)

	return player.userData.state

end


function ReverseTagClient:SetPlayerScore(player, playerScore)

    -- emit particle
    --print("Showing score particles")
    for i=0,11 do
        self.scoreParticles[i]:SetPosition(player:GetPosition())
    end
    
    if playerScore < 0 then
        playerScore = 0
    end
    
    local scoreChange = playerScore - player.userData.score
    if scoreChange > 0 and scoreChange < 11 then
        self.scoreParticles[scoreChange]:Start()
        if player == self.mainPlayer then
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/bell.wav", WVector3(), 0.25, 1, false, SoundSystem.LOW)
        end
    elseif scoreChange < -5 then
        self.scoreParticles[11]:Start()
    elseif scoreChange < 0 then
        self.scoreParticles[0]:Start()
        if player == self.mainPlayer then
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/countdown_single.wav", WVector3(), 0.5, 1, false, SoundSystem.LOW)
        end
    end

	player.userData.score = playerScore

    if player == self.ITPlayer then
        self.reverseTagGUI:SetScoreBar(self.ITPlayer.userData.score/self.tagWinScore)
    end

	self.rosterDirty = true

    --BRIAN TODO: Temp code until we have a working roster again
	--GetMenuManager():GetChat():AddMessage("#00ffda", player:GetName() .. " score: " .. tostring(player.userData.score))

end


function ReverseTagClient:GetPlayerScore(player)

	return player.userData.score

end


function ReverseTagClient:Process()

	local frameTime = GetFrameTime()

	if self.gameState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers(frameTime)
	elseif self.gameState == self.tagStates.GAME_STATE_PLAY or self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
		self:ProcessStatePlay(frameTime)
	elseif self.gameState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
	end

	self:ProcessGUI(frameTime)

end


function ReverseTagClient:ProcessGUI(frameTime)

	--Update the animation
	self.ITIndicatorAnim:Process(frameTime)
    self.ITBIndicatorAnim:Process(frameTime)
	self:ProcessRoster(frameTime)

end


function ReverseTagClient:ProcessRoster(frameTime)

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
			if player == self.ITPlayer then
				setColor = "FF00CC"
			end
			local playerData = { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor, 
								 score = player.userData.score, ping = 0, kick = 0, audioMute = 0, visualMute = 0 }
			table.insert(rosterList, playerData)
			i = i + 1
		end
		--table.sort(rosterList, function(playerA, playerB) return playerA.score > playerB.score end)
		GetMenuManager():GetRoster():UpdateRoster(rosterList)
		self.rosterDirty = false
	end

end

function ReverseTagClient:GetSortedRoster()
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

function ReverseTagClient:InitStateWaitForPlayers()

	--Nothing to init here
	self.mainPlayer:SetGUIVisible(true)

end


function ReverseTagClient:UnInitStateWaitForPlayers()

	--Nothing to uninit here

end


function ReverseTagClient:InitStatePlay()

    self.mainPlayer:SetGUIVisible(true)

    if self.ITPlayer and self.ITPlayer:GetUniqueID() == GetPlayerManager():GetLocalPlayer():GetUniqueID() then
		self.overlayITIndicator:SetVisible(false)
		self.overlayITBIndicator:SetVisible(false)	
	else
	    print("Setting IT visible")
	    self.overlayITIndicator:SetVisible(true)
        self.overlayITBIndicator:SetVisible(false)    
	end
	self.ITIndicator:SetVisible(true)
    self.ITBIndicator:SetVisible(false) 
	--self.tagPositiveOverlay:SetVisible(true)
	self.reverseTagGUI:ShowPositiveAlert(true)
	self.modeOverlayClock:Reset()
	GetSoundSystem():EmitSound(ASSET_DIR .. "sound/alarm.wav", self.mainPlayer:GetPosition(), 10, 1, false, SoundSystem.HIGH)
	
end


function ReverseTagClient:UnInitStatePlay()

	--self.tagPositiveOverlay:SetVisible(false)
	self.reverseTagGUI:ShowPositiveAlert(false)

end

function ReverseTagClient:InitStatePlayReverse()

    if self.ITPlayer and self.ITPlayer:GetUniqueID() == GetPlayerManager():GetLocalPlayer():GetUniqueID() then
		self.overlayITIndicator:SetVisible(false)
		self.overlayITBIndicator:SetVisible(false)	
	else
	    print("Setting ITB visible")
	    self.overlayITIndicator:SetVisible(false)
        self.overlayITBIndicator:SetVisible(true)    
	end
	self.ITIndicator:SetVisible(false)
    self.ITBIndicator:SetVisible(true) 
	--self.tagNegativeOverlay:SetVisible(true)
	self.reverseTagGUI:ShowNegativeAlert(true)
	self.modeOverlayClock:Reset()
	GetSoundSystem():EmitSound(ASSET_DIR .. "sound/alarm.wav", self.mainPlayer:GetPosition(), 10, 1, false, SoundSystem.HIGH)
	
end

function ReverseTagClient:UnInitStatePlayReverse()

	--self.tagNegativeOverlay:SetVisible(false)
	self.reverseTagGUI:ShowNegativeAlert(false)

end

function ReverseTagClient:InitStateShowWinners()

    -- Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end

    self.mainPlayer:SetGUIVisible(false)

	--BRIAN TODO: String table?
	GetMenuManager():GetChat():AddMessage("#00ffda", "GAME OVER!")
	self.ITIndicator:SetVisible(false)
	self.ITBIndicator:SetVisible(false)
	self.overlayITIndicator:SetVisible(false)
    self.overlayITBIndicator:SetVisible(false)

	self:ShowStandingsGUI(true)

    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/AMB_Goal.wav", WVector3(), 0.6, 10, false, SoundSystem.MEDIUM)
    
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


function ReverseTagClient:UnInitStateShowWinners()

	self.ITIndicator:SetVisible(true)
	self.overlayITIndicator:SetVisible(true)

	self:ShowStandingsGUI(false)
	
	-- Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)
    self.mainPlayer.userData.tag = 0

end


--Waiting for more players
function ReverseTagClient:ProcessStateWaitForPlayers(frameTime)

end


function ReverseTagClient:ProcessStatePlay(frameTime)

	--Calculate the distance for later
    local it = self.ITIndicator
    if self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
        it = self.ITBIndicator
    end
    local dist = self.camera:GetPosition():Distance(it:GetWorldPosition());
	if dist == 0 then
		dist = 0.01
	end

	if IsValid(self.ITPlayer) then
		local playerObject = self.ITPlayer:GetController()
		if not IsValid(playerObject) then
			print("Player " .. self.ITPlayer:GetName() .. " doesn't own a controller")
			return
		end

        --BRIAN TODO: Duplicate code that can be generalized, #ModelPositionedOverHead
		local playerPosition = playerObject:GetGraphicalPosition()
		local controllerHalfHeight = playerObject:GetBoundingBox():GetHeight() / 2
		local addToY = controllerHalfHeight + self.ITIndicatorHalfHeight
		it:SetPosition(playerPosition + WVector3(0, addToY * (dist * self.ITIndicatorBaseScale), 0))

		--Only scale the ITIndicator when somebody is IT, otherwise default to 1
		--Scale the size of the ITIndicator based on distance from the camera
		it:SetScale(WVector3(dist * self.ITIndicatorBaseScale,
										   dist * self.ITIndicatorBaseScale,
										   dist * self.ITIndicatorBaseScale))
	else
		--Nobody is it, indicator stays at the spawn pos
		it:SetPosition(self.ITRespawnPos)
		it:SetScale(WVector3(4, 4, 4))
	end

	--Update the overlay indicator of the position of the IT indicator
	local arrowPos = self.mainPlayer:GetPosition()
    local camToIT = it:GetWorldPosition() - self.camera:GetPosition()
	camToIT:Normalise()
	local kartToIT = it:GetWorldPosition() - self.mainPlayer:GetPosition()
	kartToIT:Normalise()
    arrowPos = arrowPos + camToIT*1.25
	self.overlayITIndicator:SetPosition(arrowPos)
	self.overlayITBIndicator:SetPosition(arrowPos)
    if kartToIT.x ~= 0 or kartToIT.y ~= 0 or kartToIT.z ~= 0 then
		self.overlayITIndicator:SetDirection(kartToIT)
		self.overlayITBIndicator:SetDirection(kartToIT)
	end

	--Handle invul display
	if IsValid(self.ITPlayer) then
		if GetClientSystem():GetTime() < self.invulStartTime + self.invulTimer then
			--Still invul!
			if self.invulSwitchClock:GetTimeSeconds() > self.invulSwitchTimer then
				self.invulSwitchClock:Reset()
				self.ITPlayer:GetController():SetVisible(not self.ITPlayer:GetController():GetVisible())
			end
			self.ITPlayer:GetController():SetDraftEnabled(0)
		else
			--Not invul anymore
			self.ITPlayer:GetController():SetVisible(true)
			self.ITPlayer:GetController():SetDraftEnabled(0)
		end
	end
	

    -- process particles
    if self.scoreParticles[0]:GetPosition():GetY() > -1000 then
        for i=0,10 do
            self.scoreParticles[i]:Process(frameTime)
            if IsValid(self.ITPlayer) then    
                self.scoreParticles[i]:SetPosition(self.ITPlayer:GetGraphicalPosition())
            end
        end
    end
    self.scoreParticles[11]:SetPosition(self.mainPlayer:GetGraphicalPosition())
    self.scoreParticles[11]:Process(frameTime)
    -- test whether to hide the mode overlay
	if self.modeOverlayClock:GetTimeSeconds() > self.modeOverlayTime then
	    --self.tagPositiveOverlay:SetVisible(false)
	    --self.tagNegativeOverlay:SetVisible(false)
	    self.reverseTagGUI:ShowPositiveAlert(false)
	    self.reverseTagGUI:ShowNegativeAlert(false)
	    self.modeOverlayClock:Reset()
	end
end


function ReverseTagClient:ProcessStateShowWinners(frameTime)
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


function ReverseTagClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState
	print("%%% New Tag gamestate: " .. self.tagStates:GameStateToString(self.gameState))

	--UnInit old state
	if oldState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:UnInitStateWaitForPlayers()
	elseif oldState == self.tagStates.GAME_STATE_PLAY then
		self:UnInitStatePlay()
	elseif oldState == self.tagStates.GAME_STATE_PLAY_REVERSE then
		self:UnInitStatePlayReverse()
	elseif oldState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		self:UnInitStateShowWinners()
	end

	--Init new state
	if self.gameState == self.tagStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.tagStates.GAME_STATE_PLAY then
		self:InitStatePlay()
	elseif self.gameState == self.tagStates.GAME_STATE_PLAY_REVERSE then
		self:InitStatePlayReverse()
    elseif self.gameState == self.tagStates.GAME_STATE_SHOW_WINNERS then
		self:InitStateShowWinners()
	end

end


function ReverseTagClient:GetGameInResultsMode()

    if IsValid(self.standings) and self.standings:GetVisible() then
        return true
    end
    return false

end


function ReverseTagClient:InvulStartTimeSlot(startTimeParams)

	self.invulStartTime = startTimeParams:GetParameterAtIndex(0, true):GetFloatData()

end

function ReverseTagClient:TagWinScoreSlot(tagScoreParams)

	self.tagWinScore = tagScoreParams:GetParameterAtIndex(0, true):GetIntData()

end

function ReverseTagClient:TagSettingsSlot(tagSettingsParams)

	local settingParam = tagSettingsParams:GetParameterAtIndex(0, true)
	local settingName = settingParam:GetName()

	if settingName == "InvulTimer" then
		self.invulTimer = settingParam:GetIntData()
		print("%%% InvulTimer: " .. tostring(self.invulTimer))
	else
		print("%%% Warning! Unknown tag setting: " .. settingName)
	end

end


function ReverseTagClient:PlayerStateSlot(playerStateParams)

	local playerID = ExtractPlayerIDFromState(playerStateParams:GetParameter(0, true))
	local newPlayerState = playerStateParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	--BRIAN TODO: Why is this possible? it is...
	if IsValid(player) then
		self:SetPlayerState(player, newPlayerState)
		print("%%% Player " .. player:GetName() .. " changed to state: " .. self.tagStates:PlayerStateToString(newPlayerState))
	end

end


function ReverseTagClient:PlayerScoreSlot(scoreParams)

	local playerID = ExtractPlayerIDFromState(scoreParams:GetParameter(0, true))
	local playerScore = scoreParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerScore(player, playerScore)

end


function ReverseTagClient:PlayerIT(ITPlayerID)

	--Make sure this isn't the same player who is already it
	if not self.ITPlayer or self.ITPlayer:GetUniqueID() ~= ITPlayerID then
		-- Set old ITPlayer to visible
		if IsValid(self.ITPlayer) and self.ITPlayer:GetControllerValid() then
            self.ITPlayer:GetController():SetVisible(true)
        end

        self.ITPlayer = GetPlayerManager():GetPlayerFromID(ITPlayerID)

        --Hide score particles off screen
        for i = 0, 10 do
            self.scoreParticles[i]:SetPosition(WVector3(-1000,-1000,-1000))
        end

		--Check if it is the local player
		local isLocal = false
		if self.ITPlayer and self.ITPlayer:GetUniqueID() == GetPlayerManager():GetLocalPlayer():GetUniqueID() then
			self.overlayITIndicator:SetVisible(false)
			self.overlayITBIndicator:SetVisible(false)
            isLocal = true	
		elseif self.gameState == self.tagStates.GAME_STATE_PLAY then
		    self.overlayITIndicator:SetVisible(true)
            self.overlayITBIndicator:SetVisible(false)    
		else
		    self.overlayITIndicator:SetVisible(false)
            self.overlayITBIndicator:SetVisible(true)
        end

		if self.ITPlayer ~= nil then
			GetConsole():Print("New player it: " .. self.ITPlayer:GetName())
			--self.ITIndicator:AttachToParentSceneNode(self.ITPlayer:GetController():GetSceneNode())
			--self.ITIndicator:GetSceneNode():SetInheritOrientation(false)
			self.ITIndicator:SetOverlay(true, false)
			self.ITBIndicator:SetOverlay(true, false)
			self.reverseTagGUI:SetScoreBarName(self.ITPlayer:GetName())
			self.reverseTagGUI:SetScoreBar(self.ITPlayer.userData.score/self.tagWinScore)
			self.reverseTagGUI:ShowScoreBar(true)

			if not IsValid(self.ITPlayer.userData.tag) then
			    self.ITPlayer.userData.tag = 0
			end
			if isLocal and self.gameState == self.tagStates.GAME_STATE_PLAY then
			    self.ITPlayer.userData.tag = self.ITPlayer.userData.tag + 1
			    print(self.ITPlayer:GetName()..".userData.tag = "..self.ITPlayer.userData.tag)
			    if self.ITPlayer.userData.tag == 5 then
			        self.achievements:Unlock(self.achievements.AVMT_STING_BEE)
			    end
			end
		else
			GetConsole():Print("No player is it")
			--self.ITIndicator:DetachFromParentSceneNode()
			--self.ITIndicator:AttachToRootSceneNode()
			self.ITIndicator:SetOverlay(false, false)
			self.ITBIndicator:SetOverlay(false, false)
			self.ITIndicator:SetPosition(self.ITRespawnPos)
			self.reverseTagGUI:ShowScoreBar(false)
		end
	end

	self.rosterDirty = true

end

function ReverseTagClient:GetWinningPlayer()
    local winningPlayer = nil
    local topScore = -1
    local i = 1
    local numPlayers = GetPlayerManager():GetNumberOfPlayers()
    while i <= numPlayers do
        local player = GetPlayerManager():GetPlayer(i)
        if player.userData.score > topScore then
            winningPlayer = player
            topScore = player.userData.score
        end
        i = i + 1
    end
    return winningPlayer
end 


function ReverseTagClient:ShowStandingsGUI(show)

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


function ReverseTagClient:GetProcessSlot()

	return self.processSlot

end


function ReverseTagClient:ClientConnected(connectParams)

	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:InitPlayerState(player)

end


function ReverseTagClient:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	if self.tagStates:IsPlayerIT(player.userData.state) then
		--They arent IT anymore
		self:PlayerIT(0)
	end

	self:UnInitPlayerState(player)

end

--REVERSETAGCLIENT CLASS END