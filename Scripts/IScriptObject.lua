UseModule("IBase", "Scripts/")

--ISCRIPTOBJECT CLASS START
--Any object that a ScriptObject main contain needs to derive from IScriptObject
--All IScriptObject objects must implement the following functions:
--ProcessScriptObject()

--All IScriptObject objects may optionally implement the following functions:
--NotifyScriptObjectPositionChange(pos) - Will be called when SetPosition() is called on the ScriptObject
--NotifyScriptObjectOrientationChange(orien) - Will be called when SetOrientation() is called on the ScriptObject
--NotifyScriptObjectScaleChange(scale) - Will be called when SetScale() is called on the ScriptObject
--GetBoundingBox() - Return a WAxisAlignedBox containing the object
--SetStateData()
--GetStateData()
--GetActive()
--KeyEvent()
--SetParameter()
--EnumerateParameters()
--Init()
--UnInit()

--Signals:
--Slots:

class 'IScriptObject' (IBase)

function IScriptObject:__init() super()

	self.name = "DefaultScriptObjectName"
	self.ID = 0
	self.scriptObject = nil
	self.notifyTransLock = false
	self.internalPos = WVector3()
	self.internalOrien = WQuaternion()
	self.internalScale = WVector3()
	self.internalLinVel = WVector3()

end


function IScriptObject:BuildInterfaceDefIBase()

	self:AddClassDef("IScriptObject", "IBase", "Any object that a ScriptObject main contain needs to derive from IScriptObject")
	self:AddFuncDef("IScriptObject", self.ProcessScriptObject, self.I_REQUIRED_FUNC, "ProcessScriptObject", "Will be called to give this IScriptObject processing time")
	self:AddFuncDef("IScriptObject", self.GetActive, self.I_REQUIRED_FUNC, "GetActive", "Inactive objects are not synced over the network")
	self:AddFuncDef("IScriptObject", self.BuildInterfaceDefIScriptObject, self.I_REQUIRED_FUNC, "BuildInterfaceDefIScriptObject", "The child class must build their interface in this function")

	self:BuildInterfaceDefIScriptObject()

end


function IScriptObject:InitIBase()

end


function IScriptObject:UnInitIBase()

end


function IScriptObject:SetName(setName)

	self.name = setName

end


function IScriptObject:GetName()

	return self.name

end


function IScriptObject:SetID(setID)

	self.ID = setID

end


function IScriptObject:GetID()

	return self.ID

end


function IScriptObject:RegisterSignalsAndSlots(regObject)

	self.scriptObject = regObject

	--IBase needs to be called
	IBase.RegisterSignalsAndSlots(self, regObject)

end


function IScriptObject:SetPosition(setPos, allowNotification)

	if allowNotification == false then
		self.notifyTransLock = true
	end

	if IsValid(self.scriptObject) then
		self.scriptObject:SetPosition(setPos)
	else
		self.internalPos = WVector3(setPos)
	end

	self.notifyTransLock = false

end


function IScriptObject:GetPosition()

	if IsValid(self.scriptObject) then
		return self.scriptObject:GetPosition()
	else
		return self.internalPos
	end

end


function IScriptObject:SetOrientation(setOrien, allowNotification)

	if allowNotification == false then
		self.notifyTransLock = true
	end

	if IsValid(self.scriptObject) then
		self.scriptObject:SetOrientation(setOrien)
	else
		self.internalOrien = WQuaternion(setOrien)
	end

	self.notifyTransLock = false

end


function IScriptObject:GetOrientation()

	if IsValid(self.scriptObject) then
		return self.scriptObject:GetOrientation()
	else
		return self.internalOrien
	end

end


function IScriptObject:SetScale(setScale, allowNotification)

	if allowNotification == false then
		self.notifyTransLock = true
	end

	if IsValid(self.scriptObject) then
		self.scriptObject:SetScale(setScale)
	else
		self.internalScale = WVector3(setScale)
	end

	self.notifyTransLock = false

end


function IScriptObject:GetScale()

	if IsValid(self.scriptObject) then
		return self.scriptObject:GetScale()
	else
		return self.internalScale
	end

end


function IScriptObject:SetLinearVelocity(setLinVel, allowNotification)

	if allowNotification == false then
		self.notifyTransLock = true
	end

	if IsValid(self.scriptObject) then
		self.scriptObject:SetLinearVelocity(setLinVel)
	else
		self.internalLinVel = WVector3(setLinVel)
	end

	self.notifyTransLock = false

end


function IScriptObject:GetLinearVelocity()

	if IsValid(self.scriptObject) then
		return self.scriptObject:GetLinearVelocity()
	else
		return self.internalLinVel
	end

end


function IScriptObject:NotifyPositionChange(setPos)

	if not self.notifyTransLock and IsValid(self.NotifyScriptObjectPositionChange) then
		self:NotifyScriptObjectPositionChange(setPos)
	end

end


function IScriptObject:NotifyOrientationChange(setOrien)

	if not self.notifyTransLock and IsValid(self.NotifyScriptObjectOrientationChange) then
		self:NotifyScriptObjectOrientationChange(setOrien)
	end

end


function IScriptObject:NotifyScaleChange(setScale)

	if not self.notifyTransLock and IsValid(self.NotifyScriptObjectScaleChange) then
		self:NotifyScriptObjectScaleChange(setScale)
	end

end


function IScriptObject:Process(frameTime)

	self:ProcessScriptObject(frameTime)

end

--ISCRIPTOBJECT CLASS END