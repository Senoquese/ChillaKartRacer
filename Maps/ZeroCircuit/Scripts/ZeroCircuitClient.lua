UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ZeroCircuitMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function ZeroCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end