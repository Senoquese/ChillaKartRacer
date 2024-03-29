
--GUIDIALOGREQUIRERESTART CLASS START

class 'GUIDialogRequireRestart' (IBase)

function GUIDialogRequireRestart:__init() super()

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	self:InitGUISignalsAndSlots()

end


function GUIDialogRequireRestart:BuildInterfaceDefIBase()

	self:AddClassDef("GUIDialogRequireRestart", "IBase", "The Require Restart GUI manager")

end


function GUIDialogRequireRestart:InitIBase()

end


function GUIDialogRequireRestart:InitGUISignalsAndSlots()

	--Slots
	self.leftButtonClickedSlot = self:CreateSlot("leftButtonClick", "LeftButtonClicked")
	--self.flashPage:RequestSlotConnectToSignal(self.leftButtonClickedSlot, "leftButtonClick")
	
	self.rightButtonClickedSlot = self:CreateSlot("rightButtonClick", "RightButtonClicked")
	--self.flashPage:RequestSlotConnectToSignal(self.rightButtonClickedSlot, "rightButtonClick")

end


function GUIDialogRequireRestart:UnInitIBase()

end


function GUIDialogRequireRestart:SetVisible(setVis)

end


function GUIDialogRequireRestart:GetVisible()

	return false

end


--Called when the left button is pushed
function GUIDialogRequireRestart:LeftButtonClicked(buttonParams)

    self:SetVisible(false)
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    
end


--Called when the right button is pushed
function GUIDialogRequireRestart:RightButtonClicked(buttonParams)

    self:SetVisible(false)
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()

end

--GUIDIALOGREQUIRERESTART CLASS END