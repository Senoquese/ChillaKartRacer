UseModule("IBase", "Scripts/")

--CUSTOMITEMMANAGER CLASS START

--The CustomItemManager is for managing the CustomItemSystem
--and it's relation to Ogre's resource system
class 'CustomItemManager' (IBase)

function CustomItemManager:__init() super()

end


function CustomItemManager:BuildInterfaceDefIBase()

	self:AddClassDef("CustomItemManager", "IBase", "Manages all the custom items the player has access to")

end


function CustomItemManager:InitIBase()

end


function CustomItemManager:UnInitIBase()

	self:UnloadResources()

end


function CustomItemManager:ScanItems()

	self:UnloadResources()
	GetCustomItemSystem():ScanItems(ASSET_DIR .. "CustomItems\\")
	self:LoadResources()

end


function CustomItemManager:LoadResources()

	--Iterate over all custom item groups, iterate over all items
	--in groups, add their path to the ogre resource system
	local groupIter = GetCustomItemSystem():GetIterator()
	while not groupIter:IsEnd() do
		local currentGroup = groupIter:Get()
		local itemIter = currentGroup:GetIterator()
		while not itemIter:IsEnd() do
			local currentItem = itemIter:Get()
			LoadOgreResourceGroup(currentItem:GetPath(), currentItem:GetPath(), "FileSystem", false)
			itemIter:Next()
		end
		groupIter:Next()
	end

end


function CustomItemManager:UnloadResources()

	--Iterate over all custom item groups, iterate over all items
	--in groups, unload them from the ogre resource system
	local groupIter = GetCustomItemSystem():GetIterator()
	while not groupIter:IsEnd() do
		local currentGroup = groupIter:Get()
		local itemIter = currentGroup:GetIterator()
		while not itemIter:IsEnd() do
			local currentItem = itemIter:Get()
			UnloadOgreResourceGroup(currentItem:GetPath(), currentItem:GetPath())
			itemIter:Next()
		end
		groupIter:Next()
	end
	ClearUnreferencedResources()

end


local customItemManager = CustomItemManager()
function GetCustomItemManager()

	return customItemManager

end