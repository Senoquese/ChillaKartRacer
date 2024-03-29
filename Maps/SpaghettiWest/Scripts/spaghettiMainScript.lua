UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function WestMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function WestMapUnload()

	gameMode:UnInit()
	gameMode = nil

end