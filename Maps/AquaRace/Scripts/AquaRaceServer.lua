UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function AquaRaceMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function AquaRaceMapUnload()

	gameMode:UnInit()
	gameMode = nil

end