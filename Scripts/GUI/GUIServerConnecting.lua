--GUISERVERCONNECTING CLASS START

class 'GUIServerConnecting' (IBase)

function GUIServerConnecting:__init() super()

    self.ddPrefix = "ServerConnecting_"
	self.ddGUILayout = GetMyGUISystem():LoadLayout("dialog_single.layout", self.ddPrefix)
	self.ddCont = self.ddGUILayout:GetWidget(self.ddPrefix .. "cont")
	self.ddBox = self.ddCont:FindWidget(self.ddPrefix .. "box")
    self.message = ToEdit(self.ddCont:FindWidget(self.ddPrefix .. "bodytext"))
    self.button = ToButton(self.ddCont:FindWidget(self.ddPrefix .. "button"))

    self:SetStrings()

	self:InitGUISignalsAndSlots()

	self:SetVisible(false)

end


function GUIServerConnecting:InitIBase()

end


function GUIServerConnecting:BuildInterfaceDefIBase()

	self:AddClassDef("GUIServerConnecting", "IBase", "The Server Connecting GUI manager")

end


function GUIServerConnecting:InitGUISignalsAndSlots()

	--Slots
	self.leftButtonClickedSlot = self:CreateSlot("LeftButtonClicked", "LeftButtonClicked")
	GetMyGUISystem():RegisterEvent(self.button, "eventMouseButtonClick", self.leftButtonClickedSlot)

end


function GUIServerConnecting:SetStrings()

    --TODO: Localization
    --Left Button
    self.button:SetCaption(StringToUTFString("Cancel"))
    
    --Dialog Title
    self.ddBox:SetCaption(StringToUTFString("All good things come in due time"))

    --Dialog Body Text
    self.message:SetOnlyText(StringToUTFString("Connecting..."))

end


function GUIServerConnecting:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.ddGUILayout)
	self.ddGUILayout = nil

end


function GUIServerConnecting:SetVisible(setVisible)

    self.ddGUILayout:SetVisible(setVisible)

end


function GUIServerConnecting:GetVisible()

    return self.ddGUILayout:GetVisible()

end


function GUIServerConnecting:LeftButtonClicked(buttonParams)

    GetClientSystem():SetQueuedConnectAddress("")
	--The user has decided to give up waiting for the server to respond
	GetClientSystem():RequestDisconnect()
	GetMenuManager():SetForceConnGUIVis(false)

	self:SetVisible(false)
	GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    
end

--GUISERVERCONNECTING CLASS END