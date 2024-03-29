UseModule("SoccerServer", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function HoopsLoad(map)

	gameMode = SoccerServer(map)

end


function HoopsUnload()

	gameMode:UnInit()
	gameMode = nil

end