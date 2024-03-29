UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function SpaceRaceMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function SpaceRaceMapUnload()

	gameMode:UnInit()
	gameMode = nil

end