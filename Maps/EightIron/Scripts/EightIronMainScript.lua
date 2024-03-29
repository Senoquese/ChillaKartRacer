UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function EightIronMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function EightIronMapUnload()

	gameMode:UnInit()
	gameMode = nil

end