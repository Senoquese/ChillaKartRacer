UseModule("IBase", "Scripts/")

--IGUI CLASS START

class 'IGUI' (IBase)

function IGUI:__init() super()

	self.playSoundSlot = nil
	self.gui = nil

	self.processSlot = self:CreateSlot("IGUIProcess", "IGUIProcessSlot")
	--We will process after the script system
	GetScriptSystem():GetSignal("ProcessEnd", true):Connect(self.processSlot)

	self.systemInitedSlot = self:CreateSlot("SystemInited", "SystemInited")
	self.systemUnInitedSlot = self:CreateSlot("SystemUnInited", "SystemUnInited")

end


function IGUI:BuildInterfaceDefIBase()

	self:AddClassDef("IGUI", "IBase", "Interface to any class that will manage a GUI")
	self:AddFuncDef("IGUI", self.InitIGUI, self.I_REQUIRED_FUNC, "InitIGUI", "Called when the object is being inited")
	self:AddFuncDef("IGUI", self.UnInitIGUI, self.I_REQUIRED_FUNC, "UnInitIGUI", "Called when the object is being uninited")
	self:AddFuncDef("IGUI", self.ProcessImp, self.I_OPTIONAL_FUNC, "ProcessImp", "The IGUI will be given processing time though ProcessImp()")
	self:AddFuncDef("IGUI", self.BuildInterfaceDefIGUI, self.I_OPTIONAL_FUNC, "BuildInterfaceDefIGUI", "")

    if IsValid(self.BuildInterfaceDefIGUI) then
        self:BuildInterfaceDefIGUI()
    end

end


function IGUI:InitIBase()

	self:InitIGUI()

end


function IGUI:UnInitIBase()

	self:UnInitIGUI()
	self.gui = nil

end


function IGUI:Set(setGUI)

	self.gui = setGUI

	self.systemInitedSlot:DisconnectAll()
	if IsValid(self.gui.GetSignal) and IsValid(self.gui:GetSignal("SystemInited", false)) then
		self.gui:GetSignal("SystemInited", true):Connect(self.systemInitedSlot)
	end
	self.systemUnInitedSlot:DisconnectAll()
	if IsValid(self.gui.GetSignal) and IsValid(self.gui:GetSignal("SystemUnInited", false)) then
		self.gui:GetSignal("SystemUnInited", true):Connect(self.systemUnInitedSlot)
	end

	if IsValid(self.gui.RequestSlotConnectToSignal) then
		--This will be called when the GUI wants to make a sound
		self.playSoundSlot = self:CreateSlot("PlaySoundFromPath", "PlaySoundFromPath")
		self.gui:RequestSlotConnectToSignal(self.playSoundSlot, "PlaySoundFromPath")

		--This will be called when the GUI wants to make a sound
		self.traceSlot = self:CreateSlot("Trace", "Trace")
		self.gui:RequestSlotConnectToSignal(self.traceSlot, "Trace")
	end

end


function IGUI:Get()

	return self.gui

end


function IGUI:PlaySoundFromPath(soundParams)

	local soundPath = soundParams:GetParameter(0, true):GetStringData()
	--Assuming all GUI sounds are played in local space, not 3D sounds
	GetSoundSystem():EmitSound(ASSET_DIR .. soundPath, WVector3(0, 0, 0), 1, 0, false, SoundSystem.MEDIUM)

end


function IGUI:Trace(traceParams)

	local message = traceParams:GetParameter(0, true):GetStringData()
	print("^^^ GUI MESSAGE: " .. message)

end


function IGUI:SetAnchorPoint(setAnchor)

	if IsValid(self.gui) then
		self.gui:SetAnchorPoint(setAnchor)
	end

end


function IGUI:GetAnchorPoint()

	if IsValid(self.gui) then
		self.gui:GetAnchorPoint()
	end

end


function IGUI:SetPosition(setPosition, relative)

	if IsValid(self.gui) then
		self.gui:SetPosition(setPosition, relative)
	end

end


function IGUI:GetPosition()

	if IsValid(self.gui) then
		self.gui:GetPosition()
	end

end


function IGUI:SetOpacity(opacityValue)

	if IsValid(self.gui) then
		self.gui:SetOpacity(opacityValue)
	end

end


function IGUI:GetOpacity()

	if IsValid(self.gui) then
		self.gui:GetOpacity()
	end

end


function IGUI:SetVisible(setVisible)

	if IsValid(self.gui) and IsValid(self.gui.SetVisible) then
		self.gui:SetVisible(setVisible)
	end

end


function IGUI:GetVisible()

	if IsValid(self.gui) and IsValid(self.gui.GetVisible) then
		return self.gui:GetVisible()
	end
	return false

end


function IGUI:Show(withFade, fadeTime)

	if IsValid(self.gui) then
		self.gui:Show(withFade, fadeTime)
	end

end


function IGUI:Hide(withFade, fadeTime)

	if IsValid(self.gui) then
		self.gui:Hide(withFade, fadeTime)
	end

end


function IGUI:Focus()

	if IsValid(self.gui) then
		self.gui:Focus()
	end

end


--This Process function serves no purpose unless a child
--class overrides ProcessImp()
function IGUI:ProcessGUI()

	PUSH_PROFILE("IGUI:Process()")

	if IsValid(self.ProcessImp) then
		self:ProcessImp()
	end

	POP_PROFILE("IGUI:Process()")

end


function IGUI:IGUIProcessSlot()

	self:ProcessGUI()

end


--This is here in case the child class doesn't implement it
function IGUI:SystemInited(initParams)

end


--This is here in case the child class doesn't implement it
function IGUI:SystemUnInited(unInitParams)

end

--IGUI CLASS END