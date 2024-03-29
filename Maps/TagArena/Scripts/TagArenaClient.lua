UseModule("ReverseTagClient", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil

function TagArenaLoad(tagMap)

	gameMode = ReverseTagClient(tagMap)

end


function TagArenaUnload()

	gameMode:UnInit()
	gameMode = nil

end