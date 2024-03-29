UseModule("PlayerManager", ASSET_DIR .. "Scripts/")

--PLAYERMANAGERCLIENT CLASS START

class 'PlayerManagerClient' (PlayerManager)

function PlayerManagerClient:__init(setMap) super()

	self.localPlayer = nil

end


--Override the RemoveAllPlayers call to set the localPlayer to nil
function PlayerManagerClient:RemoveAllPlayers()

	--Call the original function
	PlayerManager.RemoveAllPlayers(self)
	self.localPlayer = nil

end


function PlayerManagerClient:SetLocalPlayer(setPlayer)

	self.localPlayer = setPlayer

end


function PlayerManagerClient:GetLocalPlayer()

	return self.localPlayer

end

--PLAYERMANAGERCLIENT CLASS END


local playerManSingleton = PlayerManagerClient()
function GetPlayerManager()

	return playerManSingleton

end