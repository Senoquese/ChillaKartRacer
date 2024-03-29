UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function DustBunnyMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function DustBunnyMapUnload()

	gameMode:UnInit()
	gameMode = nil

end