UseModule("IBase", "Scripts/")
UseModule("Player", ASSET_DIR .. "Scripts/")
UseModule("AchievementManager", "Scripts/")

--PLAYERMANAGER CLASS START

class 'PlayerManager' (IBase)

function PlayerManager:__init(setMap) super()

	self.players = { }

    self.achievements = AchievementManager()

	--These signals will be emitted when a player connects and disconnects
	self.playerAddedSignal = self:CreateSignal("PlayerAdded")
	self.playerRemovedSignal = self:CreateSignal("PlayerRemoved")
	self.playerSignalParams = Parameters()

	--Grab some processing time
	self.processSlot = self:CreateSlot("Process", "Process")
	--We will process after the script system
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

end


function PlayerManager:BuildInterfaceDefIBase()

	self:AddClassDef("PlayerManager", "IBase", "Manages all the players")

end


function PlayerManager:InitIBase()

end


function PlayerManager:UnInitIBase()

end


function PlayerManager:Process(processParams)

	for index, player in pairs(self.players) do
		player:Process()
	end

end


function PlayerManager:GetNumberOfPlayers()

	return #self.players

end


function PlayerManager:GetNumberOfHumanPlayers()

    local numHumans = 0
    for index, player in pairs(self.players) do
		if not player:GetBot() then
		    numHumans = numHumans + 1
		end
	end
	return numHumans

end


function PlayerManager:AddPlayer(addPlayer)

	if not IsValid(addPlayer) then
		error("Invalid player passed into PlayerManager:AddPlayer()")
	end

	local playerExists = self:GetPlayerFromID(addPlayer:GetUniqueID())
	if not IsValid(playerExists) then
		table.insert(self.players, addPlayer)
	else
		error("Player named " .. addPlayer:GetName() .. " is already in the PlayerManager")
	end

	--Notify of this new player
	self.playerSignalParams:GetOrCreateParameter(0):SetIntData(addPlayer:GetUniqueID())
	self.playerSignalParams:GetOrCreateParameter(1):SetStringData(addPlayer:GetName())
	local playerManagerAddedSignalClock = WTimer()
	self.playerAddedSignal:Emit(self.playerSignalParams)
	print("** PlayerManagerAddedSignal Time: " .. tostring(playerManagerAddedSignalClock:GetTimeSeconds()))
		
    --Check for BFFs
    --BRIAN TODO: Disabled until fixed
    --[[if IsClient() then
        --Check the number of friends in the lobby game server, not the lobby as somebody pinging
        --a server will technically be in the lobby
        local bffs = GetSteamClientSystem():GetNumFriendsInSource(GetSteamClientSystem():GetCurrentLobby():GetLobbyGameServer())
        print("Address: " .. tostring(GetSteamClientSystem():GetCurrentLobby():GetAddress()))
        print("Friends: " .. tostring(bffs))
        if bffs > 3 then
            self.achievements:Unlock(self.achievements.AVMT_BFF)
        end
    end--]]

end


--Return the player that matches the passed in index or name
function PlayerManager:GetPlayer(from)

	local isNumber = type(from) == "number"
	local isString = type(from) == "string"
	for index, player in pairs(self.players) do
		if isNumber then
			if index == from then
				return player
			end
		elseif isString then
			if player:GetName() == from then
				return player
			end
		end
	end
	return nil

end


--Return the player that matches the passed in unique ID
function PlayerManager:GetPlayerFromID(id)

	for index, player in pairs(self.players) do
		if player:GetUniqueID() == id then
			return player
		end
	end
	return nil

end


--Return the player that owns the passed in object
function PlayerManager:GetPlayerFromObjectID(mapObjectID)

	for index, player in pairs(self.players) do
		if player:DoesOwn(mapObjectID) then
			return player
		end
	end

	return nil

end


function PlayerManager:RemovePlayer(removePlayer)

	for index, player in pairs(self.players) do
		if player:GetUniqueID() == removePlayer:GetUniqueID() then

			local playerID = player:GetUniqueID()
			local playerName = player:GetName()

			--Notify of this removed player
			self.playerSignalParams:GetOrCreateParameter(0):SetIntData(playerID)
			self.playerSignalParams:GetOrCreateParameter(1):SetStringData(playerName)
			self.playerRemovedSignal:Emit(self.playerSignalParams)

			player:UnInit()

			table.remove(self.players, index)
			return
		end
	end

end


function PlayerManager:RemoveAllPlayers()

	for index, player in pairs(self.players) do

		local playerID = player:GetUniqueID()
		local playerName = player:GetName()

		--Notify of this removed player
		self.playerSignalParams:GetOrCreateParameter(0):SetIntData(playerID)
		self.playerSignalParams:GetOrCreateParameter(1):SetStringData(playerName)
		self.playerRemovedSignal:Emit(self.playerSignalParams)

		player:UnInit()

	end

	self.players = { }

end


function PlayerManager:ResetUserData()

	for index, player in pairs(self.players) do
		player:ResetUserData()
	end

end


function PlayerManager:GetPlayerAddedSignal()

	return self.playerAddedSignal

end


function PlayerManager:GetPlayerRemovedSignal()

	return self.playerRemovedSignal

end

--PLAYERMANAGER CLASS END