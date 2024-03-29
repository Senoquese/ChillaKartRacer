--GUIDIALOGGENERAL CLASS START

class 'GUIDialogGeneral' (IBase)

function GUIDialogGeneral:__init() super()

    self.dgPrefix = "DialogGeneral_"
	self.dgGUILayout = GetMyGUISystem():LoadLayout("dialog_single.layout", self.dgPrefix)
	self.dgCont = self.dgGUILayout:GetWidget(self.dgPrefix .. "cont")
	self.dgBox = self.dgCont:FindWidget(self.dgPrefix .. "box")
    self.message = ToEdit(self.dgCont:FindWidget(self.dgPrefix .. "bodytext"))
    self.button = ToButton(self.dgCont:FindWidget(self.dgPrefix .. "button"))

    self.leftButtonClickedSlot = self:CreateSlot("LeftButtonClicked", "LeftButtonClicked")
	GetMyGUISystem():RegisterEvent(self.button, "eventMouseButtonClick", self.leftButtonClickedSlot)

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

    --Signals
    self.selectExitSignal = self:CreateSignal("ExitDialogGeneral")

end


function GUIDialogGeneral:BuildInterfaceDefIBase()

	self:AddClassDef("GUIDialogGeneral", "IBase", "The General Dialog GUI manager")

end


function GUIDialogGeneral:InitIBase()

end


function GUIDialogGeneral:SetStrings(setMessage)

    self.button:SetCaption(StringToUTFString("OK"))
    self.dgBox:SetCaption(StringToUTFString("Warning"))
    self.message:SetOnlyText(StringToUTFString(setMessage))

end


function GUIDialogGeneral:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.dgGUILayout)
	self.dgGUILayout = nil

end


function GUIDialogGeneral:SetVisible(setVisible)

    self.dgGUILayout:SetVisible(setVisible)

end


function GUIDialogGeneral:GetVisible()

    return self.dgGUILayout:GetVisible()

end


function GUIDialogGeneral:LeftButtonClicked(buttonParams)

    self.selectExitSignal:Emit(self.nullParams)
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
	self:SetVisible(false)
    
end


function GUIDialogGeneral:RightButtonClicked(buttonParams)

    self.selectExitSignal:Emit(self.nullParams)
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
	self:SetVisible(false)

end


--GUIDialogGeneral CLASS END