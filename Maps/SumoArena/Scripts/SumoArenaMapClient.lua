UseModule("SumoClient", ASSET_DIR .. "Scripts/GameModes/Sumo/")

local gameMode = nil

function SumoArenaMapLoad(sumoMap)

	gameMode = SumoClient(sumoMap)

end


function SumoArenaMapUnload()

	gameMode:UnInit()
	gameMode = nil

end