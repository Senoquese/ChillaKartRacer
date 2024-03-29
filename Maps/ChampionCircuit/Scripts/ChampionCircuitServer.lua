UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ChampionCircuitMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function ChampionCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end