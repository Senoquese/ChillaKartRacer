UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function ChampionCircuitMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function ChampionCircuitMapUnload()

	gameMode:UnInit()
	gameMode = nil

end