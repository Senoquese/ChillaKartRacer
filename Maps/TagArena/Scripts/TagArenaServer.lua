UseModule("ReverseTagServer", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil


function TagArenaLoad(tagMap)

	gameMode = ReverseTagServer(tagMap)

end


function TagArenaUnload()

	gameMode:UnInit()
	gameMode = nil

end