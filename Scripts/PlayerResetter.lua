UseModule("IBase", "Scripts/")

--PLAYERRESETTER CLASS START

--BRIAN TODO: Make an IScriptObject
class 'PlayerResetter' (IBase)

function PlayerResetter:__init() super()

	self.resetPlayerSlot = self:CreateSlot("ResetPlayer", "ResetPlayer")

end


function PlayerResetter:BuildInterfaceDefIBase()

	self:AddClassDef("PlayerResetter", "IBase", "Resets the player when its slot is emitted to")

end


function PlayerResetter:InitIBase()

end


function PlayerResetter:UnInitIBase()

end


function PlayerResetter:SetParameter(param)

end


function PlayerResetter:Process()

end


function PlayerResetter:EnumerateParameters(params)

end


--This is the meat'n'potatoes of the PlayerResetter
function PlayerResetter:ResetPlayer(params)

	local playerID = params:GetParameter("Player", true):GetIntData()
	local reason = ""
    if IsValid(params:GetParameter("Reason", false)) then
        reason = params:GetParameter("Reason", true):GetStringData()
    end
	GetServerManager():GetGameMode():RespawnPlayerAtLastNode(playerID, reason)

end

--PLAYERRESETTER CLASS END