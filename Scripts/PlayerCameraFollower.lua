UseModule("IScriptObject", "Scripts/")
UseModule("CamControllerLookAt", "Scripts/Modifiers/CameraControllers/")

--PLAYERCAMERAFOLLOWER CLASS START

--The PlayerCameraFollower gets emitted an ON signal with a players name, it will
--set that player's camera to be the follow camera until it receives an
--OFF signal with that same players name
class 'PlayerCameraFollower' (IScriptObject)

function PlayerCameraFollower:__init() super()

	self.noPos = WVector3()
	self.noOrien = WQuaternion()

	self.followController = CamControllerLookAt(nil, GetCamera())

	self.setFollowOnSlot = self:CreateSlot("SetFollowOn", "SetFollowOn")
	self.setFollowOffSlot = self:CreateSlot("SetFollowOff", "SetFollowOff")

	--Connect the off slot to the player respawned signal for now
	GetClientManager():GetSignal("PlayerRespawned"):Connect(self.setFollowOffSlot)

end


function PlayerCameraFollower:BuildInterfaceDefIScriptObject()

	self:AddClassDef("PlayerCameraFollower", "IScriptObject", "A controller for the camera that forces the camera to not translate and rotate to follow a player")

end


function PlayerCameraFollower:SetParameter(param)

end


function PlayerCameraFollower:ProcessScriptObject(frameTime)

end


function PlayerCameraFollower:GetActive()

	return true

end


function PlayerCameraFollower:UpdateScriptObjectPosition()

	return self.noPos

end


function PlayerCameraFollower:UpdateScriptObjectOrientation()

	return self.noOrien

end


function PlayerCameraFollower:EnumerateParameters(params)

end


function PlayerCameraFollower:SetFollowOn(params)

	local playerID = params:GetParameter("Player", true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	--Simple lock to prevent this from happening to the same player twice
	if IsValid(player) and player.userData.cameraFollowingNow == true then
		return
	end

	--BRIAN TODO: HACK!
	if (not IsValid(player.userData.lookAtOffClock)) or (player.userData.lookAtOffClock:GetTimeSeconds() > 1) then
		if IsValid(player) then
			player.userData.cameraFollowingNow = true
		end

		--Play the wipeout animation for this player
		--BRIAN TODO: Need a better animation system
		if IsValid(player) and IsValid(player:GetController().SetWipeoutEnabled) then
			player:GetController():SetWipeoutEnabled(true)
		end

		if IsValid(player) and player:IsLocalPlayer() then
			--GetCameraManager():AddController(self.followController, 2)
			--Play fallout sound, only for the local player
			GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Fallout.wav", GetCamera():GetPosition(), 1, 0, false, SoundSystem.MEDIUM)
		end
	end

end


function PlayerCameraFollower:SetFollowOff(params)

	local playerID = params:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	if IsValid(player) then
		player.userData.cameraFollowingNow = false
	end

	--Stop the wipeout animation for this player
	if IsValid(player) then
		--BRIAN TODO: Need a better animation system
		if IsValid(player:GetController().SetWipeoutEnabled) then
			player:GetController():SetWipeoutEnabled(false)
		end
		--BRIAN TODO: HACK!
		player.userData.lookAtOffClock = WTimer()
		if player:IsLocalPlayer() then
			--GetCameraManager():RemoveController(self.followController)
		end
	end

end

--PLAYERCAMERAFOLLOWER CLASS END