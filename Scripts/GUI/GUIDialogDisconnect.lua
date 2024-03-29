--GUIDIALOGDISCONNECT CLASS START

class 'GUIDialogDisconnect' (IBase)

function GUIDialogDisconnect:__init() super()

    self.ddPrefix = "Disconnect_"
	self.ddGUILayout = GetMyGUISystem():LoadLayout("dialog_single.layout", self.ddPrefix)
	self.ddCont = self.ddGUILayout:GetWidget(self.ddPrefix .. "cont")
    self.message = ToEdit(self.ddCont:FindWidget(self.ddPrefix .. "bodytext"))
    self.button = ToButton(self.ddCont:FindWidget(self.ddPrefix .. "button"))

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

    --self:SetStrings()

	--self:InitGUISignalsAndSlots()

    --Signals
    self.selectExitSignal = self:CreateSignal("ExitDialogDisconnect")

end



function GUIDialogDisconnect:InitIBase()

end


function GUIDialogDisconnect:InitGUISignalsAndSlots()

	--Slots

end


function GUIDialogDisconnect:SetStrings()

    --TODO: Localization
    --Left Button
    local leftParams = Parameters()
    leftParams:AddParameter(Parameter("", "Yes"))
    self.flashPage:CallFunction("setLeftButtonLabel", leftParams)

    --Left Button
    local rightParams = Parameters()
    rightParams:AddParameter(Parameter("", "No"))
    self.flashPage:CallFunction("setRightButtonLabel", rightParams)

    --Dialog Title
    local titleParams = Parameters()
    titleParams:AddParameter(Parameter("", "Disconnect"))
    self.flashPage:CallFunction("setTitle", titleParams)

    --Dialog Body Text
    local bodyParams = Parameters()
    bodyParams:AddParameter(Parameter("", "Do you want to exit the game?"))
    self.flashPage:CallFunction("setBody", bodyParams)

end

function GUIDialogDisconnect:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.ddGUILayout)
	self.ddGUILayout = nil

end

function GUIDialogDisconnect:SetVisible(setVisible)

    self.ddGUILayout:SetVisible(setVisible)

end

function GUIDialogDisconnect:GetVisible()

    return self.ddGUILayout:GetVisible()

end


--Called when the left button is pushed, this will connect to custom ip or selected server.
function GUIDialogDisconnect:LeftButtonClicked(buttonParams)

    GetClientSystem():RequestDisconnect()
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
    
end


--Called when the right button is pushed, this will refresh the server list.
function GUIDialogDisconnect:RightButtonClicked(buttonParams)

    self.selectExitSignal:Emit(self.nullParams)
    GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
	GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()

end


function GUIDialogDisconnect:SystemInited(initParams)

	self:InitGUISignalsAndSlots()

	self:SetStrings()

end


--GUIDIALOGDISCONNECT CLASS END