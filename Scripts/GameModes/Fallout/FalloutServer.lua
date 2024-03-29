UseModule("IBase", "Scripts/")
UseModule("PlayerManagerServer", "Scripts/")
UseModule("NetworkClock", "Scripts/")

--FALLOUTSERVER CLASS START

class 'FalloutServer' (IBase)

function FalloutServer:__init(setMap) super()

	self.map = setMap
	if self.map == nil or not self.map.__ok then
		error("No map passed to GameMode FalloutServer in init")
	end

	self.processSlot = self:CreateSlot("ProcessSlot", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	--Setup the signals we will need to emit over the network
	self.setGameStateSignal = self:CreateSignal("SetGameState", GetServerSystem(), true)
	self.setGameStateParams = Parameters()

	self.syncTimeSignal = self:CreateSignal("SyncTime", GetServerSystem(), true)
	self.syncTimeParams = Parameters()

	self.playerFalloutSignal = self:CreateSignal("PlayerFallout", GetServerSystem(), true)
	self.playerFalloutParams = Parameters()

	self.updateScoreSignal = self:CreateSignal("UpdateScore", GetServerSystem(), true)
	self.updateScoreParams = Parameters()

	--Setup the network slots we will need
	self.timeSyncRequestSlot = self:CreateSlot("TimeSyncRequest", "TimeSyncRequest", GetServerSystem())

	self.falloutSensor = self.map:GetMapObject("FalloutSensor", false)
	--Connect to the signal to receive info about collisions (for the tagP vs Vehicle collision)
	self.playerFalloutSlot = self:CreateSlot("PlayerFallout", "PlayerFallout")
	self.falloutSensor:Get():GetSignal("SensorCallback", true):Connect(self.playerFalloutSlot)

	--When the game clock runs out, the round is over
	self.gameClock = NetworkClock(GetServerSystem())

	--The round will end after this much time, in seconds
	self.roundTimeLimit = 300
	--The amount of time to wait until starting the next round, in seconds
	self.roundOverWaitTime = 10
	--The last time the game clock was synced with the clients
	self.lastTimeSync = 0
	--Sync the time with the clients at this rate, in seconds
	self.timeSyncRate = 10

	--Keep track of the current game state
	self.STATE_PLAY = 0
	self.STATE_ROUND_OVER = 1
	self.gameState = self.STATE_PLAY

	self:Start()

end


function FalloutServer:BuildInterfaceDefIGameMode()

	self:AddClassDef("FalloutServer", "IBase", "Manages the Fallout game mode on the server")

end


function FalloutServer:UnInitImp()

end


function FalloutServer:Start()

	print("Fallout game start!")

	self.gameClock:Reset()
	self.lastTimeSync = 0

	--Respawn all the players
	self:RespawnAllPlayers()

	--Reset all the scores
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		player.userData.falloutScore = 0
		self:UpdateScore(player)
		i = i + 1
	end

	self:SetGameState(self.STATE_PLAY)

end


function FalloutServer:End()

	print("Fallout game end!")

	self.gameClock:Reset()

	self:SetGameState(self.STATE_ROUND_OVER)

end


function FalloutServer:SetGameState(newGameState)

	self.gameState = newGameState

	print("New game state: " .. tostring(self.gameState))

	self.setGameStateParams:GetOrCreateParameter(0):SetIntData(self.gameState)
	--Time limit
	if self.gameState == self.STATE_PLAY then
		self.setGameStateParams:GetOrCreateParameter(1):SetFloatData(self.roundTimeLimit)
	elseif self.gameState == self.STATE_ROUND_OVER then
		self.setGameStateParams:GetOrCreateParameter(1):SetFloatData(self.roundOverWaitTime)
	end
	self.setGameStateSignal:Emit(self.setGameStateParams)

end


function FalloutServer:Process()

    local frameTime = GetFrameTime()
	if self.gameState == self.STATE_PLAY then
		self:ProcessStatePlay(frameTime)
	elseif self.gameState == self.STATE_ROUND_OVER then
		self:ProcessStateRoundOver(frameTime)
	end

end


function FalloutServer:ProcessStatePlay(frameTime)

	local currentTime = self.gameClock:GetTimeSeconds()

	if currentTime > self.roundTimeLimit then
		self:End()
	end

	if currentTime - self.lastTimeSync > self.timeSyncRate then
		self.lastTimeSync = currentTime
		print(tostring(self.roundTimeLimit - currentTime) .. " seconds left in round!")
	end

end


function FalloutServer:ProcessStateRoundOver(frameTime)

	if self.gameClock:GetTimeSeconds() > self.roundOverWaitTime then
		self:Start()
	end

end


function FalloutServer:GetProcessSlot()

	return self.processSlot

end


function FalloutServer:UpdateScore(player)

	--Emit the signal to indicate the score of this player
	self.updateScoreParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())

	self.updateScoreParams:GetOrCreateParameter(1):SetIntData(player.userData.falloutScore)
	self.updateScoreSignal:Emit(self.updateScoreParams)

end


function FalloutServer:TimeSyncRequest(syncRequestParams)

	self:SyncTime()

end


function FalloutServer:SyncTime()

	--Current time
	self.syncTimeParams:GetOrCreateParameter(0):SetFloatData(self.gameClock:GetTimeSeconds())
	self.syncTimeSignal:Emit(self.syncTimeParams)

end


function FalloutServer:PlayerFallout(falloutParams)

	--Only keep track of scores during play
	if self.gameState == self.STATE_PLAY then
		local player = GetPlayerManager():GetPlayer(falloutParams:GetParameter("Player", true):GetStringData())

		--Emit the notification of who fell out
		self.playerFalloutParams:GetOrCreateParameter(0):SetIntData(player:GetUniqueID())
		self.playerFalloutSignal:Emit(self.playerFalloutParams)

		player.userData.falloutScore = player.userData.falloutScore + 1
		print("Player: " .. player:GetName() .. " fell out of the map! New score: " .. tostring(player.userData.falloutScore))
		self:UpdateScore(player)
	end

end


function FalloutServer:RespawnAllPlayers()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		local player = GetPlayerManager():GetPlayer(i)
		GetServerManager():RespawnPlayer(player:GetUniqueID())
		i = i + 1
	end

end


function FalloutServer:ClientConnected(connectParams)

	local clientName = connectParams:GetParameterAtIndex(0, true):GetStringData()

	--Let this new client know which gamestate we are in
	self:SetGameState(self.gameState)

	--Init the score of this player
	local player = GetPlayerManager():GetPlayer(clientName)
	player.userData.falloutScore = 0

	--Send all the player scores so the new client is up to date
	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	local i = 1
	while i <= numPlayers do
		self:UpdateScore(GetPlayerManager():GetPlayer(i))
		i = i + 1
	end

end


function FalloutServer:ClientDisconnected(disconnectParams)

	local clientName = disconnectParams:GetParameterAtIndex(0, true):GetStringData()


end

--FALLOUTSERVER CLASS END