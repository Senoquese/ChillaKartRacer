UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function SpaceRaceMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function SpaceRaceMapUnload()

	gameMode:UnInit()
	gameMode = nil

end