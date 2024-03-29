UseModule("IWeaponPicker", "Scripts/SyncedObjects/Weapons/")

--WEAPONPICKERRANDOM CLASS START

local WEAPON_TYPES = 0
local setTypes = function (value) WEAPON_TYPES = value end
local getTypes = function () return WEAPON_TYPES end
DefineVar("WEAPON_TYPES", setTypes, getTypes)

--The WeaponPickerRandom chooses a weapon type at random.

class 'WeaponPickerRandom' (IWeaponPicker)

function WeaponPickerRandom:__init() super()

	--self.allWeaponTypeNames = { "SyncedPuncher" }
	self.allWeaponTypeNames = { "SyncedLUVBot" , "SyncedIceCube", "SyncedSeaMine", "SyncedPuncher", "SyncedTwister", "SyncedRepulsor", "SyncedSpring" }
	--self.allWeaponTypeNames = { "KartItemSeaMine", "KartItemPuncher", "KartItemIceCube", "KartItemTornado" }
	--self.noMinesTypeNames = { "KartItemPuncher", "KartItemIceCube", "KartItemTornado" }
	--self.allWeaponTypeNames = { "SyncedIceCube" }

end


--This is the prototype for the function that should return the name of the weapon type to create
function WeaponPickerRandom:PickWeapon()

	local chooseList = self.allWeaponTypeNames
	if WEAPON_TYPES == 1 then
		chooseList = self.noMinesTypeNames
	end
	local random = math.modf((Random() * #chooseList) + 1)
	return chooseList[random]

end

--WEAPONPICKERRANDOM CLASS END