UseModule("RaceClient", ASSET_DIR .. "Scripts\\GameModes\\Race\\")

local gameMode = nil

function RainbowRoadMapLoad(raceMap)

	gameMode = RaceClient(raceMap)

end


function RainbowRoadMapUnload()

	gameMode:UnInit()
	gameMode = nil

end
