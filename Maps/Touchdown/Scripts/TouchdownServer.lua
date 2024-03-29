UseModule("SoccerServer", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function TouchdownLoad(map)

	gameMode = SoccerServer(map)

end


function TouchdownUnload()

	gameMode:UnInit()
	gameMode = nil

end