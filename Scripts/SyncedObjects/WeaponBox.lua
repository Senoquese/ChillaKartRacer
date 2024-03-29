UseModule("IBase", "Scripts/")
UseModule("WeaponPickerFactory", "Scripts/SyncedObjects/Weapons/")
UseModule("ScaleModifier", "Scripts/Modifiers/")

--WEAPONBOX CLASS START

--WeaponBox
--BRIAN TODO: Make an IScriptObject
class 'WeaponBox' (IBase)

function WeaponBox:__init() super()

	self.STATE_SPAWNED = 0
	self.STATE_RESPAWNING = 1

	self.stateParam  = Parameter()

	self.name = "DefaultWeaponBoxName"
	self.ID = 0
	self.initParams = Parameters()

	self.graphicalBox = nil
	self.physicalBox = nil

	self.renderMeshName = ""
	self.boxAnim = nil
	self.boxScaler = nil

	self.boxGone = self:CreateSlot("BoxGone", "BoxGone")

	self.weaponPickerTypeName = ""
	self.weaponPicker = nil

	self.collisionStartSlot = self:CreateSlot("BoxStartCollision", "BoxStartCollision")
	self.collisionEndSlot = self:CreateSlot("BoxEndCollision", "BoxEndCollision")

    --Keep track of players currently inside of the box collision zone
	self.playersInBox = { }

	--Default spawn timer to 5 seconds
	self.spawnTimer = 5
	self.spawnClock = WTimer()

end


function WeaponBox:BuildInterfaceDefIBase()

	self:AddClassDef("WeaponBox", "IBase", "Defines a weapon box")

end


function WeaponBox:SetName(setName)

	self.name = setName

end


function WeaponBox:GetName()

	return self.name

end


function WeaponBox:SetID(setID)

	self.ID = setID

end


function WeaponBox:GetID()

	return self.ID

end


function WeaponBox:InitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:InitGraphical()
	else
		--The server simulates a physical object
		self:InitPhysical()
	end

end


function WeaponBox:InitGraphical()

	if not IsValid(self.weaponBoxID) then
		error("Weapon Box: " .. self:GetName() .. " was not assigned an WeaponBoxID before Init")
	end

	if IsValid(self.renderMeshName) then
		self.graphicalBox = OGREModel()
		self.graphicalBox:SetName(self.name .. "G")
		local modelParams = Parameters()
		modelParams:AddParameter(Parameter("RenderMeshName", self.renderMeshName))
		self.graphicalBox:Init(modelParams)
		self.boxAnim = self.graphicalBox:GetAnimation("idle", true)
		self.boxAnim:Play()
		--Start off invisible until spawned
		self.graphicalBox:SetVisible(false)
	end

	self.stateSlot = self:CreateSlot("StateSlot", "StateSlot")
	GetClientSystem():GetReceiveStateTable("Map"):WatchState("WeaponBox" .. tostring(self.weaponBoxID) .. "_State", self.stateSlot)

end


function WeaponBox:UnInitGraphical()

	if IsValid(self.graphicalBox) then
		self.graphicalBox:UnInit()
		self.graphicalBox = nil
		self.boxAnim = nil
	end

end


function WeaponBox:InitPhysical()

	if not IsValid(self.weaponBoxID) then
		error("Weapon Box: " .. self:GetName() .. " was not assigned an WeaponBoxID before Init")
	end

	self.physicalBox = BulletSensor()
	self.physicalBox:SetName(self.name .. "P")
	local physicsParams = Parameters()
	physicsParams:AddParameter(Parameter("Shape", "Cube"))
	physicsParams:AddParameter(Parameter("Dimensions", WVector3(3, 3, 3)))
	self.physicalBox:Init(physicsParams)
	self.physicalBox:GetSignal("StartCollision", true):Connect(self.collisionStartSlot)
	self.physicalBox:GetSignal("EndCollision", true):Connect(self.collisionEndSlot)

	GetServerSystem():GetSendStateTable("Map"):NewState("WeaponBox" .. tostring(self.weaponBoxID) .. "_State")

	--Start off spawned
	self:Spawn()

end


function WeaponBox:UnInitPhysical()

	if IsValid(self.physicalBox) then
		self.physicalBox:UnInit()
		self.physicalBox = nil
	end

	GetServerSystem():GetSendStateTable("Map"):RemoveState("WeaponBox" .. tostring(self.weaponBoxID) .. "_State")

end


function WeaponBox:UnInitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	else
		--The server simulates a physical object
		self:UnInitPhysical()
	end

end


function WeaponBox:DoesOwn(ownObjectID)

	return false

end


function WeaponBox:NotifyPositionChange(newPos)

	if IsClient() then
		if IsValid(self.graphicalBox) then
			self.graphicalBox:SetPosition(newPos)
		end
	else
		if IsValid(self.physicalBox) then
			self.physicalBox:SetPosition(newPos)
		end
	end

end


function WeaponBox:NotifyOrientationChange(newOrien)

	if IsClient() then
		if IsValid(self.graphicalBox) then
			self.graphicalBox:SetOrientation(newOrien)
		end
	else
		if IsValid(self.physicalBox) then
			self.physicalBox:SetOrientation(newOrien)
		end
	end

end


function WeaponBox:NotifyScaleChange(newScale)

	if IsClient() then
		if IsValid(self.graphicalBox) then
			self.savedScale = newScale
			self.graphicalBox:SetScale(newScale)
		end
	end

end


function WeaponBox:Process(frameTime)

	if self.state == self.STATE_SPAWNED then
		self:ProcessSpawned(frameTime)
	elseif self.state == self.STATE_RESPAWNING then
		self:ProcessWaitingToSpawn(frameTime)
	end

	if IsClient() then
		self.graphicalBox:Process(frameTime)
		self.boxAnim:Process(frameTime)
		if IsValid(self.boxScaler) then
			self.boxScaler:Process(frameTime)
		end
	else
		self.physicalBox:Process(frameTime)
	end

end


function WeaponBox:ProcessSpawned(frameTime)

end


function WeaponBox:ProcessWaitingToSpawn(frameTime)
	
	--Only the server processes this clock
	if IsServer() then
		if self.spawnClock:GetTimeSeconds() > self.spawnTimer then
			self:Spawn()
		end
	end

end


function WeaponBox:BoxStartCollision(collisionParams)

	--Find out what collided with this box
	local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	if IsValid(hitPlayer) then
	    table.insert(self.playersInBox, collideObjectID)
		self:Hit(hitPlayer)
	end

end


function WeaponBox:BoxEndCollision(collisionParams)

    local collideObjectID = collisionParams:GetParameter("CollideObjectID", true):GetIntData()
	local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(collideObjectID)
	if IsValid(hitPlayer) then
	    for index, playerObjID in ipairs(self.playersInBox) do
	        if playerObjID == collideObjectID then
	            table.remove(self.playersInBox, index)
	            break
	        end
	    end
	end

end


function WeaponBox:Hit(hitPlayer)

    --No collision if the box isn't spawned yet
	if self.state == self.STATE_RESPAWNING then
		return
	end

	--Give this player a weapon
	if IsValid(self.weaponPicker) then
		GetWeaponManagerServer():GivePlayerWeapon(hitPlayer, self.weaponPicker:PickWeapon())
	end

	--After it has been hit, reset the timer to respawn it
	self.spawnClock:Reset()

	self:SetState(self.STATE_RESPAWNING)

end


function WeaponBox:Spawn()

	self:SetState(self.STATE_SPAWNED)

	--Check if anyone is already collided with the box
	for index, playerObjID in ipairs(self.playersInBox) do
	    local hitPlayer = GetPlayerManager():GetPlayerFromObjectID(playerObjID)
	    if IsValid(hitPlayer) then
	        self:Hit(hitPlayer)
	        break
	    else
	        --Why would this ever happen?
	        table.remove(self.playersInBox, index)
	        break
	    end
	end

end


function WeaponBox:SetState(newState)

	if IsClient() then
		if newState ~= self.state then
			self.state = newState
			if self.state == self.STATE_SPAWNED then
				self:BoxSpawn()
			elseif self.state == self.STATE_RESPAWNING then
				self:BoxHit()
			end
		end
	else
		if newState ~= self.state then
			self.state = newState
			self.stateParam:SetIntData(self.state)
			--BRIAN TODO: Is it possible this is causes the Weapon Box State Table error?
			--Perhaps this weapon box has already been uninited which removes the WeaponBox state and then
			--This function gets called on the uninited Weapon Box anyway...
			if IsValid(self.physicalBox) then
			    GetServerSystem():GetSendStateTable("Map"):SetState("WeaponBox" .. tostring(self.weaponBoxID) .. "_State", self.stateParam)
		    else
		        print("")
		        print("")
		        print("")
		        print("+++++++++++++++++++++++++++ Warning: Detected WeaponBox StateTable problem, Please notify us! http://www.nimblebit.com/contact")
		        print("")
		        print("")
		        print("")
            end
		end
	end

end


--The server updates the client on the state here
function WeaponBox:StateSlot(stateParams)

	local newState = stateParams:GetParameterAtIndex(0, true):GetIntData()
	self:SetState(newState)

end


function WeaponBox:BoxHit()

	if IsValid(self.graphicalBox) then
		local scaleAmount = self.graphicalBox:GetScale()
		self.boxScaler = ScaleModifier(self.graphicalBox, WVector3(scaleAmount.x * 1.5, scaleAmount.y * 1.5, scaleAmount.z * 1.5), 0.25)
		self.boxScaler:GetCallbackSignal():Connect(self.boxGone)
		--Play hit sound
		--BRIAN TODO: Move the path out of here, into the map format perhaps
		GetSoundSystem():EmitSound(ASSET_DIR .. "sound/Item_Box.wav", self.graphicalBox:GetPosition(), 5, 1, true, SoundSystem.MEDIUM)
		--Show the hit effect
		GetParticleSystem():AddEffect("itemgrab", self.graphicalBox:GetPosition())
	end

end


function WeaponBox:BoxSpawn()

	if IsValid(self.graphicalBox) then
		self.graphicalBox:SetVisible(true)
	end

end


function WeaponBox:BoxGone(params)

	self.boxScaler = nil
	self.graphicalBox:SetVisible(false)
	if IsValid(self.savedScale) then
		self.graphicalBox:SetScale(self.savedScale)
	end

end


function WeaponBox:SetParameter(param)

	self.initParams:AddParameter(Parameter(param))
	if param:GetName() == "WeaponPicker" then
		self.weaponPickerTypeName = param:GetStringData()
		self.weaponPicker = WeaponPickerFactory():CreateWeaponPicker(self.weaponPickerTypeName)
	elseif param:GetName() == "SpawnTimer" then
		self.spawnTimer = param:GetFloatData()
	elseif param:GetName() == "RenderMeshName" then
		self.renderMeshName = param:GetStringData()
	elseif param:GetName() == "WeaponBoxID" then
		self.weaponBoxID = param:GetIntData()
	end

end


function WeaponBox:EnumerateParameters(params)

	params:AddParameter(Parameter("WeaponPicker", self.weaponPickerTypeName))
	params:AddParameter(Parameter("SpawnTimer", Parameter.FLOAT, self.spawnTimer))
	params:AddParameter(Parameter("RenderMeshName", self.renderMeshName))
	params:AddParameter(Parameter("WeaponBoxID", Parameter.INT, self.weaponBoxID))
	local i = 0
	while i < self.initParams:GetNumberOfParameters() do
		params:AddParameter(Parameter(self.initParams:GetParameter(i, true)))
		i = i + 1
	end

end

--WEAPONBOX CLASS END