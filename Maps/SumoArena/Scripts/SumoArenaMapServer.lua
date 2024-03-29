UseModule("SumoServer", ASSET_DIR .. "Scripts/GameModes/Sumo/")

local gameMode = nil

function SumoArenaMapLoad(sumoMap)

	gameMode = SumoServer(sumoMap)

end


function SumoArenaMapUnload()

	gameMode:UnInit()
	gameMode = nil

end