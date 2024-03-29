UseModule("ReverseTagClient", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil

function PunchBowlLoad(tagMap)

	gameMode = ReverseTagClient(tagMap)

end


function PunchBowlUnload()


	gameMode:UnInit()
	gameMode = nil

end