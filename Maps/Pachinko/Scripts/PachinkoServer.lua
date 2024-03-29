UseModule("JumpTargetServer", ASSET_DIR .. "Scripts/GameModes/JumpTarget/")

local gameMode = nil

function PachinkoLoad(map)

	gameMode = JumpTargetServer(map)

end


function PachinkoUnload()

	gameMode:UnInit()
	gameMode = nil

end