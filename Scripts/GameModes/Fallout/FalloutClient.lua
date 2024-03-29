UseModule("IBase", "Scripts/")
UseModule("PlayerManagerClient", "Scripts/")
UseModule("NetworkClock", "Scripts/")

--FALLOUTCLIENT CLASS START

class 'FalloutClient' (IBase)

function FalloutClient:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode Fallout in init")
	end

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	--Setup the signals we will need to emit over the network
	self.timeSyncRequestSignal = self:CreateSignal("TimeSyncRequest", GetClientSystem(), true)
	self.timeSyncRequestParams = Parameters()

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Setup the slots that will receive signal emits from the server
	self.setGameStateSlot = self:CreateSlot("SetGameState", "SetGameState", GetClientSystem())

	self.playerFalloutSlot = self:CreateSlot("PlayerFallout", "PlayerFallout", GetClientSystem())

	self.updateScoreSlot = self:CreateSlot("UpdateScore", "UpdateScore", GetClientSystem())

	self.timeSyncSlot = self:CreateSlot("TimeSync", "TimeSync", GetClientSystem())

	--Get reference to the playerCam
	self.camera = GetCamera()

	self.mainPlayer = GetPlayerManager():GetLocalPlayer()

	self:InitGUI()

	--We will reset this clock based on game state switched and display it
	self.gameClock = NetworkClock(GetClientSystem())

	--Game states that will be set from the server
	self.STATE_PLAY = 0
	self.STATE_ROUND_OVER = 1
	self.gameState = self.STATE_PLAY

	--Now that we have inited properly, request for a time sync
	self.timeSyncRequestSignal:Emit(self.timeSyncRequestParams)

	self.currentTimeLimit = 0

end


function FalloutClient:BuildInterfaceDefIBase()

	self:AddClassDef("FalloutClient", "IBase", "The client game mode manager for the Fallout game mode")

end


function FalloutClient:UnInitImp()

	self:UnInitGUI()

end


function FalloutClient:InitGUI()

	--Setup the GUI signals
	self.addPlayerSignal = self:CreateSignal("AddPlayer")
	self.addPlayerParams = Parameters()
	self.setPlayerScoreSignal = self:CreateSignal("SetPlayerScore")
	self.setPlayerScoreParams = Parameters()
	self.removePlayerSignal = self:CreateSignal("RemovePlayer")
	self.removePlayerParams = Parameters()
	--Score display
	local pageCreator = GUIPageCreator()
	pageCreator:SetPageName("ScoreBoard")
	pageCreator:SetPageURL("local://scoreboard.html")
	pageCreator:SetAbsoluteWidth(256)
	pageCreator:SetAbsoluteHeight(256)
	pageCreator:SetMovable(false)
	pageCreator:SetForceUpdates(false)
	pageCreator:SetAlphaMask("scoreboard.png")
	self.scorePage = GetNaviGUISystem():AddPage(pageCreator)
	self.scorePage:SetPosition(WVector3(0, 0.5, 0))
	self.scorePage:RequestSignalConnectToSlot(self.addPlayerSignal, "AddPlayerSlot")
	self.scorePage:RequestSignalConnectToSlot(self.setPlayerScoreSignal, "SetPlayerScoreSlot")
	self.scorePage:RequestSignalConnectToSlot(self.removePlayerSignal, "RemovePlayerSlot")
	--Start out not shown
	self.scorePage:Hide(false, 0)

	--Init the GUI with all the currently connected players
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local playerName = GetPlayerManager():GetPlayer(i):GetName()
		self.addPlayerParams:GetOrCreateParameter(0):SetName("PlayerName")
		self.addPlayerParams:GetOrCreateParameter(0):SetStringData(playerName)
		self.addPlayerSignal:Emit(self.addPlayerParams)
		i = i + 1
	end

	--This is so we know when to show/hide the score board
	self.showScoreboardSlot = self:CreateSlot("ShowScoreBoard", "ShowScoreBoard")
	GetClientManager():GetInputSignal("ShowPlayers"):Connect(self.showScoreboardSlot)
	
	--The time display
	self.setTimeSignal = self:CreateSignal("SetTime")
	self.setTimeParams = Parameters()
	--Score display
	local timePageCreator = GUIPageCreator()
	timePageCreator:SetPageName("FalloutTimer")
	timePageCreator:SetPageURL("local://timer.html")
	timePageCreator:SetAbsoluteWidth(256)
	timePageCreator:SetAbsoluteHeight(128)
	timePageCreator:SetMovable(false)
	timePageCreator:SetForceUpdates(false)
	timePageCreator:SetAlphaMask("timerbg.png")
	self.timePage = GetNaviGUISystem():AddPage(timePageCreator)
	self.timePage:SetPosition(WVector3(0, 0.02, 0))
	self.timePage:RequestSignalConnectToSlot(self.setTimeSignal, "SetTime")

	--The Fallout graphic
	self.falloutOverlay = OGREScreenOverlay()
	self.falloutOverlay:SetName(GenerateName())
	self.falloutOverlay:Init(Parameters())
	self.falloutOverlay:Set2D("falloutalert")
	self.falloutOverlay:SetMetricsMode(OGREScreenOverlay.MM_PIXELS)
	self.falloutOverlay:SetDimensions(512, 256)
	--Positions are applied from the center of the screen
	self.falloutOverlay:SetHorizontalAlignment(OGREScreenOverlay.HA_CENTER)
	self.falloutOverlay:SetVerticalAlignment(OGREScreenOverlay.VA_CENTER)
	--Positioned from the top left of the overlay,
	--to the left 256 pixels (half width of image),
	--moved up 256 pixels (height of image),
	--Position is applied from screen center
	self.falloutOverlay:SetPosition(WVector3(-256, -256, 0))
	self.falloutOverlay:SetVisible(false)
	self.falloutClock = WTimer()
	--Show for this amount of seconds
	self.falloutTimer = 2

end


function FalloutClient:UnInitGUI()

	GetNaviGUISystem():RemovePage(self.scorePage:GetName())
	self.scorePage = nil

	GetNaviGUISystem():RemovePage(self.timePage:GetName())
	self.timePage = nil

end


function FalloutClient:Process()

	local mins, seconds = self:GetTimeMinsSeconds()

	if (self.lastSeconds ~= seconds) and (mins > -1) and (seconds > -1) then
		self.lastSeconds = seconds

		self.setTimeParams:GetOrCreateParameter("Minutes"):SetIntData(mins)
		self.setTimeParams:GetOrCreateParameter("Seconds"):SetIntData(seconds)
		self.setTimeSignal:Emit(self.setTimeParams)
	end

	self:ProcessGUI()

end


function FalloutClient:ProcessGUI()

	if self.falloutOverlay:GetVisible() then
		if self.falloutClock:GetTimeSeconds() > self.falloutTimer then
			self.falloutOverlay:SetVisible(false)
		end
	end

end


function FalloutClient:GetTimeMinsSeconds()

	local timePassed = self.currentTimeLimit - self.gameClock:GetTimeSeconds()
	local mins, seconds = math.modf(timePassed / 60)
	seconds = math.modf(seconds * 60)
	return mins, seconds

end


function FalloutClient:ShowScoreBoard(showParams)

	--Only give the player control of the scoreboard during gameplay
	if self.gameState == self.STATE_PLAY then
		local show = showParams:GetParameter("Pressed", true):GetBoolData()
		if show then
			self.scorePage:Show(true, 0.3)
		else
			self.scorePage:Hide(true, 0.3)
		end
	end

end


function FalloutClient:SetGameState(gameStateParams)

	local newGameState = gameStateParams:GetParameterAtIndex(0, true):GetIntData()
	self.currentTimeLimit = gameStateParams:GetParameterAtIndex(1, true):GetFloatData()

	self.gameState = newGameState
	print("*** New game state: " .. tostring(self.gameState))

	if self.gameState == self.STATE_PLAY then
		self.scorePage:Hide(true, 0.3)
		self.gameClock:Reset()
	elseif self.gameState == self.STATE_ROUND_OVER then
		self.scorePage:Show(true, 0.3)
		self.gameClock:Reset()
	end

end


function FalloutClient:TimeSync(timeSyncParams)

	local currentServerTime = gameStateParams:GetParameterAtIndex(0, true):GetFloatData()

	--Reset the time
	self.gameClock:Reset()
	self.gameClock:AddTime(currentServerTime)

end


function FalloutClient:PlayerFallout(falloutParams)

	local playerID = falloutParams:GetParameterAtIndex(0, true):GetIntData()
	local falloutPlayer = GetPlayerManager():GetPlayerFromID(playerID)
	print("Player: " .. falloutPlayer:GetName() .. " fell out of the map!")

	--If the local player fellout, show the fallout graphic for a period of time
	if GetPlayerManager():GetLocalPlayer():GetUniqueID() == playerID then
		self.falloutOverlay:SetVisible(true)
		self.falloutClock:Reset()
	end

end


function FalloutClient:UpdateScore(scoreParams)

	local playerName = scoreParams:GetParameterAtIndex(0, true):GetStringData()
	local playerScore = scoreParams:GetParameterAtIndex(1, true):GetIntData()
	GetConsole():Print("Player: " .. playerName .. " Score: " .. tostring(playerScore))

	if IsValid(self.setPlayerScoreSignal) and IsValid(self.setPlayerScoreParams) then
		self.setPlayerScoreParams:GetOrCreateParameter(0):SetName("PlayerName")
		self.setPlayerScoreParams:GetOrCreateParameter(0):SetStringData(playerName)
		self.setPlayerScoreParams:GetOrCreateParameter(1):SetName("PlayerScore")
		self.setPlayerScoreParams:GetOrCreateParameter(1):SetStringData(tostring(playerScore))
		self.setPlayerScoreSignal:Emit(self.setPlayerScoreParams)
	end

end


function FalloutClient:GetProcessSlot()

	return self.processSlot

end


function FalloutClient:ClientConnected(connectParams)

	local clientName = connectParams:GetParameterAtIndex(0, true):GetStringData()
	self.addPlayerParams:GetOrCreateParameter(0):SetName("PlayerName")
	self.addPlayerParams:GetOrCreateParameter(0):SetStringData(clientName)
	self.addPlayerSignal:Emit(self.addPlayerParams)

end


function FalloutClient:ClientDisconnected(disconnectParams)

	local clientName = disconnectParams:GetParameterAtIndex(0, true):GetStringData()
	self.removePlayerParams:GetOrCreateParameter(0):SetName("PlayerName")
	self.removePlayerParams:GetOrCreateParameter(0):SetStringData(clientName)
	self.removePlayerSignal:Emit(self.removePlayerParams)

end

--FALLOUTCLIENT CLASS END