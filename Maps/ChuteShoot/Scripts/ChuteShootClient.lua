UseModule("JumpTargetClient", ASSET_DIR .. "Scripts/GameModes/JumpTarget/")

local gameMode = nil

function ChuteShootLoad(map)

	gameMode = JumpTargetClient(map)

end


function ChuteShootUnload()

	gameMode:UnInit()
	gameMode = nil

end