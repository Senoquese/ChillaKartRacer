--GUIWEAPONBOX CLASS START

class 'GUIWeaponBox' (IBase)

function GUIWeaponBox:__init() super()

	self.wbPrefix = "Weapon_"
	self.wbGUILayout = GetMyGUISystem():LoadLayout("weapon.layout", self.wbPrefix)
	self.contParent = self.wbGUILayout:GetWidget(self.wbPrefix .. "weaponboxes")

	self.wbCont = self.contParent:FindWidget(self.wbPrefix .. "weaponbg")
	self.icon = ToStaticImage(self.wbCont:FindWidget(self.wbPrefix .. "weaponimg"))

	self.awbCont = self.contParent:FindWidget(self.wbPrefix .. "altweaponbg")
	self.iconAlt = ToStaticImage(self.awbCont:FindWidget(self.wbPrefix .. "altweaponimg"))
	
	--Hide icon
	self:SetWeapon("")
	self:SetAltWeapon("")
end


function GUIWeaponBox:BuildInterfaceDefIBase()

	self:AddClassDef("GUIWeaponBox", "IBase", "The weapon box GUI manager")

end


function GUIWeaponBox:InitIBase()

end


function GUIWeaponBox:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.wbGUILayout)
	self.wbGUILayout = nil
	
end


function GUIWeaponBox:SetVisible(visible)
	self.wbGUILayout:SetVisible(visible)
end


function GUIWeaponBox:SetWeapon(thumb)
	if thumb == self.curThumb then
		return
	end

	if thumb == "" then
		self.icon:SetVisible(false)
	else
		self.icon:SetVisible(true)
		self.icon:SetImageTexture(thumb)
	end
	
	self.curThumb = thumb
end

function GUIWeaponBox:SetAltWeapon(thumb)
	if thumb == self.curAltThumb then
		return
	end

	if thumb == "" then
		self.iconAlt:SetVisible(false)
	else
		self.iconAlt:SetVisible(true)
		self.iconAlt:SetImageTexture(thumb)
	end
	
	self.curAltThumb = thumb
end

--GUIWEAPONBOX CLASS END