UseModule("JumpTargetClient", ASSET_DIR .. "Scripts/GameModes/JumpTarget/")

local gameMode = nil

function PachinkoLoad(map)

	gameMode = JumpTargetClient(map)

end


function PachinkoUnload()

	gameMode:UnInit()
	gameMode = nil

end