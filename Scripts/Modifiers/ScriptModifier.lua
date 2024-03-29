UseModule("IBase", "Scripts/")

--SCRIPTMODIFIER CLASS START

class 'ScriptModifier' (IBase)

function ScriptModifier:__init() super()

	self.callbackSignal = self:CreateSignal("Callback")
	self.callbackParams = Parameters()

end


function ScriptModifier:BuildInterfaceDefIBase()

	self:AddClassDef("ScriptModifier", "IBase", "Defines a class which will modify an object or value over time")

end


function ScriptModifier:InitIBase()

end


function ScriptModifier:UnInitIBase()

end


function ScriptModifier:GetCallbackSignal()

	return self.callbackSignal

end


function ScriptModifier:EmitCallback()

	self.callbackSignal:Emit(self.callbackParams)

end


function ScriptModifier:Process()

end

--SCRIPTMODIFIER CLASS END