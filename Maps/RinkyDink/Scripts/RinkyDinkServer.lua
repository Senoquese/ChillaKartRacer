UseModule("SoccerServer", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function RinkyDinkLoad(map)

	gameMode = SoccerServer(map)

end


function RinkyDinkUnload()

	gameMode:UnInit()
	gameMode = nil

end