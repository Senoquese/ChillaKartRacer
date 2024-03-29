UseModule("SoccerClient", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function HoopsLoad(map)

	gameMode = SoccerClient(map)

end


function HoopsUnload()


	gameMode:UnInit()
	gameMode = nil

end