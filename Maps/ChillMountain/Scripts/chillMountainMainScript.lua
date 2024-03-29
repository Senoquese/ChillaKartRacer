UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ChillMountainMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function ChillMountainMapUnload()

	gameMode:UnInit()
	gameMode = nil

end