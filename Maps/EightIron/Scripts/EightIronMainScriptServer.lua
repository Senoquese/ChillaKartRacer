UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function EightIronMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function EightIronMapUnload()

	gameMode:UnInit()
	gameMode = nil

end