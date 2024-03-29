UseModule("IBase", "Scripts/")

--CLIENTINPUTMANAGER CLASS START

--The ClientInputManager is an input filter
class 'ClientInputManager' (IBase)

function ClientInputManager:__init() super()

	--Slots to receive input
	self.keyPressedSlot = self:CreateSlot("KeyPressed", "KeyPressed")
	GetInputSystem():GetSignal("KeyPressed", true):Connect(self.keyPressedSlot)
	self.keyReleasedSlot = self:CreateSlot("KeyReleased", "KeyReleased")
	GetInputSystem():GetSignal("KeyReleased", true):Connect(self.keyReleasedSlot)
	self.mousePressedSlot = self:CreateSlot("MousePressed", "MousePressed")
	GetInputSystem():GetSignal("MousePressed", true):Connect(self.mousePressedSlot)
	self.mouseReleasedSlot = self:CreateSlot("MouseReleased", "MouseReleased")
	GetInputSystem():GetSignal("MouseReleased", true):Connect(self.mouseReleasedSlot)
	self.mouseMovedSlot = self:CreateSlot("MouseMoved", "MouseMoved")
	GetInputSystem():GetSignal("MouseMoved", true):Connect(self.mouseMovedSlot)
	self.axisMovedSlot = self:CreateSlot("AxisMoved", "AxisMoved")
	GetInputSystem():GetSignal("AxisMoved", true):Connect(self.axisMovedSlot)

	--Signals to forward input
	self.keyPressedSignal = self:CreateSignal("KeyPressed")
	self.keyPressedIgnoreFocusSignal = self:CreateSignal("KeyPressedIgnoreFocus")
	self.keyReleasedIgnoreFocusSignal = self:CreateSignal("KeyReleasedIgnoreFocus")
	self.keyReleasedSignal = self:CreateSignal("KeyReleased")
	self.mousePressedSignal = self:CreateSignal("MousePressed")
	self.mouseReleasedSignal = self:CreateSignal("MouseReleased")
	self.mouseMovedSignal = self:CreateSignal("MouseMoved")
	self.axisMovedSignal = self:CreateSignal("AxisMoved")
	self.axisMovedIgnoreFocus = self:CreateSignal("AxisMovedIgnoreFocus")

	self:InitKeyMapping()

	self.forceAllowInput = false

end


function ClientInputManager:BuildInterfaceDefIBase()

	self:AddClassDef("ClientInputManager", "IBase", "Manages input for the client in script")

end


function ClientInputManager:InitIBase()

end


function ClientInputManager:UnInitIBase()

end


--BRIAN TODO: Is this still needed with the new NetworkedWorld input system?
function ClientInputManager:InitKeyMapping()

    self.defaultKeyMap = { }
    self.defaultKeyMap["ControlBoost"] = { "LSHIFT", "JS_4" }
    self.defaultKeyMap["UseItemUp"] = { "MB_LEFT", "JS_0" }
    self.defaultKeyMap["UseItemDown"] = { "Q", "JS_2" }
    self.defaultKeyMap["Hop"] = { "SPACE", "JS_3" }
    self.defaultKeyMap["ControlReset"] = { "R", "JS_7" }
    self.defaultKeyMap["ControlAccel"] = { "W", "JS_AX4N" }
    self.defaultKeyMap["ControlReverse"] = { "S", "JS_AX4P" }
    self.defaultKeyMap["ControlRight"] = { "D", "JS_AX1P" }
    self.defaultKeyMap["ControlLeft"] = { "A", "JS_AX1N" }
    self.defaultKeyMap["ControlMouseLook"] = { "MB_RIGHT", "JS_5" }
    self.defaultKeyMap["ShowPlayers"] = { "TAB", "JS_6" }
    self.defaultKeyMap["AllChat"] = { "Y", "Y" }
    self.defaultKeyMap["Escape"] = { "ESC", "ESC" }
    self.defaultKeyMap["ControlCameraLeft"] = { "JS_AX3N", "JS_AX3N" }
    self.defaultKeyMap["ControlCameraRight"] = { "JS_AX3P", "JS_AX3P" }
    self.defaultKeyMap["ControlCameraUp"] = { "JS_AX2N", "JS_AX2N" }
    self.defaultKeyMap["ControlCameraDown"] = { "JS_AX2P", "JS_AX2P" }

	self.keyMap = { }
	for keyName, key in pairs(self.defaultKeyMap) do
	    self.keyMap[keyName] = { StringToKeyCode(key[1]), StringToKeyCode(key[2]) }
	end

	for keyName, key in pairs(self.keyMap) do
	    --First mapping
		local currentKey = GetSettingTable():GetSetting("Input" .. keyName, "Shared", false)
		if IsValid(currentKey) and string.len(currentKey:GetStringData()) > 0 then
			self.keyMap[keyName][1] = StringToKeyCode(currentKey:GetStringData())
		else
			currentKey = Parameter("Input" .. keyName, KeyCodeToString(key[1]))
			GetSettingTable():AddSetting(currentKey, "Shared")
		end
		--Second mapping
		local currentKey2 = GetSettingTable():GetSetting("Input" .. keyName .. "2", "Shared", false)
		if IsValid(currentKey2) and string.len(currentKey2:GetStringData()) > 0 then
			self.keyMap[keyName][2] = StringToKeyCode(currentKey2:GetStringData())
		else
			currentKey2 = Parameter("Input" .. keyName .. "2", KeyCodeToString(key[2]))
			GetSettingTable():AddSetting(currentKey2, "Shared")
		end
	end
	
	local paramMouseSensitivity = GetSettingTable():GetSetting("MouseSensitivity", "Shared", false)
    if IsValid(paramMouseSensitivity) then
        self.mouseSensitivity = tonumber(paramMouseSensitivity:GetStringData())
    else
        self.mouseSensitivity = 25
    end
    
    local paramMouseLook = GetSettingTable():GetSetting("AutoMouseLook", "Shared", false)
    if IsValid(paramMouseLook) then
        self.autoMouseLook = paramMouseLook:GetStringData() == "true"
    else
        self.autoMouseLook = true
    end

    local paramGamePadMouseLook = GetSettingTable():GetSetting("GamePadMouseLook", "Shared", false)
    if IsValid(paramGamePadMouseLook) then
        self.gamePadMouseLook = paramGamePadMouseLook:GetStringData() == "true"
    else
        --Default to off
        self.gamePadMouseLook = false
    end

end


function ClientInputManager:SaveCurrentMapping()

    for keyName, key in pairs(self.keyMap) do
        --First mapping
		local currentKey = GetSettingTable():GetSetting("Input" .. keyName, "Shared", false)
		if IsValid(currentKey) then
		    currentKey:SetStringData(KeyCodeToString(key[1]))
		else
			currentKey = Parameter("Input" .. keyName, KeyCodeToString(key[1]))
			GetSettingTable():AddSetting(currentKey, "Shared")
		end
		--Second mapping
		local currentKey2 = GetSettingTable():GetSetting("Input" .. keyName .. "2", "Shared", false)
		if IsValid(currentKey2) then
		    currentKey2:SetStringData(KeyCodeToString(key[2]))
		else
			currentKey2 = Parameter("Input" .. keyName .. "2", KeyCodeToString(key[2]))
			GetSettingTable():AddSetting(currentKey2, "Shared")
		end
	end

end


function ClientInputManager:SetForceAllowInput(setForce)

    self.forceAllowInput = setForce

end


function ClientInputManager:GetForceAllowInput()

    return self.forceAllowInput

end


function ClientInputManager:SetKeyCode(keyName, keyCode1, keyCode2)

	if IsValid(self.keyMap[keyName]) then
		self.keyMap[keyName][1] = keyCode1
		self.keyMap[keyName][2] = keyCode2
	end

end


function ClientInputManager:GetKeyCode(whichBinding, keyName)

    if IsValid(self.keyMap[keyName]) then
        return self.keyMap[keyName][whichBinding]
    end
    return nil

end


function ClientInputManager:GetKeyCodeMatches(keyCode, keyName)

	if self.keyMap[keyName][1] == keyCode or self.keyMap[keyName][2] == keyCode then
	    return true
	else
	    return false
	end

end


function ClientInputManager:AllowInput()

	--Don't forward this if the GUI has focus
	if (not self.forceAllowInput) and
       (GetConsole():GetEnabled() or
       GetMyGUISystem():GetInputManager():IsFocusMouse() or
       GetMyGUISystem():GetInputManager():IsFocusKey()) then
		return false
	end
	return true

end


function ClientInputManager:KeyPressed(keyParams)

	if self:AllowInput() then
		--Forward it along
		self.keyPressedSignal:Emit(keyParams)
	end
	--Emits regardless of focus
	self.keyPressedIgnoreFocusSignal:Emit(keyParams)

end


function ClientInputManager:KeyReleased(keyParams)

	if self:AllowInput() then
		--Forward it along
		self.keyReleasedSignal:Emit(keyParams)
	end
	--Emits regardless of focus
	self.keyReleasedIgnoreFocusSignal:Emit(keyParams)

end


function ClientInputManager:MousePressed(mouseParams)

	if self:AllowInput() then
		--Forward it along
		self.mousePressedSignal:Emit(mouseParams)
	end

end


function ClientInputManager:MouseReleased(mouseParams)

	if self:AllowInput() then
		--Forward it along
		self.mouseReleasedSignal:Emit(mouseParams)
	end

end


function ClientInputManager:MouseMoved(mouseParams)

	if self:AllowInput() then
		--Forward it along
		self.mouseMovedSignal:Emit(mouseParams)
	end

end


function ClientInputManager:AxisMoved(axisParams)

    --local axis = axisParams:GetParameter("Axis", true):GetIntData()
    --local position = axisParams:GetParameter("Position", true):GetFloatData()
    --print("Axis: " .. tostring(axis) .. " Position: " .. tostring(position))
    if self:AllowInput() then
        self.axisMovedSignal:Emit(axisParams)
    end
    self.axisMovedIgnoreFocus:Emit(axisParams)

end