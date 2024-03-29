--GUISETTINGS CLASS START

class 'GUISettings' (IBase)

function GUISettings:__init() super()

	--Needed for the bug that causes a mouse up event to trigger off after
	--the X is pressed in the window that then takes input away from the game
	self.mouseReleasedSlot = self:CreateSlot("MouseReleased", "MouseReleased")
	GetInputSystem():GetSignal("MouseReleased", true):Connect(self.mouseReleasedSlot)

	--Signals
	self.selectExitSignal = self:CreateSignal("ExitSettings")
	self.showDialogRequireRestartSignal = self:CreateSignal("ShowDialogRequireRestart")
	self.mouseClickSlot = self:CreateSlot("MouseClick", "MouseClick")
	self.controlMouseClickSlot = self:CreateSlot("ControlMouseClick", "ControlMouseClick")
	self.bindKeyEventSlot = self:CreateSlot("BindKeyEvent", "BindKeyEvent")
	self.bindAxisEventSlot = self:CreateSlot("BindAxisEvent", "BindAxisEvent")

	self.settingsPrefix = "Settings_"
	self.settingsGUILayout = GetMyGUISystem():LoadLayout("settings.layout", self.settingsPrefix)
	self.settingsCont = self.settingsGUILayout:GetWidget(self.settingsPrefix .. "settings")

	--self.buttonCancel = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "cancel"))
	--GetMyGUISystem():RegisterEvent(self.buttonCancel, "eventMouseButtonClick", self.mouseClickSlot)

	self.buttonApply = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "applysettings"))
	GetMyGUISystem():RegisterEvent(self.buttonApply, "eventMouseButtonClick", self.mouseClickSlot)

	--Listen for close button
	GetMyGUISystem():RegisterEvent(self.settingsCont, "eventWindowButtonPressed", self.mouseClickSlot)

	--Multiplayer tab
	self.multiplayer_playerName = ToEdit(self.settingsCont:FindWidget(self.settingsPrefix .. "playername"))

	--Sound tab
	self.sound_effectsVolume = ToHScroll(self.settingsCont:FindWidget(self.settingsPrefix .. "effectsVolume"))
	self.sound_musicVolume = ToHScroll(self.settingsCont:FindWidget(self.settingsPrefix .. "musicVolume"))

	--Controls tab
	self:InitControlsTab()

	--Graphics tab
	self.gfx_antiAliasing = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "antialiasing"))
	self.gfx_fullscreen = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "fullscreen"))
	self.gfx_renderingDevice = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "renderingdevice"))
	self.gfx_vsync = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "vsync"))
	self.gfx_resolution = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "resolution"))
	self.gfx_srgb = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "srgb"))
	self.gfx_textureFilter = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "texturefilter"))
	self.gfx_shadows = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "shadows"))
	self.gfx_textures = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "textures"))
	self.gfx_shaders = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "shaders"))
	--self.gfx_motionblur = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "motionblur"))
	self.gfx_fov = ToHScroll(self.settingsCont:FindWidget(self.settingsPrefix .. "fov"))
	--self.gfx_screenblur = ToComboBox(self.settingsCont:FindWidget(self.settingsPrefix .. "screenblur"))

	self.gfx_fov:SetScrollRange(60)

	local paramFOV = GetSettingTable():GetSetting("FOV", "Shared", false)
	if IsValid(paramFOV) then
		self.gfx_fov:SetScrollPosition(tonumber(paramFOV:GetStringData()))
	else
		paramFOV = Parameter("FOV", 30)
		GetSettingTable():AddSetting(paramFOV, "Shared")
	end

	self.gfx_fov:SetMoveToClick(true)
	--This will notify us when the slider changes
	self.fovSliderSlot = self:CreateSlot("FovSliderSlot", "FovSliderSlot")
	GetMyGUISystem():RegisterEvent(self.gfx_fov, "eventScrollChangePosition", self.fovSliderSlot)

	--Listen for escape key
	self.params = Parameters()
	self.keyEventSlot = self:CreateSlot("KeyEvent", "KeyEvent")
	GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.keyEventSlot)

	--These params will be used for multiple signals that do not emit any parameters
	self.nullParams = Parameters()

	--Default Values
	self.playerName = "Player" .. tostring(GenerateID())
	self.effectsVolume = "100"
	self.musicVolume = "100"
	self.mouseSensitivity = "25"

	self.requireRestart = false

end


function GUISettings:BuildInterfaceDefIBase()

	self:AddClassDef("GUISettings", "IBase", "The Settings Menu GUI manager")

end


function GUISettings:InitIBase()

end


function GUISettings:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.settingsGUILayout)
	self.settingsGUILayout = nil

end


function GUISettings:InitControlsTab()

	self.bindingButton = nil
	self.previousBinding = nil
	self.controlButtons = {}
	--Bound name, { GUI button 1, GUI button 2 }, { Default key 1, Default key 2 }
	table.insert(self.controlButtons, { "ControlBoost", { nil, nil }, { "LSHIFT", "JS_4" } } )
	table.insert(self.controlButtons, { "UseItemUp", { nil, nil }, { "MB_LEFT", "JS_0" } } )
	table.insert(self.controlButtons, { "UseItemDown", { nil, nil }, { "Q", "JS_2" } } )
	table.insert(self.controlButtons, { "Hop", { nil, nil }, { "SPACE", "JS_3" } } )
	table.insert(self.controlButtons, { "ControlReset", { nil, nil }, { "R", "JS_7" } } )
	table.insert(self.controlButtons, { "ControlAccel", { nil, nil }, { "W", "JS_AX4N" } } )
	table.insert(self.controlButtons, { "ControlReverse", { nil, nil }, { "S", "JS_AX4P" } } )
	table.insert(self.controlButtons, { "ControlRight", { nil, nil }, { "D", "JS_AX1P" } } )
	table.insert(self.controlButtons, { "ControlLeft", { nil, nil }, { "A", "JS_AX1N" } } )
	table.insert(self.controlButtons, { "ControlMouseLook", { nil, nil }, { "MB_RIGHT", "JS_5" } } )
	table.insert(self.controlButtons, { "ShowPlayers", { nil, nil }, { "TAB", "JS_6" } } )
	table.insert(self.controlButtons, { "AllChat", { nil, nil }, { "Y", "Y" } } )
	table.insert(self.controlButtons, { "Escape", { nil, nil }, { "ESC", "ESC" } } )
	table.insert(self.controlButtons, { "ControlCameraLeft", { nil, nil }, { "JS_AX3N", "JS_AX3N" } } )
	table.insert(self.controlButtons, { "ControlCameraRight", { nil, nil }, { "JS_AX3P", "JS_AX3P" } } )
	table.insert(self.controlButtons, { "ControlCameraUp", { nil, nil }, { "JS_AX2N", "JS_AX2N" } } )
	table.insert(self.controlButtons, { "ControlCameraDown", { nil, nil }, { "JS_AX2P", "JS_AX2P" } } )

	for index, buttonDefTable in pairs(self.controlButtons) do
		--First binding
		local inputGUIButton = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "Input" .. buttonDefTable[1]))
		GetMyGUISystem():RegisterEvent(inputGUIButton, "eventMouseButtonClick", self.controlMouseClickSlot)
		buttonDefTable[2][1] = inputGUIButton
		--Second binding
		local inputGUIButton2 = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "Input" .. buttonDefTable[1] .. "2"))
		if IsValid(inputGUIButton2) then
			GetMyGUISystem():RegisterEvent(inputGUIButton2, "eventMouseButtonClick", self.controlMouseClickSlot)
			buttonDefTable[2][2] = inputGUIButton2
		end
	end

	self.controls_mouseSensitivity = ToHScroll(self.settingsCont:FindWidget(self.settingsPrefix .. "mouseslider"))

	self.mouseLookCheck = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "mouselook"))
	GetMyGUISystem():RegisterEvent(self.mouseLookCheck, "eventMouseButtonClick", self.mouseClickSlot)

	self.gamePadMouseLookCheck = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "gamepadmouselook"))
	GetMyGUISystem():RegisterEvent(self.gamePadMouseLookCheck, "eventMouseButtonClick", self.mouseClickSlot)

	self.defaultControls = ToButton(self.settingsCont:FindWidget(self.settingsPrefix .. "DefaultControls"))
	GetMyGUISystem():RegisterEvent(self.defaultControls, "eventMouseButtonClick", self.mouseClickSlot)

end


function GUISettings:SetVisible(visible)

	if (visible and not self.settingsGUILayout:GetVisible()) then
		self:SetStrings()
	end
	self.settingsGUILayout:SetVisible(visible)

end


function GUISettings:GetVisible()

	return self.settingsGUILayout:GetVisible()

end


function GUISettings:SetStrings()

	self:SetupTabGraphics()
	self:SetupTabSound()
	self:SetupTabControls()
	self:SetupTabMultiplayer()

end


function GUISettings:MouseClick(pressedParams)

	local wname = pressedParams:GetParameter("WidgetName", true):GetStringData()

	if wname == self.settingsCont:GetName() then
		self.selectExitSignal:Emit(self.nullParams)
		self.exitClicked = true
	elseif wname == self.buttonApply:GetName() then
		self:Apply()
		self.selectExitSignal:Emit(self.params)
	elseif wname == self.defaultControls:GetName() then
		self:DefaultControlsTab()
	elseif wname == self.mouseLookCheck:GetName() then
		self.mouseLookCheck:SetButtonPressed(not self.mouseLookCheck:GetButtonPressed())
	elseif wname == self.gamePadMouseLookCheck:GetName() then
		self.gamePadMouseLookCheck:SetButtonPressed(not self.gamePadMouseLookCheck:GetButtonPressed())
	end

end


function GUISettings:MouseReleased(params)

	if self.exitClicked == true then
		self.exitClicked = false
		GetMyGUISystem():GetInputManager():ResetKeyFocusWidget()
		GetMyGUISystem():GetInputManager():ResetMouseFocusWidget()
	end

end


function GUISettings:SetupTabGraphics()

	--!!! Decision on defaults !!!
	--AA is default to off, full screen true, vsync off and native res, current defaults on the rest

	--RESOLUTION
	local currResStr = GetOGRESystem():GetResolution()
	local selIndex = 0
	self.gfx_resolution:RemoveAllItems()
	local supportedResParams = GetOGRESystem():GetSupportedResolutions()
	local numResolutions = supportedResParams:GetNumberOfParameters()
	local currResolution = 0
	while currResolution < numResolutions do
		local resStr = supportedResParams:GetParameter(currResolution, true):GetStringData()
		self.gfx_resolution:AddItem(StringToUTFString(resStr), MyGUIAny())
		if resStr == currResStr then
			selIndex = currResolution
		end
		currResolution = currResolution + 1
	end
	self.gfx_resolution:SetIndexSelected(selIndex)

	--FULLSCREEN MODE
	local fullscreenEnabled = GetOGRESystem():GetFullscreenEnabled()
	--Should be 2 options, Yes or No
	local guiSelectedFullscreen = self.gfx_fullscreen:GetItemNameAt(0):AsUTF8()
	local fsSelIndex = 0
	if not fullscreenEnabled and guiSelectedFullscreen == "Yes" then
		fsSelIndex = 1
	end
	self.gfx_fullscreen:SetIndexSelected(fsSelIndex)

	--SHADOWS ENABLED
	local shadowsEnabled = GetOGRESystem():GetShadowsEnabled()
	--Should be 2 options, Yes or No
	local guiSelectedShadow = self.gfx_shadows:GetItemNameAt(0):AsUTF8()
	local shSelIndex = 0
	if not shadowsEnabled and guiSelectedShadow == "Yes" then
		shSelIndex = 1
	end
	self.gfx_shadows:SetIndexSelected(shSelIndex)

	--SCREEN BLUR
	--[[local paramSBE = GetSettingTable():GetSetting("ScreenBlurAllowed", "System", false)
	if IsValid(paramSBE) then
		GetClientManager():SetScreenBlurAllowed(paramSBE:GetBoolData())
	end
	local screenBlurAllowed = GetClientManager():GetScreenBlurAllowed()
	--Should be 2 options, On or Off
	local guiSelectedBlur = self.gfx_screenblur:GetItemNameAt(0):AsUTF8()
	local blSelIndex = 0
	if not screenBlurAllowed and guiSelectedBlur == "On" then
		blSelIndex = 1
	end
	self.gfx_screenblur:SetIndexSelected(blSelIndex)--]]

	--RENDERING DEVICE
	--[[local currRenderDevice = GetOGRESystem():GetRenderingDevice()
	local selRDIndex = 0
	self.gfx_renderingDevice:RemoveAllItems()
	local supportedRDParams = GetOGRESystem():GetSupportedRenderingDevices()
	local numRD = supportedRDParams:GetNumberOfParameters()
	local currRD = 0
	while currRD < numRD do
		local rdStr = supportedRDParams:GetParameter(currRD, true):GetStringData()
		self.gfx_renderingDevice:AddItem(StringToUTFString(rdStr), MyGUIAny())
		if rdStr == currRenderDevice then
			selRDIndex = currRD
		end
		currRD = currRD + 1
	end
	self.gfx_renderingDevice:SetIndexSelected(selRDIndex)--]]

	--TEXTURE FILTER
	self.gfx_textureFilter:RemoveAllItems()
	self.gfx_textureFilter:AddItem(StringToUTFString("BILINEAR"), MyGUIAny())
	self.gfx_textureFilter:AddItem(StringToUTFString("TRILINEAR"), MyGUIAny())
	self.gfx_textureFilter:AddItem(StringToUTFString("ANISOTROPIC"), MyGUIAny())
	if GetTextureFiltering() == OGREUtil.BILINEAR then
		self.gfx_textureFilter:SetIndexSelected(0)
	elseif GetTextureFiltering() == OGREUtil.TRILINEAR then
		self.gfx_textureFilter:SetIndexSelected(1)
	elseif GetTextureFiltering() == OGREUtil.ANISOTROPIC then
		self.gfx_textureFilter:SetIndexSelected(2)
	end

	--VSYNC
	self.gfx_vsync:RemoveAllItems()
	self.gfx_vsync:AddItem(StringToUTFString("On"), MyGUIAny())
	self.gfx_vsync:AddItem(StringToUTFString("Off"), MyGUIAny())
	local vsyncEnabled = GetOGRESystem():GetVSyncEnabled()
	if vsyncEnabled then
		self.gfx_vsync:SetIndexSelected(0)
	else
		self.gfx_vsync:SetIndexSelected(1)
	end

	--ANTI-ALIASING
	local currAAMode = GetOGRESystem():GetAAMode()
	local selAAIndex = 0
	self.gfx_antiAliasing:RemoveAllItems()
	local supportedAAParams = GetOGRESystem():GetSupportedAAModes()
	local numAA = supportedAAParams:GetNumberOfParameters()
	local currAA = 0
	while currAA < numAA do
		local aaStr = supportedAAParams:GetParameter(currAA, true):GetStringData()
		self.gfx_antiAliasing:AddItem(StringToUTFString(aaStr), MyGUIAny())
		if aaStr == currAAMode then
			selAAIndex = currAA
		end
		currAA = currAA + 1
	end
	self.gfx_antiAliasing:SetIndexSelected(selAAIndex)
end


function GUISettings:SetupTabSound()
	
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
	
	--GetSoundSystem():SetSFXVolume(tonumber(self.effectsVolume)/100)
	--GetSoundSystem():SetMusicVolume(tonumber(self.musicVolume)/100)
	
	self.sound_effectsVolume:SetScrollPosition(tonumber(self.effectsVolume))
	self.sound_musicVolume:SetScrollPosition(tonumber(self.musicVolume))
	
end


function GUISettings:SetupTabControls()

	for index, buttonDefTable in pairs(self.controlButtons) do
		buttonDefTable[2][1]:SetCaption(StringToUTFString(self:ConvertKeyCodeToString(1, buttonDefTable[1])))
		if IsValid(buttonDefTable[2][2]) then
			buttonDefTable[2][2]:SetCaption(StringToUTFString(self:ConvertKeyCodeToString(2, buttonDefTable[1])))
		end
	end

	local paramMouseSensitivity = GetSettingTable():GetSetting("MouseSensitivity", "Shared", false)
	if IsValid(paramMouseSensitivity) then
		self.mouseSensitivity = paramMouseSensitivity:GetStringData()
	else
		paramMouseSensitivity = Parameter("MouseSensitivity", self.mouseSensitivity)
		GetSettingTable():AddSetting(paramMouseSensitivity, "Shared")
	end
	self.controls_mouseSensitivity:SetScrollPosition(tonumber(self.mouseSensitivity))

	local paramMouseLook = GetSettingTable():GetSetting("AutoMouseLook", "Shared", false)
	if IsValid(paramMouseLook) then
		local autoMouseLook = paramMouseLook:GetStringData() == "true"
		self.mouseLookCheck:SetButtonPressed(autoMouseLook)
	else
		paramMouseLook = Parameter("AutoMouseLook", self.mouseLookCheck:GetButtonPressed())
		GetSettingTable():AddSetting(paramMouseLook, "Shared")
	end

	local paramGamePadMouseLook = GetSettingTable():GetSetting("GamePadMouseLook", "Shared", false)
	if IsValid(paramGamePadMouseLook) then
		local gpMouseLook = paramGamePadMouseLook:GetStringData() == "true"
		self.gamePadMouseLookCheck:SetButtonPressed(gpMouseLook)
	else
		paramGamePadMouseLook = Parameter("GamePadMouseLook", self.gamePadMouseLookCheck:GetButtonPressed())
		GetSettingTable():AddSetting(paramGamePadMouseLook, "Shared")
	end

end


function GUISettings:SetupTabMultiplayer()
	
	--get player name from settings table
	local paramPlayerName = GetSettingTable():GetSetting("PlayerName", "Shared", false)

	--if valid name found in settings, use it, otherwise add the default name to settings table
	if IsValid(paramPlayerName) then
		self.playerName = paramPlayerName:GetStringData()
	else
		-- initilize playerName to steam name if availible
		if IsValid(GetSteamClientSystem) then
			self.playerName = GetSteamClientSystem():GetLocalPlayerName()
			
			if string.len(self.playerName) == 0 then
				self.playerName = "Player" .. tostring(GenerateID())
			end
		end
		
		paramPlayerName = Parameter("PlayerName", self.playerName)
		GetSettingTable():AddSetting(paramPlayerName, "Shared")
	end 
	
	-- set name in GUI
	self.multiplayer_playerName:SetOnlyText(StringToUTFString(self.playerName))
 
end


function GUISettings:ControlMouseClick(pressedParams)

	if self.pressState == 0 or self.pressState == 1 then
		return
	end

	local wname = pressedParams:GetParameter("WidgetName", true):GetStringData()
	local cButton = ToButton(self.settingsCont:FindWidget(wname))

	self.previousBinding = cButton:GetCaption():AsUTF8()
	cButton:SetCaption(StringToUTFString("") )
	cButton:SetButtonPressed(true)
	self.bindingButton = cButton
	GetClientInputManager():GetSignal("KeyReleasedIgnoreFocus", true):Connect(self.bindKeyEventSlot)
	GetClientInputManager():GetSignal("AxisMovedIgnoreFocus", true):Connect(self.bindAxisEventSlot)
	self.pressState = 0

end


function GUISettings:FovSliderSlot(sliderParams)
	local sliderPos = sliderParams:GetParameter("Index", true):GetIntData()
	paramFOV = Parameter("FOV", sliderPos)
	GetSettingTable():AddSetting(paramFOV, "Shared")

	-- GetOGRESystem():SetCompositorEnabled("Tiling", (sliderPos > 0))
	-- GetOGRESystem():SetCompositorSetting("Tiling", "NumTiles", ((100 - sliderPos) * 2))
	-- GetOGRESystem():SetCompositorSetting("Tiling", "Threshhold", 0)
	
	-- if sliderPos > 0 then
	--     GetClientManager().indieSlider = true
	-- end

end


function GUISettings:BindKeyEvent(keyParams)

	if self.pressState == 0 then
		self.pressState = 1
		return
	end

	if IsValid(self.bindingButton) then
		local key = keyParams:GetParameter("Key", true):GetIntData()
		local keyStr = KeyCodeToString(key)
		if keyStr == " " then
			keyStr = "SPACE"
		end
		self.bindingButton:SetCaption(StringToUTFString(keyStr) )
		self.bindingButton:SetButtonPressed(false)

		self.bindingButton = nil
	end

	self.bindKeyEventSlot:DisconnectAll()
	self.bindAxisEventSlot:DisconnectAll()

	self.pressState = 2

end


function GUISettings:BindAxisEvent(axisParams)

	local axisID = axisParams:GetParameter("Axis", true):GetIntData()
	local position = axisParams:GetParameter("Position", true):GetFloatData()
	local passedThres = math.abs(position) > 0.25
	if IsValid(self.bindingButton) and passedThres then
		local axisIDStr = KeyCodeToString(axisID)
		self.bindingButton:SetCaption(StringToUTFString(axisIDStr) )
		self.bindingButton:SetButtonPressed(false)

		self.bindingButton = nil
	end

	if passedThres then
		self.bindKeyEventSlot:DisconnectAll()
		self.bindAxisEventSlot:DisconnectAll()

		self.pressState = 2
	end

end


function GUISettings:KeyEvent(keyParams)

	local key = keyParams:GetParameter("Key", true):GetIntData()
	if (self.pressState == 2 or self.pressState == nil) and self:GetVisible() and GetClientInputManager():GetKeyCodeMatches(key, "Escape") then
		self.selectExitSignal:Emit(self.params)
	end

end


function GUISettings:ConvertKeyCodeToString(whichBinding, key)

	 local keyCode = KeyCodeToString(GetClientInputManager():GetKeyCode(whichBinding, key))

	 if keyCode == " " then
		keyCode = "SPACE"
	 end

	 return keyCode

end


function GUISettings:SaveMultiplayerTab()

	--Player Name
	local paramPlayerName = GetSettingTable():GetSetting("PlayerName", "Shared", true)
	local pname = self.multiplayer_playerName:GetOnlyText():AsUTF8()
	pname = string.gsub(pname, "#", "")

	if string.len(pname) > 0 then
		paramPlayerName:SetStringData(pname)
	else
		-- invalid player name, display old name since didn't save new name.
		self.multiplayer_playerName:AddText(StringToUTFString(paramPlayerName:GetStringData()))
	end
	GetClientManager():InitPlayerName()

end


function GUISettings:SaveSoundTab()

	local paramVolume = GetSettingTable():GetSetting("EffectsVolume", "Shared", true)
	paramVolume:SetStringData(tostring(self.sound_effectsVolume:GetScrollPosition()))

	paramVolume = GetSettingTable():GetSetting("MusicVolume", "Shared", true)
	paramVolume:SetStringData(tostring(self.sound_musicVolume:GetScrollPosition()))

	GetSoundSystem():SetSFXVolume(self.sound_effectsVolume:GetScrollPosition()/100)
	GetSoundSystem():SetMusicVolume(self.sound_musicVolume:GetScrollPosition()/100)

end


function GUISettings:SaveControlsTab()

	for index, buttonDefTable in pairs(self.controlButtons) do
		local keyStr1 = StringToKeyCode(buttonDefTable[2][1]:GetCaption():AsUTF8())
		local keyStr2 = keyStr1
		if IsValid(buttonDefTable[2][2]) then
			keyStr2 = StringToKeyCode(buttonDefTable[2][2]:GetCaption():AsUTF8())
		end
		GetClientInputManager():SetKeyCode(buttonDefTable[1], keyStr1, keyStr2)
	end

	GetClientInputManager():SaveCurrentMapping()

	local paramMouseSensitivity = GetSettingTable():GetSetting("MouseSensitivity", "Shared", false)
	if IsValid(paramMouseSensitivity) then
		paramMouseSensitivity:SetStringData(tostring(self.controls_mouseSensitivity:GetScrollPosition()))
		GetClientInputManager().mouseSensitivity = self.controls_mouseSensitivity:GetScrollPosition()
	end

	local paramMouseLook = GetSettingTable():GetSetting("AutoMouseLook", "Shared", false)
	if IsValid(paramMouseLook) then
		paramMouseLook:SetStringData(tostring(self.mouseLookCheck:GetButtonPressed()))
		GetClientInputManager().autoMouseLook = self.mouseLookCheck:GetButtonPressed()
	end

	local paramGamePadMouseLook = GetSettingTable():GetSetting("GamePadMouseLook", "Shared", false)
	if IsValid(paramGamePadMouseLook) then
		paramGamePadMouseLook:SetStringData(tostring(self.gamePadMouseLookCheck:GetButtonPressed()))
		GetClientInputManager().gamePadMouseLook = self.gamePadMouseLookCheck:GetButtonPressed()
	end

	--Assign the new key mapping to the network world after updating the mapping in the ClientInputManager
	AssignInputMapping(GetClientWorld())

end


function GUISettings:DefaultControlsTab()

	for index, buttonDefTable in pairs(self.controlButtons) do
		buttonDefTable[2][1]:SetCaption(StringToUTFString(buttonDefTable[3][1]))
		if IsValid(buttonDefTable[2][2]) then
			buttonDefTable[2][2]:SetCaption(StringToUTFString(buttonDefTable[3][2]))
		end
	end

	self.controls_mouseSensitivity:SetScrollPosition(25)
	self.mouseLookCheck:SetButtonPressed(true)

end

function GUISettings:SaveGraphicsTab()

	--[[ Save graphics options --
	self.gfx_renderingDevice
	self.gfx_vsync
	self.gfx_srgb
	self.gfx_textures
	self.gfx_shaders
	self.gfx_motionblur
	self.gfx_fov
	--]]

	--RESOLUTION
	local guiSelectedRes = self.gfx_resolution:GetItemNameAt(self.gfx_resolution:GetIndexSelected()):AsUTF8()
	if GetOGRESystem():GetResolution() ~= guiSelectedRes then
		--GetOGRESystem():SetResolution(guiSelectedRes)
		--Save new setting to table
		local paramRes = GetSettingTable():GetSetting("Resolution", "System", false)
		if IsValid(paramRes) then
			paramRes:SetStringData(guiSelectedRes)
		else
			GetSettingTable():AddSetting(Parameter("Resolution", guiSelectedRes), "System")
		end
	end

	--FULLSCREEN MODE
	local fsSelected = self.gfx_fullscreen:GetItemNameAt(self.gfx_fullscreen:GetIndexSelected()):AsUTF8()
	local fsGUIEnabled = (fsSelected == "Yes")
	if GetOGRESystem():GetFullscreenEnabled() ~= fsGUIEnabled then
		--GetOGRESystem():SetFullscreenEnabled(fsGUIEnabled)
		--Save new setting to table
		local paramFS = GetSettingTable():GetSetting("Fullscreen", "System", false)
		if IsValid(paramFS) then
			paramFS:SetBoolData(fsGUIEnabled)
		else
			GetSettingTable():AddSetting(Parameter("Fullscreen", fsGUIEnabled), "System")
		end
	end
	
	--SHADOWS ENABLED
	local shSelected = self.gfx_shadows:GetItemNameAt(self.gfx_shadows:GetIndexSelected()):AsUTF8()
	local shGUIEnabled = (shSelected == "Yes")
	if GetOGRESystem():GetShadowsEnabled() ~= shGUIEnabled then
		GetOGRESystem():SetShadowsEnabled(shGUIEnabled)
		--Save new setting to table
		local paramSH = GetSettingTable():GetSetting("Shadows", "System", false)
		if IsValid(paramSH) then
			paramSH:SetBoolData(shGUIEnabled)
		else
			GetSettingTable():AddSetting(Parameter("Shadows", shGUIEnabled), "System")
		end
	end

	--SCREEN BLUR
	--[[local sbeSelected = self.gfx_screenblur:GetItemNameAt(self.gfx_screenblur:GetIndexSelected()):AsUTF8()
	local sbeGUIEnabled = (sbeSelected == "On")
	if GetClientManager():GetScreenBlurAllowed() ~= sbeGUIEnabled then
		GetClientManager():SetScreenBlurAllowed(sbeGUIEnabled)
		--Save new setting to table
		local paramSBE = GetSettingTable():GetSetting("ScreenBlurAllowed", "System", false)
		if IsValid(paramSBE) then
			paramSBE:SetBoolData(sbeGUIEnabled)
		else
			GetSettingTable():AddSetting(Parameter("ScreenBlurAllowed", sbeGUIEnabled), "System")
		end
	end--]]

	--TEXTURE FILTER
	local tfSelected = self.gfx_textureFilter:GetItemNameAt(self.gfx_textureFilter:GetIndexSelected()):AsUTF8()
	if tfSelected == "BILINEAR" then
		SetTextureFiltering(OGREUtil.BILINEAR, 1)
	elseif tfSelected == "TRILINEAR" then
		SetTextureFiltering(OGREUtil.TRILINEAR, 1)
	elseif tfSelected == "ANISOTROPIC" then
		SetTextureFiltering(OGREUtil.ANISOTROPIC, 8)
	end
	--Save new setting to table
	local paramTF = GetSettingTable():GetSetting("TextureFilterMode", "System", false)
	if IsValid(paramTF) then
		paramTF:SetStringData(tfSelected)
	else
		GetSettingTable():AddSetting(Parameter("TextureFilterMode", tfSelected), "System")
	end

	--VSYNC
	local vsSelected = self.gfx_vsync:GetItemNameAt(self.gfx_vsync:GetIndexSelected()):AsUTF8()
	local vsGUIEnabled = (vsSelected == "On")
	if GetOGRESystem():GetVSyncEnabled() ~= vsGUIEnabled then
		GetOGRESystem():SetVSyncEnabled(vsGUIEnabled)
		--Save new setting to table
		local paramVS = GetSettingTable():GetSetting("VSync", "System", false)
		if IsValid(paramVS) then
			paramVS:SetBoolData(vsGUIEnabled)
		else
			GetSettingTable():AddSetting(Parameter("VSync", vsGUIEnabled), "System")
		end
	end

	--ANTI-ALIASING
	local aaSelected = self.gfx_antiAliasing:GetItemNameAt(self.gfx_antiAliasing:GetIndexSelected()):AsUTF8()
	if GetOGRESystem():GetAAMode() ~= aaSelected then
		GetOGRESystem():SetAAMode(aaSelected)
		--Save new setting to table
		local paramAA = GetSettingTable():GetSetting("AAMode", "System", false)
		if IsValid(paramAA) then
			paramAA:SetStringData(GetOGRESystem():GetAAMode())
		else
			GetSettingTable():AddSetting(Parameter("AAMode", GetOGRESystem():GetAAMode()), "System")
		end
	end

end


--Called when the left button is pushed, this will apply the changed settings.
function GUISettings:Apply()

	self:SaveMultiplayerTab()
	self:SaveSoundTab()
	self:SaveControlsTab()
	self:SaveGraphicsTab()

	--[[
	if self.requireRestart then
		self.showDialogRequireRestartSignal:Emit(self.nullParams)
	end
	--]]
end

--GUISETTINGS CLASS END