UseModule("SoccerServer", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function KickItLoad(map)

	gameMode = SoccerServer(map)

end


function KickItUnload()

	gameMode:UnInit()
	gameMode = nil

end