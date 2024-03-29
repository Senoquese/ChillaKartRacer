UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function AquaRaceMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function AquaRaceMapUnload()

	gameMode:UnInit()
	gameMode = nil

end