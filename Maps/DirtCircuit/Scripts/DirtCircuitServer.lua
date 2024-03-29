UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function DirtCircuitMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function DirtCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end