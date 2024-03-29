UseModule("FreeClient", ASSET_DIR .. "Scripts\\GameModes\\Free\\")

local gameMode = nil

function SkateLoad(tagMap)
    gameMode = FreeClient(tagMap)
end


function SkateUnload()
    gameMode:UnInit()
	gameMode = nil
end