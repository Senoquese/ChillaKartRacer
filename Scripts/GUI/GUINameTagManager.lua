UseModule("IBase", "Scripts/")
UseModule("GUINameTag", "Scripts/GUI/")

--GUINAMETAGMANAGER CLASS START

class 'GUINameTagManager' (IBase)

function GUINameTagManager:__init() super()

	self.mapUnloadSlot = self:CreateSlot("MapUnloadSlot", "MapUnloadSlot")
	GetMapLoader():GetSignal("MapUnloadStart"):Connect(self.mapUnloadSlot)

	self.processSlot = self:CreateSlot("Process", "Process")
	--Process after the objects have processed so
	--that the player's positions are up to date
	GetOGRESystem():GetSignal("ProcessBegin", true):Connect(self.processSlot)

	self.playerAddedSlot = self:CreateSlot("PlayerAdded", "PlayerAdded")
	GetPlayerManager():GetPlayerAddedSignal():Connect(self.playerAddedSlot)

	self.playerRemovedSlot = self:CreateSlot("PlayerRemoved", "PlayerRemoved")
	GetPlayerManager():GetPlayerRemovedSignal():Connect(self.playerRemovedSlot)

	self.camera = GetCamera()
	self.boundingBox = WAxisAlignedBox()

	--This is where the name starts to fade away
	self.fallOffStart = 75
	--This is where the name has faded away completely
	self.fallOffEnd = 150

	self.forceAllVisible = false

	self.nameTagGUIs = { }

end


function GUINameTagManager:BuildInterfaceDefIBase()

	self:AddClassDef("GUINameTagManager", "IBase", "Manages all the name tags that float over player's heads")

end


function GUINameTagManager:InitIBase()

end


function GUINameTagManager:UnInitIBase()

	--UnInit the list of name tags
	for player, tag in ipairs(self.nameTagGUIs) do
		tag:UnInit()
	end
	self.nameTagGUIs = { }

end


function GUINameTagManager:Process()

	for index, tag in ipairs(self.nameTagGUIs) do
		if IsValid(tag:GetPlayer()) and IsValid(tag:GetPlayer():GetController()) then
			self.boundingBox:Set(tag:GetPlayer():GetController():GetBoundingBox())
			self.boundingBox:Translate(tag:GetPlayer():GetPosition())
			if self.camera:GetVisible(self.boundingBox) then
				--Check that the name didn't change
				if tag:GetDisplayedName() ~= tag:GetPlayer():GetName() then
					tag:UpdateName()
				end
				local nameTagPos = WVector3(tag:GetPlayer():GetPosition())
				nameTagPos.y = nameTagPos.y + self.boundingBox:GetHeight()
				nameTagPos = WorldVectorToScreen(nameTagPos, self.camera)
				tag:SetPosition(nameTagPos)
				local distanceToCam = self.camera:GetPosition():Distance(tag:GetPlayer():GetPosition())
				local opacity = distanceToCam / self.fallOffEnd
				if self.forceAllVisible then
					tag:SetVisible(true)
				elseif opacity > 1 then
					tag:SetVisible(false)
				else
					--More opaque the closer it gets
					tag:SetOpacity(1 - opacity)
					tag:SetVisible(true)
				end
			else
				tag:SetVisible(false)
			end
		end
	end

end


function GUINameTagManager:PlayerAdded(playerParams)

	local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()
	local player = GetPlayerManager():GetPlayerFromID(playerID)

	if not player:IsLocalPlayer() then
		table.insert(self.nameTagGUIs, GUINameTag(player, 1, 1, 1) )
	end

end


function GUINameTagManager:PlayerRemoved(playerParams)

	local playerID = playerParams:GetParameterAtIndex(0, true):GetIntData()

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:UnInit()
			table.remove(self.nameTagGUIs, index)
			return
		end
	end

end


function GUINameTagManager:SetPlayerColor(playerID, setRed, setGreen, setBlue)

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:SetColor(setRed, setGreen, setBlue)
		end
	end

end


function GUINameTagManager:SetForceVisible(playerID, setVis)

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:SetForceVisible(setVis)
		end
	end

end


function GUINameTagManager:GetForceVisible(playerID)

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:GetForceVisible()
		end
	end

end


function GUINameTagManager:SetForceInvisible(playerID, setVis)

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:SetForceInvisible(setVis)
		end
	end

end


function GUINameTagManager:GetForceInvisible(playerID)

	for index, tag in ipairs(self.nameTagGUIs) do
		if tag:GetPlayer():GetUniqueID() == playerID then
			tag:GetForceInvisible()
		end
	end

end


function GUINameTagManager:SetForceAllVisible(setForce)

	self.forceAllVisible = setForce

end


function GUINameTagManager:GetForceAllVisible()

	return self.forceAllVisible

end


function GUINameTagManager:MapUnloadSlot(unloadParams)

	self.forceAllVisible = false

	--Default all colors back to white
	for index, tag in ipairs(self.nameTagGUIs) do
		self:SetPlayerColor(tag:GetPlayer():GetUniqueID(), 1, 1, 1)
	end

end

--GUINAMETAGMANAGER CLASS END