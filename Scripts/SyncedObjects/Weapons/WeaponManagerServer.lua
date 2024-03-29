UseModule("IBase", "Scripts/")

--WEAPONMANAGERSERVER CLASS START

class 'WeaponManagerServer' (IBase)

function WeaponManagerServer:__init() super()

	self.activeWeapons = { }
	self.players = { }

	--A weapon will signal us when it is done being used
	self.weaponUsedSlot = self:CreateSlot("WeaponUsed", "WeaponUsed")

	--These two signals will notify us when a client connects or disconnects from the server
	self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.clientConnectedSlot)

	self.clientDisconnectedSlot = self:CreateSlot("ClientDisconnected", "ClientDisconnected")
	--The player manager will keep us up to date
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.clientDisconnectedSlot)

	self.processSlot = self:CreateSlot("Process", "Process")
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	self.playerInputEventSlot = self:CreateSlot("PlayerInputEvent", "PlayerInputEvent")

end


function WeaponManagerServer:BuildInterfaceDefIBase()

	self:AddClassDef("WeaponManagerServer", "IBase", "Manages the weapons on the server")

end


function WeaponManagerServer:InitIBase()

end


function WeaponManagerServer:UnInitIBase()

	--Remove all weapons
	self:RemoveWeapons(nil)

end


function WeaponManagerServer:GivePlayerWeapon(player, weaponType)

	if IsValid(player) and IsValid(weaponType) then
		--Only give the player the weapon if they don't already have something in queue
		-- if not player:GetWeaponInQueue() then
			--No weapon in queue, this weapon is now considered to be in queue
			--even if it is the only weapon
			player:SetQueuedWeapon(weaponType)
		-- end
	end

end


--Create the weapon that the player has queued, remove the queued weapon, and
--assign the newly created weapon to the player as their active weapon
function WeaponManagerServer:CreateQueuedWeapon(forPlayer)

	--Does the player have a weapon in queue?
	if forPlayer:GetWeaponInQueue() then
		--We can only create the queued weapon if the player doesn't already have an active weapon
		if not IsValid(forPlayer:GetActiveWeapon()) then
			local createWeaponType = forPlayer:GetQueuedWeaponTypeName()
			--First, remove the weapon from the player's queue
			forPlayer:SetQueuedWeapon(nil)
			--Now create the previously queued weapon and assign it to the player
			local params = Parameters()
			--We have to let the new weapon know who owns it
			params:AddParameter(Parameter("OwnerID", Parameter.INT, forPlayer:GetUniqueID()))
			--An estimation is all we need for networking purposes
			params:AddParameter(Parameter("Position", forPlayer:GetPosition()))
			local createWeaponClock = WTimer()
			local newActiveWeapon = GetServerWorld():CreateObject(createWeaponType .. "_Weapon" .. tostring(GenerateID()), createWeaponType, true, params)

			print("Create new active weapon time: " .. tostring(createWeaponClock:GetTimeSeconds()))

			--Make connections
			newActiveWeapon:GetSignal("WeaponUsed", true):Connect(self.weaponUsedSlot)
			--Give this client ownership of the newly added weapon
			GetServerWorld():SetObjectOwner(newActiveWeapon:GetID(), forPlayer:GetUniqueID())
			--Notify the player of it's new active weapon
			forPlayer:SetActiveWeapon(newActiveWeapon)
			print("Player: " .. forPlayer:GetName() .. " got a " .. createWeaponType)
			--We need to track the life of this new weapon
			table.insert(self.activeWeapons, { forPlayer, ToScriptObject(newActiveWeapon) } )
			return ToScriptObject(newActiveWeapon)
		end
	end

	return nil

end


--Remove any weapons that the passed in player is in control of or in queue
--Pass nil to remove all weapons
function WeaponManagerServer:RemoveWeapons(player)

    local allWeaponIDs = { }
    for index, weapon in ipairs(self.activeWeapons) do
        if not IsValid(player) or (IsValid(weapon[1]) and weapon[1]:GetUniqueID() == player:GetUniqueID()) then
            table.insert(allWeaponIDs, weapon[2]:GetID())
        end
    end
    for index, weaponID in ipairs(allWeaponIDs) do
        self:_RemoveWeapon(weaponID)
    end
    --Notify the player
    if IsValid(player) then
        player:_RemoveWeapons()
    else
        for index, tablePlayer in ipairs(self.players) do
            tablePlayer.Player:_RemoveWeapons()
        end
    end

end


function WeaponManagerServer:_RemoveWeapon(weaponID)

	print("RemoveWeapon(" .. tostring(weaponID) .. ")")
	--Find the passed in weaponID in the weapon table
	for index, weapon in ipairs(self.activeWeapons) do
		if weapon[2]:GetID() == weaponID then
			GetServerWorld():DestroyObject(weaponID)
			table.remove(self.activeWeapons, index)
			break
		end
	end

end


function WeaponManagerServer:ClientConnected(connectParams)

    --NOTE: The next chunk takes almost 0 time
	local playerID = connectParams:GetParameterAtIndex(0, true):GetIntData()
	local connectPlayer = GetPlayerManager():GetPlayerFromID(playerID)	

	connectPlayer:GetSignal("InputEvent"):Connect(self.playerInputEventSlot)

	--We need to keep track of players internally
	--KeyDownFirst is a simple check to make sure the first input event is a key down
	table.insert(self.players, { Player = connectPlayer, KeyDownFirst = false } )

end


function WeaponManagerServer:ClientDisconnected(disconnectParams)

	local playerID = disconnectParams:GetParameterAtIndex(0, true):GetIntData()
	local disconnectPlayer = GetPlayerManager():GetPlayerFromID(playerID)

	--See if this player owns any of the weapons
	for index, weapon in ipairs(self.activeWeapons) do
		--Notify this weapon that this player is now invalid
		weapon[2]:Get():_PlayerInvalid(disconnectPlayer)
		if not IsValid(disconnectPlayer) then
			error("Disconnect player is invalid in ClientDisconnected")
		end
		--Check if the weapon has an owner and the owner is this disconnecting player
		if IsValid(weapon[1]) and weapon[1]:GetUniqueID() == disconnectPlayer:GetUniqueID() then
			--This weapon no longer has an owner
			weapon[1] = nil
		end
	end

	--Remove this player's controlled or queued items
	self:RemoveWeapons(disconnectPlayer)

	--Remove this player from our internal table
	for index, tablePlayer in ipairs(self.players) do
		if tablePlayer.Player:GetUniqueID() == disconnectPlayer:GetUniqueID() then
			table.remove(self.players, index)
			break
		end
	end

end


--When this weapon has been used by the player and the player no longer has
--control over it, the player can then pick up or use another weapon
--Note, the weapon might still be active even after it has been used (a mine on the field stays
--on the field for a period of time)
function WeaponManagerServer:WeaponUsed(weaponParams)

	--First find the weapon
	local weaponID = weaponParams:GetParameter(0, true):GetIntData()
	local weaponOwnerID = 0
	for index, weapon in ipairs(self.activeWeapons) do
		if weapon[2]:GetID() == weaponID then
			--Tell the player that this weapon is no longer the active weapon
			weapon[1]:SetActiveWeapon(nil)
			--Save off the weapon owner's ID
			weaponOwnerID = weapon[1]:GetUniqueID()
			break
		end
	end

	--Reset the input state for this weapon's owner
	for index, tablePlayer in ipairs(self.players) do
		if tablePlayer.Player:GetUniqueID() == weaponOwnerID then
			tablePlayer.KeyDownFirst = false
			break
		end
	end

end


--This function finds dead weapons and removes them from the world
function WeaponManagerServer:Process()

	for index, weapon in ipairs(self.activeWeapons) do
		if weapon[2]:Get():GetWeaponDead() then
			self:_RemoveWeapon(weapon[2]:GetID())
			break
		end
	end

end


function WeaponManagerServer:PlayerInputEvent(eventParams)

	local playerID = eventParams:GetParameter("PeerID", true):GetIntData()
	local pressed = eventParams:GetParameter("Pressed", true):GetBoolData()
	local keyID = eventParams:GetParameter("KeyID", true):GetIntData()
	local extraData = eventParams:GetParameter("ExtraData", false)

	--Find this player
	for index, tablePlayer in ipairs(self.players) do
		if tablePlayer.Player:GetUniqueID() == playerID then
			if keyID == InputMap.UseItemUp or keyID == InputMap.UseItemDown then
				--Create a new weapon if the player has one in queue but not an active one
				if tablePlayer.Player:GetWeaponInQueue() and (not IsValid(tablePlayer.Player:GetActiveWeapon())) and (pressed or tablePlayer.KeyDownFirst) then
					--At this point we know a keydown has happened first
					tablePlayer.KeyDownFirst = true
					local createdWeapon = self:CreateQueuedWeapon(tablePlayer.Player)
					--Now apply this input event to the created weapon
					if IsValid(createdWeapon) then
						createdWeapon:Get():KeyEvent(keyID, pressed, extraData)
					end
				end
			end
		end
	end

end

--WEAPONMANAGERSERVER CLASS END


local weaponManSingleton = WeaponManagerServer()
function GetWeaponManagerServer()

	return weaponManSingleton

end