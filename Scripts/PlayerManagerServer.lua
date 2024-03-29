UseModule("PlayerManager", ASSET_DIR .. "Scripts/")

--PLAYERMANAGERSERVER CLASS START

class 'PlayerManagerServer' (PlayerManager)

function PlayerManagerServer:__init(setMap) super()

end

--PLAYERMANAGERSERVER CLASS END


local playerManSingleton = PlayerManagerServer()
function GetPlayerManager()

	return playerManSingleton

end