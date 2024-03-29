--GUIMAINMENU CLASS START

class 'GUIMainMenu' (IBase)

function GUIMainMenu:__init() super()

    self.mouseClickSlot = self:CreateSlot("ButtonClick", "ButtonClick")

    self.mainPrefix = "Main_"
 --    if GetDemoMode() then
	--     self.mainGUILayout = GetMyGUISystem():LoadLayout("mainmenu_demo.layout", self.mainPrefix)
	--     self.upsellPrefix = "Upsell_"
	--     self.upsellGUILayout = GetMyGUISystem():LoadLayout("upsell.layout", self.upsellPrefix)
	--     self.upsellGUILayout:SetVisible(false)
	--     self.upsellMainCont = self.upsellGUILayout:GetWidget(self.upsellPrefix .. "cont")
	--     self.buttonUpsellUpgrade = ToButton(self.upsellMainCont:FindWidget(self.upsellPrefix .. "upgrade"))
 --        self.buttonUpsellQuit = ToButton(self.upsellMainCont:FindWidget(self.upsellPrefix .. "quit"))
	--     GetMyGUISystem():RegisterEvent(self.buttonUpsellUpgrade, "eventMouseButtonClick", self.mouseClickSlot)
	--     GetMyGUISystem():RegisterEvent(self.buttonUpsellQuit, "eventMouseButtonClick", self.mouseClickSlot)
	--     self.upsellCaption = self.buttonUpsellUpgrade:GetCaption():AsUTF8()
	--     self.upsellButtonPulseColor1r = 0x9e
	--     self.upsellButtonPulseColor1g = 0xc5
	--     self.upsellButtonPulseColor1b = 0x19
	--     self.upsellButtonPulseColor2r = 0x41
	--     self.upsellButtonPulseColor2g = 0x54
	--     self.upsellButtonPulseColor2b = 0x00
	--     self.upsellPulseCurrPercent = 0
 --        self.upsellPulsePercentChange = 6
	-- else
	    self.mainGUILayout = GetMyGUISystem():LoadLayout("mainmenu.layout", self.mainPrefix)
	-- end
	self.mainCont = self.mainGUILayout:GetWidget(self.mainPrefix .. "cont")
    self.buttonFindGame = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_findgame"))
    self.buttonHostGame = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_hostgame"))
    self.buttonGarage = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_garage"))
    self.buttonSettings = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_settings"))
    self.buttonCredits = ToButton(self.mainGUILayout:GetWidget(self.mainPrefix .. "mm_credits"))
    self.buttonExit = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_exit"))
    self.buttonQuickPlay = ToButton(self.mainCont:FindWidget(self.mainPrefix .. "mm_quickplay"))
    self.version = self.mainGUILayout:GetWidget(self.mainPrefix .. "version")
    self.version:SetCaption(StringToUTFString(GetVersionString()))

    GetMyGUISystem():RegisterEvent(self.buttonFindGame, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonHostGame, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonGarage, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonSettings, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonCredits, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonExit, "eventMouseButtonClick", self.mouseClickSlot)
    GetMyGUISystem():RegisterEvent(self.buttonQuickPlay, "eventMouseButtonClick", self.mouseClickSlot)

    -- if GetDemoMode() then
    --     self.buttonBuyGame = ToButton(self.mainGUILayout:GetWidget(self.mainPrefix .. "upgrade"))
    --     GetMyGUISystem():RegisterEvent(self.buttonBuyGame, "eventMouseButtonClick", self.mouseClickSlot)
    --     self.buttonFindGame:SetCaption(StringToUTFString("#545454" .. self.buttonFindGame:GetCaption():AsUTF8()))
    -- end

	self.connectToServerSignal = self:CreateSignal("ConnectToServer")
	self.goToServerBrowserSignal = self:CreateSignal("GoToServerBrowser")
	self.goToServerSignal = self:CreateSignal("GoToServer")
	self.goToGarageSignal = self:CreateSignal("GoToGarage")
	self.goToSettingsSignal = self:CreateSignal("GoToSettings")
	self.goToHelpSignal = self:CreateSignal("GoToHelp")
	self.goToCreditsSignal = self:CreateSignal("GoToCredits")
	self.quickPlaySignal = self:CreateSignal("QuickPlay")
	
	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	self:InitSoundLevels()
	
end


function GUIMainMenu:BuildInterfaceDefIBase()

	self:AddClassDef("GUIMainMenu", "IBase", "The Main Menu GUI manager")

end


function GUIMainMenu:InitSoundLevels()

    self.effectsVolume = 100
    self.musicVolume = 100

    local paramEffectsVolume = GetSettingTable():GetSetting("EffectsVolume", "Shared", false)

    if IsValid(paramEffectsVolume) then
        self.effectsVolume = paramEffectsVolume:GetStringData()
    else
        paramEffectsVolume = Parameter("EffectsVolume", self.effectsVolume)
        GetSettingTable():AddSetting(paramEffectsVolume, "Shared")
    end
    
    local paramMusicVolume = GetSettingTable():GetSetting("MusicVolume", "Shared", false)
    if IsValid(paramMusicVolume) then
        self.musicVolume = paramMusicVolume:GetStringData()
    else
        paramMusicVolume = Parameter("MusicVolume", self.musicVolume)
        GetSettingTable():AddSetting(paramMusicVolume, "Shared")
    end
    
    GetSoundSystem():SetSFXVolume(tonumber(self.effectsVolume)/100)
    GetSoundSystem():SetMusicVolume(tonumber(self.musicVolume)/100)

end


function GUIMainMenu:InitIBase()

end


function GUIMainMenu:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.mainGUILayout)
	self.mainGUILayout = nil

end


function GUIMainMenu:Process(frameTime)

    if IsValid(self.buttonUpsellUpgrade) and self.buttonUpsellUpgrade:IsVisible() then
        self.upsellPulseCurrPercent = self.upsellPulseCurrPercent + (self.upsellPulsePercentChange * frameTime)
        if self.upsellPulseCurrPercent > 1 then
            self.upsellPulseCurrPercent = 1
            self.upsellPulsePercentChange = -self.upsellPulsePercentChange
        elseif self.upsellPulseCurrPercent < 0 then
            self.upsellPulseCurrPercent = 0
            self.upsellPulsePercentChange = -self.upsellPulsePercentChange
        end
        local colorValueR = Lerp(self.upsellPulseCurrPercent, self.upsellButtonPulseColor1r, self.upsellButtonPulseColor2r)
        local colorValueG = Lerp(self.upsellPulseCurrPercent, self.upsellButtonPulseColor1g, self.upsellButtonPulseColor2g)
        local colorValueB = Lerp(self.upsellPulseCurrPercent, self.upsellButtonPulseColor1b, self.upsellButtonPulseColor2b)
        local colorStr = string.format("%2x%2x%2x", colorValueR, colorValueG, colorValueB)
        print(self.upsellPulseCurrPercent .. "   colorStr: " .. colorStr)
        self.buttonUpsellUpgrade:SetCaption(StringToUTFString("#" .. colorStr .. self.upsellCaption))
    end

end


function GUIMainMenu:SetVisible(visible)

    print("SetVisible(" .. tostring(visible) .. ")")
    self.mainGUILayout:SetVisible(visible)

end


function GUIMainMenu:GetVisible()

    return self.mainGUILayout:GetVisible()

end


function GUIMainMenu:ConnectToServer()

	self.connectToServerSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToServerBrowser()

	self.goToServerBrowserSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToServer()

    print("GoToServer")
	self.goToServerSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToGarage()

	self.goToGarageSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToSettings()

	self.goToSettingsSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToHelp()

	self.goToHelpSignal:Emit(self.nullParams)

end


function GUIMainMenu:GoToCredits()

	self.goToCreditsSignal:Emit(self.nullParams)

end


function GUIMainMenu:QuickPlay()

    self.quickPlaySignal:Emit(self.nullParams)

end


function GUIMainMenu:ButtonClick(buttonParams)

	local wname = buttonParams:GetParameter("WidgetName", true):GetStringData()

	if wname == self.buttonGarage:GetName() then
		self:GoToGarage()
	elseif wname == self.buttonFindGame:GetName() then
	    -- if GetDemoMode() then
	        -- GetMenuManager():ShowDialogGeneral("Multiplayer is not available in the demo")
	    -- else
		    self:GoToServerBrowser()
		-- end
    elseif wname == self.buttonHostGame:GetName() then
		self:GoToServer()
    elseif wname == self.buttonSettings:GetName() then
		self:GoToSettings()
    elseif wname == self.buttonCredits:GetName() then
		self:GoToCredits()
    elseif wname == self.buttonQuickPlay:GetName() then
		self:QuickPlay()
	elseif wname == self.buttonExit:GetName() then
	    -- if GetDemoMode() then
	        -- self.upsellGUILayout:SetVisible(true)
	    -- else
		    GetOGRESystem():Exit()
		-- end
    -- elseif GetDemoMode() and wname == self.buttonBuyGame:GetName() then
    --     GetSteamClientSystem():ShowStoreOverlay()
    -- elseif GetDemoMode() and wname == self.buttonUpsellUpgrade:GetName() then
    --     GetSteamClientSystem():ShowStoreOverlay()
    -- elseif GetDemoMode() and wname == self.buttonUpsellQuit:GetName() then
    --     GetOGRESystem():Exit()
	end

end


--GUIMAINMENU CLASS END