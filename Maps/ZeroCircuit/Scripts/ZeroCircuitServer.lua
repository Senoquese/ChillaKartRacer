UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ZeroCircuitMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function ZeroCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end