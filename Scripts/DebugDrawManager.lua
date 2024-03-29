UseModule("IBase", "Scripts/")

--DEBUGDRAWMANAGER CLASS START

--The DebugDrawManager is used to notify registered objects to draw debug info
class 'DebugDrawManager' (IBase)

function DebugDrawManager:__init() super()

	self.debugDrawEnabled = false
	self.registeredObjects = { }

end


function DebugDrawManager:BuildInterfaceDefIBase()

	self:AddClassDef("DebugDrawManager", "IBase", "Used to notify registered objects to draw debug info")

end


function DebugDrawManager:InitIBase()

end


function DebugDrawManager:UnInitIBase()

end


function DebugDrawManager:SetEnabled(enabled)

	if self.debugDrawEnabled ~= enabled then
		self.debugDrawEnabled = enabled
		for index, drawer in ipairs(self.registeredObjects) do
			drawer:SetDebugDrawEnabled(self.debugDrawEnabled)
		end
	end

end


function DebugDrawManager:GetEnabled()

	return self.debugDrawEnabled

end


function DebugDrawManager:AddDrawer(addDrawer)

	table.insert(self.registeredObjects, addDrawer)
	--Notify this object of the current draw state
	addDrawer:SetDebugDrawEnabled(self.debugDrawEnabled)

end


function DebugDrawManager:RemoveDrawer(removeDrawer)

	for index, drawer in ipairs(self.registeredObjects) do
		if drawer == removeDrawer then
			table.remove(self.registeredObjects, index)
			break
		end
	end

end

--DEBUGDRAWMANAGER CLASS END