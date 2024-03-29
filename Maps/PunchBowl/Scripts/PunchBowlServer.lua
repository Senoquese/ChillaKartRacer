UseModule("ReverseTagServer", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil

function PunchBowlLoad(tagMap)

	gameMode = ReverseTagServer(tagMap)

end


function PunchBowlUnload()

	gameMode:UnInit()
	gameMode = nil

end