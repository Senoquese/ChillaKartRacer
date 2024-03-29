UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function WestMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function WestMapUnload()

	gameMode:UnInit()
	gameMode = nil

end