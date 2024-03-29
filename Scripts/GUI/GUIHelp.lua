
--GUIHELP CLASS START

class 'GUIHelp' (IBase)

function GUIHelp:__init() super()

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	self:InitGUISignalsAndSlots()

	self.selectExitSignal = self:CreateSignal("ExitHelp")

end


function GUIHelp:BuildInterfaceDefIBase()

	self:AddClassDef("GUIHelp", "IBase", "The Help Menu GUI manager")

end


function GUIHelp:InitIBase()

end


function GUIHelp:InitGUISignalsAndSlots()

	self.exitHelpSlot = self:CreateSlot("ExitHelp", "ExitHelp")
	--self.flashPage:RequestSlotConnectToSignal(self.exitHelpSlot, "CloseHelp")

end


function GUIHelp:UnInitIBase()

end


function GUIHelp:SetVisible(setVis)

end


function GUIHelp:GetVisible()

	return false

end


function GUIHelp:ExitHelp(exitParams)

	self.selectExitSignal:Emit(exitParams)

end

--GUIHELP CLASS END