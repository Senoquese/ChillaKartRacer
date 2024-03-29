UseModule("ReverseTagServer", ASSET_DIR .. "Scripts/GameModes/ReverseTag/")

local gameMode = nil

--local savedGravity = nil

function FalloutMapLoad(falloutMap)

	--savedGravity = WVector3(GetBulletPhysicsSystem():GetGravity())
	--GetBulletPhysicsSystem():SetGravity(WVector3(0, -5, 0))

	gameMode = ReverseTagServer(falloutMap)

end


function FalloutMapUnload()

	--GetBulletPhysicsSystem():SetGravity(savedGravity)

	gameMode:UnInit()
	gameMode = nil

end