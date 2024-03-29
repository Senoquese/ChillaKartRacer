UseModule("IBase", "Scripts/")
UseModule("WeaponPickerRandom", "Scripts/SyncedObjects/Weapons/")
UseModule("WeaponPickerRandom_norepulse", "Scripts/SyncedObjects/Weapons/")
UseModule("WeaponPickerRandom_puncher", "Scripts/SyncedObjects/Weapons/")

--WEAPONPICKERFACTORY CLASS START

class 'WeaponPickerFactory' (IBase)

function WeaponPickerFactory:__init() super()

	self.creationFuncs = { }

	self.creationFuncs["WeaponPickerRandom"] = function(setPlayer) return WeaponPickerRandom() end
	self.creationFuncs["WeaponPickerRandom_norepulse"] = function(setPlayer) return WeaponPickerRandom_norepulse() end

	self.creationFuncs["WeaponPickerRandom_puncher"] = function(setPlayer) return WeaponPickerRandom_puncher() end



end


function WeaponPickerFactory:BuildInterfaceDefIBase()

	self:AddClassDef("WeaponPickerFactory", "IBase", "A factory for different weapon pickers")

end


function WeaponPickerFactory:InitIBase()

end


function WeaponPickerFactory:UnInitIBase()

end


function WeaponPickerFactory:CreateWeaponPicker(weaponPickerType)

	local creationFunc = self.creationFuncs[weaponPickerType]
	if IsValid(creationFunc) then
		return creationFunc()
	end

	error("No creation function defined for weapon picker type: " .. weaponPickerType .. " in WeaponPickerFactory:CreateWeaponPicker()")

end

--WEAPONPICKERFACTORY CLASS END