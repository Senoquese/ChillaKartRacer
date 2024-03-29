UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function DirtCircuitMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function DirtCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end