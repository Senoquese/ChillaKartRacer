--GUISERVERMESSAGE CLASS START

class 'GUIServerMessage' (IBase)

function GUIServerMessage:__init() super()

    self.ddPrefix = "Disconnect_"
	self.ddGUILayout = GetMyGUISystem():LoadLayout("dialog_single.layout", self.ddPrefix)
	self.ddCont = self.ddGUILayout:GetWidget(self.ddPrefix .. "cont")
	self.ddBox = self.ddCont:FindWidget(self.ddPrefix .. "box")
    self.message = ToEdit(self.ddCont:FindWidget(self.ddPrefix .. "bodytext"))
    self.button = ToButton(self.ddCont:FindWidget(self.ddPrefix .. "button"))

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	self:InitGUISignalsAndSlots()

	self.serverMessageSlot = self:CreateSlot("ServerMessage", "ServerMessage")
	self.serverMessageSlot:Connect(GetClientSystem():GetSignal("ServerMessage", true))

	self:SetVisible(false)

	self.messageQueue = { }

end


function GUIServerMessage:InitIBase()

end


function GUIServerMessage:BuildInterfaceDefIBase()

	self:AddClassDef("GUIServerMessage", "IBase", "The Server Message GUI manager")

end


function GUIServerMessage:InitGUISignalsAndSlots()

	--Slots
	self.leftButtonClickedSlot = self:CreateSlot("LeftButtonClicked", "LeftButtonClicked")
	GetMyGUISystem():RegisterEvent(self.button, "eventMouseButtonClick", self.leftButtonClickedSlot)

end


function GUIServerMessage:SetStrings(serverMessage)

    --TODO: Localization
    --Left Button
    self.button:SetCaption(StringToUTFString("Continue"))
    
    --Dialog Title
    self.ddBox:SetCaption(StringToUTFString("Server Message"))

    --Dialog Body Text
    self.message:SetOnlyText(StringToUTFString(serverMessage))

end


function GUIServerMessage:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.ddGUILayout)
	self.ddGUILayout = nil

end


function GUIServerMessage:SetVisible(setVisible)

    self.ddGUILayout:SetVisible(setVisible)

end


function GUIServerMessage:GetVisible()

    return self.ddGUILayout:GetVisible()

end


function GUIServerMessage:LeftButtonClicked(buttonParams)

    if not self:CheckQueuedMessages() then
        self:SetVisible(false)
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    end

end


function GUIServerMessage:RightButtonClicked(buttonParams)

    if not self:CheckQueuedMessages() then
        self:SetVisible(false)
        GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
        GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    end

end


function GUIServerMessage:ServerMessage(serverMessageParams)

	local serverMessage = serverMessageParams:GetParameter("Message", true):GetStringData()
	local popup = serverMessageParams:GetParameter("Popup", true):GetBoolData()
	if popup then
        if not self:GetVisible() then
            self:PostMessage(serverMessage)
        else
            table.insert(self.messageQueue, serverMessage)
        end
    else
        GetMenuManager():GetChat():AddMessage(GetMenuManager():GetChat().chatColorServer, serverMessage)
    end

end


function GUIServerMessage:PostMessage(serverMessage)

    print("Server Message: " .. serverMessage)
	self:SetStrings(serverMessage)
	self:SetVisible(true)

end


function GUIServerMessage:CheckQueuedMessages()

    if #self.messageQueue > 0 then
        local serverMessage = self.messageQueue[1]
        table.remove(self.messageQueue, 1)
        self:PostMessage(serverMessage)
        return true
    end
    return false

end

--GUISERVERMESSAGE CLASS END