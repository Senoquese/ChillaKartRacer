--IBASE CLASS START

--IBase is an interface for all objects defined in Lua
--It helps ensure that objects are cleaned up properly
--IBase is the bee's knees
class 'IBase'

function IBase:__init()

	self.unInitSignal = WSignal("UnInit")

	self.ibaseSignals = { }
	self.ibaseSlots = { }

	self.ibaseRegObject = nil

	--Just default to reference comparisons for IBase objects
	getmetatable(self).__eq = nil

	self.ibaseInterface = { }
	self.ibaseInterface["Classes"] = { }
	self.ibaseInterface["Functions"] = { }
	--Function types
	self.I_REQUIRED_FUNC = 0
	self.I_OPTIONAL_FUNC = 1
	self.I_PRIVATE_FUNC = 2
	self.I_PUBLIC_FUNC = 3

	--BRIAN TODO: Note, this could be done in some sort of "script debug mode" and skip for release mode
	self:_BuildInterfaceDef()
	self:_VerifyInterface()

end


--Call to define a class in the hierarchy of this class
function IBase:AddClassDef(name, baseName, desc)

	self.ibaseInterface["Classes"][name] = { Name = name, BaseName = baseName, Desc = desc }

end


--Call to define function that make up the interface of the class that derives from IBase
function IBase:AddFuncDef(className, func, type, name, desc)

	self.ibaseInterface["Functions"][name] = { ClassName = className, Func = func, Type = type, Name = name, Desc = desc }

end


--All interfaces should implement this function and call it in their __init()
function IBase:_VerifyInterface()

	local invalidFuncDefs = { }
	for funcName, funcDef in pairs(self.ibaseInterface["Functions"]) do
		--Function is invalid if it is required and doesn't exist
		if (funcDef.Type == self.I_REQUIRED_FUNC) and (not IsValid(funcDef.Func)) then
			invalidFuncDefs[funcName] = funcDef
		end
	end
	--Report problems
	local problems = ""
	for invalidFuncName, invalidFuncDef in pairs(invalidFuncDefs) do
		problems = problems .. "Function " .. invalidFuncName .. " missing from object of type " .. invalidFuncDef.ClassName .. "\n"
	end
	if string.len(problems) > 0 then
		local report = "Problems verifying interface for classes:"
		for className, classDef in pairs(self.ibaseInterface["Classes"]) do
			report = report .. "\n" .. className
		end
		report = report .. "\nProblems:\n" .. problems
		error(report)
	end

end


function IBase:_BuildInterfaceDef()

	self:AddClassDef("IBase", nil, "The root class for all other script classes to derive from")
	self:AddFuncDef("IBase", self.BuildInterfaceDefIBase, self.I_REQUIRED_FUNC, "BuildInterfaceDefIBase", "The child class must build their interface in this function")
	self:AddFuncDef("IBase", self.InitIBase, self.I_REQUIRED_FUNC, "InitIBase", "Called to notify the derived object that this is being Inited")
	self:AddFuncDef("IBase", self.UnInitIBase, self.I_REQUIRED_FUNC, "UnInitIBase", "Called to notify the derived object that this is being UnInited")
	self:AddFuncDef("IBase", self.NotifyDebugDrawEnabled, self.I_OPTIONAL_FUNC, "NotifyDebugDrawEnabled", "Called to notify the derived object that debug draw has been enabled or disabled")

	--Any child class must implement this function
	self:BuildInterfaceDefIBase()

end


function IBase:Init()

	self:InitIBase()

	if IsClient() then
		GetDebugDrawManager():AddDrawer(self)
	end

end


function IBase:UnInit()

	if IsClient() and IsValid(GetDebugDrawManager()) then
		GetDebugDrawManager():RemoveDrawer(self)
	end

	self:UnInitIBase()

	if IsValid(self.unInitSignal) then
		self.unInitSignal:Emit(Parameters())
		self.unInitSignal:DisconnectAll()
		self.unInitSignal = nil
	end

	--UnInit the signals
	for sigName, signal in pairs(self.ibaseSignals) do
		if IsValid(signal[1]) then
			signal[1]:DisconnectAll()
		end
		if IsValid(signal[2]) then
			signal[2]:UnInit()
		end
	end
	--Clear the table
	self.ibaseSignals = { }

	--UnInit the slots
	for slotName, slot in pairs(self.ibaseSlots) do
		if IsValid(slot[1]) then
			slot[1]:DisconnectAll()
		end
		if IsValid(slot[2]) then
			slot[2]:UnInit()
		end
	end
	--Clear the table
	self.ibaseSlots = { }

end


--Hide the actual signal creation from the user
function IBase:CreateSignal(signalName, networkSystem, reliable)

    if self:GetSignal(signalName, false) then
        print("Warning: Signal with name: " .. signalName .. " already created")
    end

	local newSignal = WSignal(signalName)
	local persistentSignal = nil

	if IsValid(networkSystem) then
		if not IsValid(reliable) or type(reliable) ~= "boolean" then
			error("reliable parameter not valid in IBase:CreateSignal()")
		end
		networkSystem:AddPersistentSignal(newSignal, reliable)
		persistentSignal = PersistentSignalWrapper(newSignal, networkSystem)
	end

	--Add it to the list
	self.ibaseSignals[signalName] = { newSignal, persistentSignal }

	return newSignal

end


--Hide the actual slot creation from the user
function IBase:CreateSlot(slotName, functionName, networkSystem)

    if self:GetSlot(slotName, false) then
        print("Warning: Slot with name: " .. slotName .. " already created")
    end

	local newSlot = WSlot(slotName, ScriptValueWrapper(self, self.unInitSignal, functionName), functionName)
	local persistentSlot = nil

	if IsValid(networkSystem) then
		networkSystem:AddPersistentSlot(newSlot, slotName)
		persistentSlot = PersistentSlotWrapper(newSlot, networkSystem)
	end

	--Add it to the list
	self.ibaseSlots[slotName] = { newSlot, persistentSlot }

	return newSlot

end


function IBase:DestroySignal(destroySignal)

	local foundSignal = self.ibaseSignals[destroySignal:GetName()]
	if IsValid(foundSignal) then
		if IsValid(foundSignal[1]) then
			foundSignal[1]:DisconnectAll()
		end
		if IsValid(foundSignal[2]) then
			foundSignal[2]:UnInit()
		end
	else
		error("Signal named " .. destroySignal:GetName() .. " not found")
	end

end


function IBase:DestroySlot(destroySlot)

	local foundSlot = self.ibaseSlots[destroySlot:GetName()]
	if IsValid(foundSlot) then
		if IsValid(foundSlot[1]) then
			foundSlot[1]:DisconnectAll()
		end
		if IsValid(foundSlot[2]) then
			foundSlot[2]:UnInit()
		end
	else
		error("Slot named " .. destroySlot:GetName() .. " not found")
	end

end


--Retrieve a created signal from this object
function IBase:GetSignal(signalName, throwOnNotFound)

	local retSignal = self.ibaseSignals[signalName]
	if (not IsValid(retSignal)) and (IsValid(self.ibaseRegObject)) then
		retSignal = { self.ibaseRegObject:GetSignal(signalName, false) }
	end
	if IsValid(retSignal) then
		return retSignal[1]
	end

	if (not IsValid(throwOnNotFound)) or (throwOnNotFound == true) then
		error("No signal with name: " .. signalName .. " in IBase:GetSignal()")
	end

	return nil

end


--Retrieve a created slot from this object
function IBase:GetSlot(slotName, throwOnNotFound)

	local retSlot = self.ibaseSlots[slotName]
	if (not IsValid(retSlot)) and (IsValid(self.ibaseRegObject)) then
		retSlot = { self.ibaseRegObject:GetSlot(slotName, false) }
	end
	if IsValid(retSlot) then
		return retSlot[1]
	end

	if (not IsValid(throwOnNotFound)) or (throwOnNotFound == true) then
		error("No slot with name: " .. slotName .. " in IBase:GetSlot()")
	end

	return nil

end


function IBase:RegisterSignalsAndSlots(regObject)

	self.ibaseRegObject = regObject

	--Add the signals
	for sigName, signal in pairs(self.ibaseSignals) do
		self.ibaseRegObject:RegisterScriptSignal(sigName, signal[1])
	end

	--Add the slots
	for slotName, slot in pairs(self.ibaseSlots) do
		self.ibaseRegObject:RegisterScriptSlot(slotName, slot[1])
	end

end


function IBase:SetDebugDrawEnabled(enabled)

	if IsValid(self.NotifyDebugDrawEnabled) then
		self:NotifyDebugDrawEnabled(enabled)
	end

end

--IBASE CLASS END