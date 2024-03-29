UseModule("IGameMode", "Scripts/GameModes/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("AchievementManager", "Scripts/")
UseModule("RaceStates", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceCountdown", "Scripts\\GameModes\\Race\\")
UseModule("GUIRacePosition", "Scripts\\GameModes\\Race\\")
UseModule("GUIRaceStandings", "Scripts\\GameModes\\Race\\")
UseModule("GUITimer", "Scripts\\GameModes\\Race\\")
UseModule("RaceNodeManager", "Scripts\\GameModes\\Race\\")
UseModule("RaceCheckpointManager", "Scripts\\GameModes\\Race\\")
UseModule("RaceCheckpointMarkerManager", "Scripts\\GameModes\\Race\\")
UseModule("SpectatorManager", "Scripts/")
UseModule("CamControllerGoTo", "Scripts/")

--RACECLIENT CLASS START

class 'RaceClient' (IGameMode)

function RaceClient:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode Race in init")
	end

    self.achievements = AchievementManager()

	self.spectatorTimer = WTimer()

    self.spectatorManager = SpectatorManager()

	self:LoadMapSettings()

	self:InitGUI()
	
	-- Set roster to reverse sort by score
	GetMenuManager():GetRoster():SetScoreSorting(false)

	self.raceCheckpointMarkerManager = RaceCheckpointMarkerManager(self.map)
	self.raceStates = RaceStates()

	self.raceNodeManager = nil
	self:InitNodes()

    self.raceCheckpointManager = RaceCheckpointManager(self.map, self.raceNodeManager)

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	self.camFollowObjChanged = self:CreateSlot("CamFollowObjChanged", "CamFollowObjChanged")
	GetCameraManager():GetSignal("FollowObjectChanged", true):Connect(self.camFollowObjChanged)

    --Called when the spectated object is uninited
	self.specObjUnInitSlot = self:CreateSlot("SpecObjUnInit", "SpecObjUnInit")
	self.spectatorManager:GetSignal("FollowObjUnInit", true):Connect(self.specObjUnInitSlot)

	--This is the global time that the round will start so the countdown is in sync
	self.roundStartTime = 0
	--Is the countdown GUI currently active?
	self.countdownActive = false

	--This is the global time that the race will be forced to finish
	self.raceEndTime = 0
	self.raceEndTimeActive = false

	--Get reference to the playerCam
	self.camera = GetCamera()

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

	self.visualizationEnabled = false

	self.rosterManualUpdateClock = WTimer()
	self.rosterManualUpdateTimer = 1

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

    -- Listen for fire key
    self.keyEventSlot = self:CreateSlot("KeyEvent","KeyEvent")
    GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)
    
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


function RaceClient:BuildInterfaceDefIGameMode()

	self:AddClassDef("RaceClient", "IGameMode", "Manages the race game mode")

end


function RaceClient:InitGameMode()

end


function RaceClient:UnInitGameMode()

	self.raceCheckpointMarkerManager:UnInit()
	self.raceCheckpointMarkerManager = nil

	self:UnInitGUI()
	self:UnInitNodes()
	self:UnInitState()

end


function RaceClient:InitState()

	--This is needed for player state
	self.playerStateSlot = self:CreateSlot("PlayerStateSlot", "PlayerStateSlot")
	--This is to receive which lap a player is on
	self.playerLapSlot = self:CreateSlot("PlayerLapSlot", "PlayerLapSlot")
	--This is to receive which place a player is in
	self.playerPlaceSlot = self:CreateSlot("PlayerPlaceSlot", "PlayerPlaceSlot")
	--This is to receive which checkpoint a player is on
	self.playerCheckpointSlot = self:CreateSlot("PlayerCheckpointSlot", "PlayerCheckpointSlot")

	self.gameStateSlot = self:CreateSlot("GameStateSlot", "GameStateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("GameState", self.gameStateSlot)

	self.roundStartTimeSlot = self:CreateSlot("RoundStartTimeSlot", "RoundStartTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RoundStartTime", self.roundStartTimeSlot)

	self.raceEndTimeSlot = self:CreateSlot("RaceEndTimeSlot", "RaceEndTimeSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RaceEndTime", self.raceEndTimeSlot)

	--Race settings
	self.raceSettingsSlot = self:CreateSlot("RaceSettingsSlot", "RaceSettingsSlot")
	--NumLaps
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("NumLaps", self.raceSettingsSlot)
	--RaceCountdownTimer
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("RaceCountdownTimer", self.raceSettingsSlot)

end


function RaceClient:UnInitState()

end


function RaceClient:InitPlayerState(player)

	--Default values before watching their state in case their states is already known to the table
	player.userData.state = self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS
	player.userData.lap = 0
	player.userData.place = 0

	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_State", self.playerStateSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Lap", self.playerLapSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Place", self.playerPlaceSlot)
	GetClientSystem():GetReceiveStateTable("Map"):WatchState(tostring(player:GetUniqueID()) .. "_Checkpoint", self.playerCheckpointSlot)

	self.rosterDirty = true

end


function RaceClient:UnInitPlayerState(player)

	self.rosterDirty = true

end


function RaceClient:InitNodes()

	self.raceNodeManager = RaceNodeManager(GetClientWorld())

end


function RaceClient:UnInitNodes()

	self.raceNodeManager:UnInit()
	self.raceNodeManager = nil

end


function RaceClient:InitGUI()

	self.countdownGUI = GUIRaceCountdown()

	self.timerGUI = GUITimer()
	self.timerGUI:SetVisible(false)

	self.racePosition = GUIRacePosition(0, 0, 0, 0)
	--Start off invisible
	self.racePosition:SetVisible(false)

	self.raceStandings = GUIRaceStandings()
	self.raceStandings:SetVisible(false)

    self.warmupGUI = GetMyGUISystem():LoadLayout("warmup.layout", "Warmup_")
    self.warmupGUI:SetVisible(false)
    
    self.spectatorGUI = GetMyGUISystem():LoadLayout("spectator.layout", "Spectator_")
    self.spectatorGUI:SetVisible(false)

	--Does the roster need to be updated?
	self.rosterDirty = true

	--We will control the roster
	--GetMenuManager():GetRoster():SetManuallyControlled(true)

end


function RaceClient:UnInitGUI()

	self.countdownGUI:UnInit()
	self.countdownGUI = nil
	self.timerGUI:UnInit()
	self.timerGUI = nil
	self.racePosition:UnInit()
	self.racePosition = nil
	self.raceStandings:UnInit()
	self.raceStandings = nil

    GetMyGUISystem():UnloadLayout(self.warmupGUI)
	self.warmupGUI = nil

    GetMyGUISystem():UnloadLayout(self.spectatorGUI)
	self.spectatorGUI = nil

    
	--We no longer control the roster
	GetMenuManager():GetRoster():SetManuallyControlled(false)

end


function RaceClient:LoadMapSettings()

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

    self.camFreeMove = CamControllerGoTo(self.observeCamPos, self.observeCamLookAt, GetCamera())
	--self.camFreeMove:SetPosition(self.observeCamPos)
	--self.camFreeMove:SetLookAt(self.observeCamLookAt)

end

function RaceClient:GoToSpectator()
    self.spectatorTimer:Reset()
    self.spectatorTimer:Stop()
    
    self.mainPlayer:SetControllerEnabled(false)
    
    -- Find a player to follow
    local racingPlayer = self:GetRacingPlayer()
            
    -- Give camera control to the spectator manager 
    if IsValid(racingPlayer) then
        self.spectatorManager:SetFollowPlayer(racingPlayer)
        self.spectatorManager:SetEnabled(true)
    end
    
    self.spectatorGUI:SetVisible(true)
    
end

function RaceClient:SetPlayerState(player, newPlayerState)

	player.userData.state = newPlayerState

    --Based on the player state, manage their controller
	if player.userData.state == self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS then
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_COUNTDOWN then
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_RACE then
	    print("State PLAYER_STATE_RACE")
	    player:GetController().boostBurned = 0
	    player:GetController().weaponsUsed = false
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_RACE_FINISHED then
		--player:SetControllerEnabled(false)
		if player == self.mainPlayer and IsClient() then
		    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/AMB_Goal.wav", WVector3(), 0.6, 10, false, SoundSystem.HIGH)
		    
		    -- Check for iced finish
		    if player == self.mainPlayer then
		        print("Iced at finish: "..tostring(player:GetController():GetWheelFriction()))
		        print("Place: "..player.userData.place)
		        if player:GetController():GetWheelFriction() == 0 and player.userData.place == 1 then
		            self.achievements:Unlock(self.achievements.AVMT_FROZEN_FINISH)
		        end
		    end
		    
		    -- Check for overachiever
		    if player == self.mainPlayer then
		        print("Overachiever: "..tostring(self.overachiever))
		        if self.overachiever then
		            self.achievements:Unlock(self.achievements.AVMT_OVERACHIEVER)
		        end
		    end
		    
		    -- Check for pwnt
		    if player == self.mainPlayer then
		        if IsValid(self.placeTime) and player.userData.place == 1 and GetClientSystem():GetTime() - self.placeTime < 2 then
		            self.achievements:Unlock(self.achievements.AVMT_PWNT)
		        end
		    end
		    
		    -- Check for screwed
		    if player == self.mainPlayer then
		        if IsValid(self.placeTime) and player.userData.place ~= 1 and GetClientSystem():GetTime() - self.placeTime < 2 then
		            self.achievements:Unlock(self.achievements.AVMT_SCREWED)
		        end
		    end
		    
		    -- Check for easy rider
		    if player == self.mainPlayer then
		        print("Boost Burned: "..player:GetController().boostBurned)
		        if player.userData.place == 1 and player:GetController().boostBurned == 0 then
		            self.achievements:Unlock(self.achievements.AVMT_EASY_RIDER)
		        end
		    end
		    
		    -- Check for pacifist
		    if player == self.mainPlayer then
		        if player.userData.place == 1 and player:GetController().weaponsUsed == false then
		            self.achievements:Unlock(self.achievements.AVMT_PACIFIST)
		        end
		    end
		    
		    -- Check for butterfly
		    if player == self.mainPlayer then
		        if player.userData.place == 1 and player:GetController().inAir then
		            self.achievements:Unlock(self.achievements.AVMT_FLOAT_BUTTERFLY)
		        end
		    end
		end
	elseif player.userData.state == self.raceStates.PLAYER_STATE_SHOW_WINNERS then
		player:SetControllerEnabled(true)
	elseif player.userData.state == self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END then
		player:SetControllerEnabled(false)
	end

	if player == self.mainPlayer then
	    self.spectatorGUI:SetVisible(false)
	
	    --player:GetController():SetBoostPercent(1)
	    --player:GetController():SetBoostPercent(0)
		if self:GetPlayerState(self.mainPlayer) == self.raceStates.PLAYER_STATE_WAIT_FOR_PLAYERS then
			--Load all we want before the race starts
			self:SetLoadingAllowed(true)
		end

		--Show or Hide the race laps GUI if the main player is racing or not
		if self:GetPlayerState(self.mainPlayer) == self.raceStates.PLAYER_STATE_RACE or 
           self:GetPlayerState(self.mainPlayer) == self.raceStates.PLAYER_STATE_COUNTDOWN then
			--Loading now would interrupt gameplay
			self:SetLoadingAllowed(false)

			self.racePosition:SetVisible(true)
			self.mainPlayer:SetGUIVisible(true)
		else
			--self.racePosition:SetVisible(false)
			--self.mainPlayer:SetGUIVisible(false)
			--BRIAN TODO: String table?
			--GetMenuManager():GetChat():AddMessage("#00ffda", "WAITING FOR NEXT RACE")
		end

		--Show or Hide the standings based on if the player should see the winners
		if self:GetPlayerState(self.mainPlayer) == self.raceStates.PLAYER_STATE_SHOW_WINNERS then
			--Load all we want when the winners are being shown as nobody is playing
			self:SetLoadingAllowed(true)
			self:ShowStandingsGUI(true)
		    --self.camFreeMove:SetPosition(self.observeCamPos)
			--self.camFreeMove:SetLookAt(self.observeCamLookAt)
			
			
			--
            self.spectatorManager:SetEnabled(false)
			GetCameraManager():AddController(self.camFreeMove, 2)
			GetCamera():SetPosition(self.observeCamPos)
			GetCamera():GetLookAt():SetPosition(self.observeCamLookAt)
			--
			
			if self.mainPlayer.userData.place == 1 then
			    GetSoundSystem():EmitSound(ASSET_DIR .. "sound/win.wav", WVector3(), 0.2, 10, false, SoundSystem.HIGH)
			    if GetClientManager().indieSlider then
			        self.achievements:Unlock(self.achievements.AVMT_INDIE_GAMER)
			    end
			end
		else
			self:ShowStandingsGUI(false)
			GetCameraManager():RemoveController(self.camFreeMove)
		end

        -- Spectator states
        if self:IsPlayerSpectating(self.mainPlayer) then
			--It is okay to load while the player is spectating as it won't screw up their gameplay
            self:SetLoadingAllowed(true)
            
            self.spectatorTimer:Reset()
            --[[
            -- Find a player to follow
            local racingPlayer = self:GetRacingPlayer()
            
            -- Give camera control to the spectator manager 
            if IsValid(racingPlayer) then
                self.spectatorManager:SetFollowPlayer(racingPlayer)
                self.spectatorManager:SetEnabled(true)
            end
            --]]
        end
		
	end

end

function RaceClient:KeyEvent(keyParams)
    local key = keyParams:GetParameter("Key", true):GetIntData()
    --print("key pressed:"..key)
    if self:IsPlayerSpectating(self.mainPlayer) and GetClientInputManager():GetKeyCodeMatches(key, "UseItemUp") then
        -- Switch follow player
        local newFollow = self:GetRacingPlayer(self.spectatorManager:GetFollowPlayer())
        if IsValid(newFollow) then
            print("newFollow:"..newFollow:GetName())
            self.spectatorManager:SetFollowPlayer(newFollow)
        end
    end

    -- REFRESH LAYOUT FOR THE POSITION (DEBUG ONLY SENOQUESE)
 --    self.racePosition:UnInit()
	-- self.racePosition = nil
	-- self.racePosition = GUIRacePosition(0, 0, 0, 0)
	-- self.racePosition:SetVisible(true)
end

function RaceClient:GetRacingPlayer(notPlayer)

    local racers = {}

    local i = 1
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
    while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if player ~= self.mainPlayer and player ~= notPlayer and (self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_RACE or self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_COUNTDOWN) then
			table.insert(racers, player)
		end
		i = i + 1
	end
	
	if #racers > 0 then
	    return racers[math.modf((Random() * #racers) + 1)]
	else
	    return nil
	end
	
end


function RaceClient:GetPlayerState(player)

	return player.userData.state

end


function RaceClient:GetNumRacingPlayers()

	local totalRacingPlayers = 0
	local i = 1
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	while i < (numPlayers + 1) do
		local player = GetPlayerManager():GetPlayer(i)
		if self.raceStates:IsPlayerRacing(self:GetPlayerState(player)) then
			totalRacingPlayers = totalRacingPlayers + 1
		end
		i = i + 1
	end

	return totalRacingPlayers

end


function RaceClient:Process()

    local frameTime = GetFrameTime()
	if self.gameState == self.raceStates.GAME_STATE_WAIT_FOR_PLAYERS then
		self:ProcessStateWaitForPlayers(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_COUNTDOWN then
		self:ProcessStateCountdown(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_RACE then
		self:ProcessStateRace(frameTime)
	elseif self.gameState == self.raceStates.GAME_STATE_SHOW_WINNERS then
		self:ProcessStateShowWinners(frameTime)
    end

	self:ProcessGUI(frameTime)

	self.raceCheckpointMarkerManager:Process(frameTime)
	
	if self.visualizationEnabled then
	    self:DrawToNode()
	end

end

function RaceClient:ProcessSpectatorState(frameTime)

    if self.spectatorTimer:GetTimeSeconds() == 0 then
        -- Check if the player we're following is still racing
        local followPlayer = self.spectatorManager:GetFollowPlayer()
        if not IsValid(followPlayer) or self:GetPlayerState(followPlayer) ~= self.raceStates.PLAYER_STATE_RACE then
            -- Switch to another racing player
            local racer = self:GetRacingPlayer()
            if IsValid(racer) then
                self.spectatorManager:SetFollowPlayer(racer)
            end
        end
    elseif self.spectatorTimer:GetTimeSeconds() > 1.0 then
        self:GoToSpectator()
    end

end

function RaceClient:DrawToNode()
    local playerCheckpoint = self.raceCheckpointManager:GetPlayerCheckpoint(self.mainPlayer)
    
    if IsValid(playerCheckpoint) then
        local playerCP = self.raceCheckpointManager:GetCheckpoint(playerCheckpoint)
        
        if IsValid(playerCP) then
            local nodeA, distA = self.raceNodeManager:GetNextClosestNode(playerCP, self.mainPlayer:GetPosition())
            local nodePlane = nodeA:Get():GetPlane()
            if not IsValid(self.mainPlayer.userData.node) or nodeA:Get():GetIndex() ~= self.mainPlayer.userData.node then
                self.mainPlayer.userData.node = nodeA:Get():GetIndex()
                print("node:"..self.mainPlayer.userData.node)
            end
            local side = nodePlane:GetPointOnSide(self.mainPlayer:GetPosition())
            if not IsValid(self.line) then
                self.line = OGRELines()    
            end
            self.line:Init(Parameters())
            self.line:Begin()
            if side == WPlane.POSITIVE_SIDE then
                local onto = nodeA:Get():GetNextNode():GetPosition() - nodeA:GetPosition()
                local toKart = self.mainPlayer:GetPosition() - nodeA:GetPosition()
                local proj = toKart:Project(onto)
                self.line:AddLine(nodeA:GetPosition()+WVector3(0,0.5,0), nodeA:GetPosition()+proj+WVector3(0,0.5,0), WColorValue(0, 1, 0, 0))
            else
                local onto = nodeA:Get():GetPrevNode():GetPosition() - nodeA:GetPosition()
                local toKart = self.mainPlayer:GetPosition() - nodeA:GetPosition()
                local proj = toKart:Project(onto)
                self.line:AddLine(nodeA:GetPosition()+WVector3(0,0.5,0), nodeA:GetPosition()+proj+WVector3(0,0.5,0), WColorValue(0, 0, 1, 0))
            end
            self.line:End()
            --print(distA)
        end
    end
end

function RaceClient:ProcessGUI(frameTime)

	self.racePosition:SetPlaces(self:GetNumRacingPlayers())

	self:ProcessRoster(frameTime)
	
	if self.spectatorManager:GetEnabled() and IsValid(self.spectatorManager:GetFollowPlayer()) then
	    local tempPlace = 0
	    if IsValid(self.spectatorManager:GetFollowPlayer().userData.place) then
	        tempPlace = self.spectatorManager:GetFollowPlayer().userData.place
	    end
	    local tempLap = 0
	    if IsValid(self.spectatorManager:GetFollowPlayer().userData.lap) then
	        tempLap = self.spectatorManager:GetFollowPlayer().userData.lap
	    end
        self.racePosition:SetPlace(tempPlace)
	    self.racePosition:SetLap(tempLap)
	end

	self.countdownGUI:Process(frameTime)

end


function RaceClient:ProcessRoster(frameTime)

	if self.rosterDirty or self.rosterManualUpdateClock:GetTimeSeconds() > self.rosterManualUpdateTimer then
		self.rosterManualUpdateClock:Reset()
		local rosterList = { }
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		local i = 1
		while i <= numPlayers do
			local player = GetPlayerManager():GetPlayer(i)
			local setColor = "B9FD01"
			if player:IsLocalPlayer() then
				setColor = "FFFFFF"
			end
			local playerPing = math.ceil(player:GetPing() * 1000)
			local playerData = { uniqueID = player:GetUniqueID(), name = player:GetName(), color = setColor, 
								 score = player.userData.place, ping = playerPing, kick = 0, audioMute = 0, visualMute = 0 }
			table.insert(rosterList, playerData)
			i = i + 1
		end
		--table.sort(rosterList, function(playerA, playerB) return playerA.score < playerB.score end)
		GetMenuManager():GetRoster():UpdateRoster(rosterList)
		self.rosterDirty = false
	end

end


function RaceClient:ShowStandingsGUI(show)

	if show then
		--Update the standings
		local currentStandings = { }
		local i = 1
		local numPlayers = GetPlayerManager():GetNumberOfPlayers()
		while i < (numPlayers + 1) do
			local player = GetPlayerManager():GetPlayer(i)
			if player.userData.lap > 0 then
				table.insert(currentStandings, { player, player.userData.place })
			end
			i = i + 1
		end
		self.raceStandings:ShowStandings(currentStandings)
	else
		self.raceStandings:HideStandings()
	end

end


function RaceClient:InitStateWaitForPlayers()

	--Markers are only enabled in the race state
	self.raceCheckpointMarkerManager:TurnOffAllMarkers()
	self.warmupGUI:SetVisible(true)
	self.mainPlayer:SetGUIVisible(true)
	self.racePosition:SetVisible(false)

end


function RaceClient:UnInitStateWaitForPlayers()

	self.warmupGUI:SetVisible(false)

end


function RaceClient:InitStateCountdown()

	self.countdownActive = false

	--Markers are only enabled in the race state
	self.raceCheckpointMarkerManager:TurnOffAllMarkers()
	self.racePosition:SetVisible(true)
	self.mainPlayer:SetGUIVisible(true)

    
    
end


function RaceClient:UnInitStateCountdown()

	--Nothing to uninit here

end


function RaceClient:InitStateRace()

	--Nothing to init here
    self.mainPlayer:SetGUIVisible(true)
    self.racePosition:SetVisible(true)
    self.raceStartTimer = WTimer()
    self.overachiever = true
end


function RaceClient:UnInitStateRace()

	self.timerGUI:SetVisible(false)
	self.racePosition:SetVisible(false)

end


function RaceClient:InitStateShowWinners()

    -- Turn off music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(true)
    end
    
    self.mainPlayer:SetGUIVisible(false)
    self.racePosition:SetVisible(false)

	--Markers are only enabled in the race state
	self.raceCheckpointMarkerManager:TurnOffAllMarkers()
	
	-- play a win or lose sound
    if IsValid(self.mainPlayer.userData.place) and self.mainPlayer.userData.place <=3 then
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/win.wav", WVector3(), 0.2, 10, false, SoundSystem.HIGH)
        
        if self.mainPlayer.userData.place == 1 then
            self.achievements:UpdateStat(self.achievements.STAT_FINISHES_1ST, 1)
        elseif self.mainPlayer.userData.place == 2 then
            self.achievements:UpdateStat(self.achievements.STAT_FINISHES_2ND, 1)
        else
            self.achievements:UpdateStat(self.achievements.STAT_FINISHES_3RD, 1)
        end
    else
        GetSoundSystem():EmitSound(ASSET_DIR .. "sound/fail.wav", WVector3(), 0.2, 10, false, SoundSystem.HIGH)
    end

    self:CheckGentlemansWager()
    self:CheckPirateParty()
	self:CheckWargames()
	self:CheckInspectorKemp()
	self:CheckTermination()

end


function RaceClient:UnInitStateShowWinners()

    -- Turn on music
    if IsValid(self.mapMusic) then
        self.mapMusic:SetMute(false)
    end
    
    self.mainPlayer:SetGUIVisible(true)

end


--Waiting for more players
function RaceClient:ProcessStateWaitForPlayers(frameTime)

end


function RaceClient:ProcessStateCountdown(frameTime)

	--The countdown doesn't start until after the time in self.roundStartTime
	if GetClientSystem():GetTime() > self.roundStartTime and not self.countdownActive and self:GetPlayerState(self.mainPlayer) == self.raceStates.PLAYER_STATE_COUNTDOWN then
		self.countdownGUI:Start(self.roundStartTime+3)
		self.countdownActive = true
	end

end


function RaceClient:ProcessStateRace(frameTime)

	if self.raceEndTimeActive then
		self.timerGUI:SetVisible(true)
		self.timerGUI:SetTime(self.raceEndTime - GetClientSystem():GetTime())
		if GetClientSystem():GetTime() >= self.raceEndTime then
			self.raceEndTimeActive = false
		end
	end

	if not self.raceEndTimeActive then
		self.timerGUI:SetVisible(false)
	end
	
	if self:IsPlayerSpectating(self.mainPlayer) then
	   self:ProcessSpectatorState(frameTime) 
	end

end

function RaceClient:IsPlayerSpectating(player)
    if self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_RACE_FINISHED or
	    self:GetPlayerState(player) == self.raceStates.PLAYER_STATE_WAIT_FOR_RACE_END then
	    return true
	else
	    return false
	end
end


function RaceClient:ProcessStateShowWinners(frameTime)

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


function RaceClient:RaceSettingsSlot(raceSettingsParams)

	local settingParam = raceSettingsParams:GetParameterAtIndex(0, true)
	local settingName = settingParam:GetName()

	if settingName == "NumLaps" then
		self.numLaps = settingParam:GetIntData()
		print("%%% NumLaps: " .. tostring(self.numLaps))
		--Notify the gui
		if IsValid(self.racePosition) then
			self.racePosition:SetLaps(self.numLaps)
		end
	elseif settingName == "RaceCountdownTimer" then
		self.raceCountdownTimer = settingParam:GetFloatData()
		print("%%% RaceCountdownTimer: " .. tostring(self.raceCountdownTimer))
	else
		print("%%% Warning! Unknown race setting: " .. settingName)
	end

end


function RaceClient:GameStateSlot(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()

	local oldState = self.gameState
	self.gameState = newGameState
	print("%%% New Race gamestate: " .. self.raceStates:GameStateToString(self.gameState))

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
		self:InitStateWaitForPlayers()
	elseif self.gameState == self.raceStates.GAME_STATE_COUNTDOWN then
		self:InitStateCountdown()
	elseif self.gameState == self.raceStates.GAME_STATE_RACE then
		self:InitStateRace()
	elseif self.gameState == self.raceStates.GAME_STATE_SHOW_WINNERS then
		self:InitStateShowWinners()
	end

end


function RaceClient:GetGameInResultsMode()

    if IsValid(self.raceStandings) and self.raceStandings:GetVisible() then
        return true
    end
    return false

end


function RaceClient:PlayerStateSlot(playerStateParams)

	playerID = ExtractPlayerIDFromState(playerStateParams:GetParameter(0, true))
	local newPlayerState = playerStateParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:SetPlayerState(player, newPlayerState)
	print("%%% Player " .. player:GetName() .. " changed to state: " .. self.raceStates:PlayerStateToString(newPlayerState))

end


function RaceClient:PlayerLapSlot(playerLapParams)

	local playerID = ExtractPlayerIDFromState(playerLapParams:GetParameter(0, true))
	local currentLap = playerLapParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	player.userData.lap = currentLap
	print("%%% Player " .. player:GetName() .. " is on lap: " .. tostring(player.userData.lap))

	--If this is the local player then update the GUI
	if playerID == self.mainPlayer:GetUniqueID() then
		self.racePosition:SetLap(player.userData.lap)
	end

end


function RaceClient:PlayerPlaceSlot(playerPlaceParams)

	local playerID = ExtractPlayerIDFromState(playerPlaceParams:GetParameter(0, true))
	local currentPlace = playerPlaceParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	player.userData.place = currentPlace

	--If this is the local player then update the GUI
	if playerID == self.mainPlayer:GetUniqueID() then
		self.racePosition:SetPlace(player.userData.place)

		-- keep track of the time player gained first
		self.placeTime = GetClientSystem():GetTime()
		
		if IsValid(self.raceStartTimer) and self.raceStartTimer:GetTimeSeconds() > 5 then
		    if currentPlace > 1 then
		        print("Overachiever FALSE")
		        self.overachiever = false
		    end
		end
	end

	self.rosterDirty = true

end


function RaceClient:PlayerCheckpointSlot(playerCheckpointParams)

	local playerID = ExtractPlayerIDFromState(playerCheckpointParams:GetParameter(0, true))
	local currentCheckpoint = playerCheckpointParams:GetParameter(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	player.userData.currentCheckpoint = currentCheckpoint

	--BRIAN TODO: What to do if the follow object changes between two calls to this function?
	if GetCameraManager():IsFollowObject(player:GetController()) then
		--Notify the marker manager about the new checkpoint for the main player
		self.raceCheckpointMarkerManager:SetCurrentCheckpoint(player.userData.currentCheckpoint)
		--Play a sound effect so the player knows they hit a checkpoint
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/bell.wav", WVector3(), 0.5, 1, false, SoundSystem.MEDIUM)
	end

end


function RaceClient:RoundStartTimeSlot(startTimeParams)

	self.roundStartTime = startTimeParams:GetParameterAtIndex(0, true):GetFloatData()
	-- Let players know when the round will start
	--local timeToStart = math.ceil(self.roundStartTime-GetClientSystem():GetTime())
	--local chat = GetMenuManager():GetChat()
	--chat:AddMessage(chat.chatColorServer, "Race will start in "..timeToStart.." seconds.")

end


function RaceClient:RaceEndTimeSlot(timeParams)

	self.raceEndTime = timeParams:GetParameterAtIndex(0, true):GetFloatData()
	if self.raceEndTime == 0 then
		self.raceEndTimeActive = false
	else
		self.raceEndTimeActive = true
	end

end


function RaceClient:ClientConnected(connectParams)

	local playerAddedClock = WTimer()
	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:InitPlayerState(player)

	print("Player added to RaceClient time: " .. tostring(playerAddedClock:GetTimeSeconds()))

end


function RaceClient:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)
	self:UnInitPlayerState(player)

end


function RaceClient:SpecObjUnInit(params)

    local newFollow = self:GetRacingPlayer(self.spectatorManager:GetFollowPlayer())
    if IsValid(newFollow) then
        print("newFollow:"..newFollow:GetName())
        self.spectatorManager:SetFollowPlayer(newFollow)
    else
        self.spectatorManager:SetFollowPlayer(nil)
    end

end


function RaceClient:CamFollowObjChanged(params)

	print("RaceClient:CamFollowObjChanged() called!!!")

end


function RaceClient:SetVisualizationEnabled(setEnabled)

	self.visualizationEnabled = setEnabled
	self.raceNodeManager:SetVisualizationEnabled(self.visualizationEnabled)

end


function RaceClient:GetVisualizationEnabled()

	return self.visualizationEnabled

end

--RACECLIENT CLASS END