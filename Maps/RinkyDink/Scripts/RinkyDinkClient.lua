UseModule("SoccerClient", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function RinkyDinkLoad(map)

	gameMode = SoccerClient(map)

end


function RinkyDinkUnload()


	gameMode:UnInit()
	gameMode = nil

end