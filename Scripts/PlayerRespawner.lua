UseModule("IBase", "Scripts/")

--PLAYERRESPAWNER CLASS START

--BRIAN TODO: Make an IScriptObject
class 'PlayerRespawner' (IBase)

function PlayerRespawner:__init() super()

	self.respawnPlayerSlot = self:CreateSlot("RespawnPlayer", "RespawnPlayer")

end


function PlayerRespawner:BuildInterfaceDefIBase()

	self:AddClassDef("PlayerRespawner", "IBase", "Respawns a player when its slot is emitted to")

end


function PlayerRespawner:InitIBase()

end


function PlayerRespawner:UnInitIBase()

end


function PlayerRespawner:SetParameter(param)

end


function PlayerRespawner:Process()

end


function PlayerRespawner:EnumerateParameters(params)

end


--This is the meat'n'potatoes of the PlayerRespawner
function PlayerRespawner:RespawnPlayer(params)

    local reason = nil
    if IsValid(params:GetParameter("Reason", false)) then
        reason = params:GetParameter("Reason", true):GetStringData()
    end
	GetServerManager():RespawnPlayer(params:GetParameter("Player", true):GetIntData(), nil, nil, nil, reason)

end

--SENSOR CLASS END