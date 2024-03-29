UseModule("SoccerClient", ASSET_DIR .. "Scripts/GameModes/Soccer/")

local gameMode = nil

function TouchdownLoad(map)

	gameMode = SoccerClient(map)

end


function TouchdownUnload()


	gameMode:UnInit()
	gameMode = nil

end