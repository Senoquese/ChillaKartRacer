UseModule("IBase", "Scripts/")

--IWEAPONPICKER CLASS START

--The IWeaponPicker is an interface to a class that picks a weapon.
--based on some criteria.
class 'IWeaponPicker' (IBase)

function IWeaponPicker:__init() super()

end


function IWeaponPicker:BuildInterfaceDefIBase()

	self:AddClassDef("IWeaponPicker", "IBase", "An interface for a class that picks a weapon based on some factor")
	self:AddFuncDef("IWeaponPicker", self.PickWeapon, self.I_REQUIRED_FUNC, "PickWeapon", "Return an ISyncedWeapon")

end


function IWeaponPicker:InitIBase()

end


function IWeaponPicker:UnInitIBase()

end


--[[
--This is the prototype for the function that should return the name of the weapon type to create
--The child class needs to implement this function
function IWeaponPicker:PickWeapon()

end
--]]

--IWEAPONPICKER CLASS END