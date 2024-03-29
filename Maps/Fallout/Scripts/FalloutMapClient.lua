UseModule("ReverseTagClient", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil

function FalloutMapLoad(falloutMap)

	gameMode = ReverseTagClient(falloutMap)

end


function FalloutMapUnload()


	gameMode:UnInit()
	gameMode = nil

end