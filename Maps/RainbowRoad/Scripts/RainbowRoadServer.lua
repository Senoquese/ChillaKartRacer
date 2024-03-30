UseModule("RaceServer", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function RainbowRoadMapLoad(raceMap)

	gameMode = RaceServer(raceMap)

end


function RainbowRoadMapUnload()

	gameMode:UnInit()
	gameMode = nil

end
