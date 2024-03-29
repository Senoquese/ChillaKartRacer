UseModule("SoccerClient", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function KickItLoad(map)

	gameMode = SoccerClient(map)

end


function KickItUnload()


	gameMode:UnInit()
	gameMode = nil

end