--GUIESCAPEMENU CLASS START

class 'GUIEscapeMenu' (IBase)

function GUIEscapeMenu:__init() super()

    self.emPrefix = "Escape_"
	self.emGUILayout = GetMyGUISystem():LoadLayout("escmenu.layout", self.emPrefix)
	self.emCont = self.emGUILayout:GetWidget(self.emPrefix .. "cont")
    self.buttonResume = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_resume"))
    self.buttonInviteFriends = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_invitefriends"))
    self.buttonServer = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_server"))
    self.buttonSettings = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_settings"))
    --self.buttonBrowser = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_browser"))
    self.buttonQuit = ToButton(self.emCont:FindWidget(self.emPrefix .. "esc_quit"))

    -- if GetDemoMode() then
    --     self.buttonInviteFriends:SetCaption(StringToUTFString("#545454" .. self.buttonInviteFriends:GetCaption():AsUTF8()))
    --     --self.buttonBrowser:SetCaption(StringToUTFString("#545454" .. self.buttonBrowser:GetCaption():AsUTF8()))
    -- end

	self.mouseClickSlot = self:CreateSlot("MouseClick", "MouseClick")
	GetMyGUISystem():RegisterEvent(self.buttonResume, "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonInviteFriends, "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonSettings, "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonQuit, "eventMouseButtonClick", self.mouseClickSlot)
	GetMyGUISystem():RegisterEvent(self.buttonServer, "eventMouseButtonClick", self.mouseClickSlot)
	--GetMyGUISystem():RegisterEvent(self.buttonBrowser, "eventMouseButtonClick", self.mouseClickSlot)

    -- Listen for escape key
    self.keyEventSlot = self:CreateSlot("KeyEvent","KeyEvent")
    self.escState = 0
    GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)

    self.goToServerBrowserSignal = self:CreateSignal("GoToServerBrowser")
    self.goToServerSignal = self:CreateSignal("GoToServer")
    self.goToSettingsSignal = self:CreateSignal("GoToSettings")
    self.selectExitSignal = self:CreateSignal("ExitDialogDisconnect")
    self.nullParams = Parameters()

    -- Toggle server button
    local isServer = GetClientSystem():GetServerProcessRunning()
    self.buttonServer:SetVisible(isServer)

end


function GUIEscapeMenu:BuildInterfaceDefIBase()

	self:AddClassDef("GUIEscapeMenu", "IBase", "The Escape Menu GUI manager")

end


function GUIEscapeMenu:InitIBase()

end


function GUIEscapeMenu:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.emGUILayout)
	self.emGUILayout = nil
	
end


function GUIEscapeMenu:SetVisible(visible)

    self.escState = 0
    self.emGUILayout:SetVisible(visible)
    
    if visible then
        -- Toggle server button
        local isServer = GetClientSystem():GetServerProcessRunning()
        self.buttonServer:SetVisible(isServer)
    end

end


function GUIEscapeMenu:GetVisible()

    return self.emGUILayout:GetVisible()

end


function GUIEscapeMenu:KeyEvent(keyParams)
    local key = keyParams:GetParameter("Key", true):GetIntData()
    if self:GetVisible() and GetClientInputManager():GetKeyCodeMatches(key, "Escape") and self.escState > 0 then
        self.selectExitSignal:Emit(self.nullParams)
    end

    if self:GetVisible() then
        self.escState = self.escState+1
    end
end


function GUIEscapeMenu:MouseClick(pressedParams)

    local wname = pressedParams:GetParameter("WidgetName", true):GetStringData()

    if wname == self.buttonResume:GetName() then
           
        self.selectExitSignal:Emit(self.nullParams)
           
    elseif wname == self.buttonInviteFriends:GetName() then

        -- if GetDemoMode() then
        --     local tempParams = Parameters()
        --     tempParams:GetOrCreateParameter("Key"):SetIntData(GetClientInputManager():GetKeyCode(1, "Escape"))
        --     self:KeyEvent(tempParams)
        --     GetMenuManager():ShowDialogGeneral("Invites are not available in the demo")
        -- else
            GetSteamClientSystem():ShowInviteOverlay()
        -- end

    elseif wname == self.buttonSettings:GetName() then
    
        self:SetVisible(false)
        self.goToSettingsSignal:Emit(self.nullParams)
        
    elseif wname == self.buttonServer:GetName() then
    
        self:SetVisible(false)
        self.goToServerSignal:Emit(self.nullParams)

    --[[elseif wname == self.buttonBrowser:GetName() then

        if GetDemoMode() then
            local tempParams = Parameters()
            tempParams:GetOrCreateParameter("Key"):SetIntData(GetClientInputManager():GetKeyCode(1, "Escape"))
            self:KeyEvent(tempParams)
            GetMenuManager():ShowDialogGeneral("Server browser is not available in the demo")
        else
            self:SetVisible(false)
            self.goToServerBrowserSignal:Emit(self.nullParams)
        end--]]

    elseif wname == self.buttonQuit:GetName() then
    
        GetClientSystem():RequestDisconnect()
    
    end

end

--GUIESCAPEMENU CLASS END