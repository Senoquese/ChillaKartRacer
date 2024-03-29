--GUISERVERTIMEOUT CLASS START

class 'GUIServerTimeout' (IBase)

function GUIServerTimeout:__init() super()

    self.ddPrefix = "Timeout_"
	self.ddGUILayout = GetMyGUISystem():LoadLayout("dialog_single.layout", self.ddPrefix)
	self.ddCont = self.ddGUILayout:GetWidget(self.ddPrefix .. "cont")
	self.ddBox = self.ddCont:FindWidget(self.ddPrefix .. "box")
    self.message = ToEdit(self.ddCont:FindWidget(self.ddPrefix .. "bodytext"))
    self.button = ToButton(self.ddCont:FindWidget(self.ddPrefix .. "button"))

    self:SetStrings()

	self:InitGUISignalsAndSlots()

	self.peerConnectionInterruptedSlot = self:CreateSlot("PeerConnectionInterrupted", "PeerConnectionInterrupted")
	self.peerConnectionInterruptedSlot:Connect(GetClientSystem():GetSignal("PeerConnectionInterrupted", true))

	self.peerConnectionTimedOutSlot = self:CreateSlot("PeerConnectionTimedOut", "PeerConnectionTimedOut")
	self.peerConnectionTimedOutSlot:Connect(GetClientSystem():GetSignal("PeerConnectionTimedOut", true))

	self.peerConnectionReestablishedSlot = self:CreateSlot("PeerConnectionReestablished", "PeerConnectionReestablished")
	self.peerConnectionReestablishedSlot:Connect(GetClientSystem():GetSignal("PeerConnectionReestablished", true))

	self:SetVisible(false)

end


function GUIServerTimeout:InitIBase()

end


function GUIServerTimeout:BuildInterfaceDefIBase()

	self:AddClassDef("GUIServerTimeout", "IBase", "The Server Timeout GUI manager")

end


function GUIServerTimeout:InitGUISignalsAndSlots()

	--Slots
	self.leftButtonClickedSlot = self:CreateSlot("LeftButtonClicked", "LeftButtonClicked")
	GetMyGUISystem():RegisterEvent(self.button, "eventMouseButtonClick", self.leftButtonClickedSlot)

end


function GUIServerTimeout:SetStrings()

    --TODO: Localization
    --Left Button
    self.button:SetCaption(StringToUTFString("Disconnect"))
    
    --Dialog Title
    self.ddBox:SetCaption(StringToUTFString("What da heck?"))

    --Dialog Body Text
    self.message:SetOnlyText(StringToUTFString("Connection has been interrupted and may timeout in a few seconds"))

end


function GUIServerTimeout:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.ddGUILayout)
	self.ddGUILayout = nil

end


function GUIServerTimeout:SetVisible(setVisible)

    self.ddGUILayout:SetVisible(setVisible)

end


function GUIServerTimeout:GetVisible()

    return self.ddGUILayout:GetVisible()

end


function GUIServerTimeout:LeftButtonClicked(buttonParams)

	--The user has decided to give up waiting for the server to respond
	GetClientSystem():RequestDisconnect()

	self:SetVisible(false)
	GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    
end


function GUIServerTimeout:PeerConnectionInterrupted(peerConnectionInterruptedParams)

    --This will happen in ping request mode, no need to panic
    if (not GetClientSystem():GetInRequestPingMode()) then
	    self:SetVisible(true)
	end
	
end


function GUIServerTimeout:PeerConnectionTimedOut(peerConnectionTimedOutParams)

	self:SetVisible(false)

end


function GUIServerTimeout:PeerConnectionReestablished(peerConnectionReestablishedParams)

	self:SetVisible(false)

end

--GUISERVERTIMEOUT CLASS END