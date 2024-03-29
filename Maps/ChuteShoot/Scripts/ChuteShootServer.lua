UseModule("JumpTargetServer", ASSET_DIR .. "Scripts/GameModes/JumpTarget/")

local gameMode = nil

function ChuteShootLoad(map)

	gameMode = JumpTargetServer(map)

end


function ChuteShootUnload()

	gameMode:UnInit()
	gameMode = nil

end