UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ChillMountainMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function ChillMountainMapUnload()

	gameMode:UnInit()
	gameMode = nil

end