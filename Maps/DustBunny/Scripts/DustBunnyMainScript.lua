UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function DustBunnyMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function DustBunnyMapUnload()

	gameMode:UnInit()
	gameMode = nil

end