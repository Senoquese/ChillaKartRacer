UseModule("FreeServer", ASSET_DIR .. "Scripts\\GameModes\\Free\\")

local gameMode = nil

function SkateLoad(tagMap)

    gameMode = FreeServer(tagMap)

end


function SkateUnload()

    gameMode:UnInit()
	gameMode = nil

end