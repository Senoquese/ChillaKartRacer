UseModule("IWeaponPicker", "Scripts/SyncedObjects/Weapons/")

--WEAPONPICKERRANDOM CLASS START

local WEAPON_TYPES = 0
local setTypes = function (value) WEAPON_TYPES = value end
local getTypes = function () return WEAPON_TYPES end
DefineVar("WEAPON_TYPES", setTypes, getTypes)

--The WeaponPickerRandom chooses a weapon type at random.

class 'WeaponPickerRandom_norepulse' (IWeaponPicker)

function WeaponPickerRandom_norepulse:__init() super()


	self.allWeaponTypeNames = { "SyncedLUVBot" , "SyncedIceCube", "SyncedSeaMine", "SyncedPuncher", "SyncedTwister", "SyncedSpring" }


end


--This is the prototype for the function that should return the name of the weapon type to create
function WeaponPickerRandom_norepulse:PickWeapon()

	local chooseList = self.allWeaponTypeNames
	if WEAPON_TYPES == 1 then
		chooseList = self.noMinesTypeNames
	end
	local random = math.modf((Random() * #chooseList) + 1)
	return chooseList[random]

end

--WEAPONPICKERRANDOM CLASS END