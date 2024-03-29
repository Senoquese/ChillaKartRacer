--SPECTATORMANAGER CLASS START

class 'SpectatorManager' (IBase)

function SpectatorManager:__init() super()

    self.camCombiner = CamControllerKartCombiner(nil, GetCamera())
    self.enabled = false
    self.followPlayer = nil
    self.followObjUnInitSlot = self:CreateSlot("FollowObjUnInit", "FollowObjUnInit")
    self.followObjUnInitSignal = self:CreateSignal("FollowObjUnInit")

end


function SpectatorManager:BuildInterfaceDefIBase()

	self:AddClassDef("SpectatorManager", "IBase", "Manages spectator mode")

end


function SpectatorManager:InitIBase()

end


function SpectatorManager:SetEnabled(isEnabled)

    if isEnabled ~= self.enabled then
        self.enabled = isEnabled
        if self.enabled then
            print("Enabling SpectatorManager")
            GetCameraManager():AddController(self.camCombiner, 4)
        else
            GetCameraManager():RemoveController(self.camCombiner)
        end
    end

end


function SpectatorManager:GetEnabled()

    return self.enabled

end


function SpectatorManager:SetFollowPlayer(player)

    if IsValid(player) and player ~= self.followPlayer then
        print("SpectatorManager setting follow player: "..player:GetName())
        self.followPlayer = player
        self:SetFollowObject(player:GetController())
    elseif not IsValid(player) then
        print("SpectatorManager setting follow player to nil")
        self.followPlayer = nil
        self:SetFollowObject(nil)
    end

end


function SpectatorManager:GetFollowPlayer()

    return self.followPlayer

end


function SpectatorManager:SetFollowObject(object)

    if IsValid(object) and object ~= self:GetFollowObject() then
        print("SpectatorManager setting follow object:"..object:GetName())
        self.camCombiner:SetFollowObject(object)
        self.followObjUnInitSlot:DisconnectAll()
        self.followObjUnInitSlot:Connect(object:GetSignal("UnInitBegin", true))
    elseif not IsValid(object) then
        print("SpectatorManager setting follow object to nil")
        self.camCombiner:SetFollowObject(nil)
        self.followObjUnInitSlot:DisconnectAll()
    end

end


function SpectatorManager:GetFollowObject()

    return self.camCombiner:GetFollowObject()

end


function SpectatorManager:UnInitIBase()

	self.cameraControllers = nil
	self.activeController = nil

end


function SpectatorManager:FollowObjUnInit()

    self.followObjUnInitSignal:Emit(Parameters())

end

--SPECTATORMANAGER CLASS END