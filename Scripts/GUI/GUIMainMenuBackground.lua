UseModule("IBase", "Scripts/")
UseModule("SavedItemsSerializer", "Scripts/")

--GUIMAINMENUBACKGROUND CLASS START

class 'GUIMainMenuBackground' (IBase)

function GUIMainMenuBackground:__init() super()

	--TWEAKABLE VALUES
	self.logoSoundDelayTime = 0.3
	self.engineSoundDelayTime = .725
	--TWEAKABLE VALUES

	--The background
	self.background = OGREBackgroundImage()
	self.background:SetName("background")
	local params = Parameters()
	local numBackgrounds = 12
	local backgroundChoice = math.random(1, numBackgrounds)
	--For some reason it only chooses the first background unless we call it twice
	--BEHOLD! ONE OF THE MANY MYSTERIES OF LIFE!
	backgroundChoice = math.random(1, numBackgrounds)

-- SENOQUESE CHANGE BACKGROUND DEBUG

	-- params:AddParameter(Parameter("MaterialName", "menu_background" .. tostring(backgroundChoice)))
	params:AddParameter(Parameter("MaterialName", "menu_background_ashton"))
	self.background:Init(params)

	--The logo
	self.logoPrefix = "Logo_"
	-- if GetDemoMode() then
	-- 	self.logoGUI = GetMyGUISystem():LoadLayout("logo_demo.layout", self.logoPrefix)
	-- else
		self.logoGUI = GetMyGUISystem():LoadLayout("logo.layout", self.logoPrefix)
	-- end

	self.platform = OGREModel()
	local params = Parameters()
	params:AddParameter(Parameter("RenderMeshName", "plat.mesh"))
	self.platform:SetName("platform")
	self.platform:Init(params)
	self.platform:SetCastShadows(false)
	self.platform:SetReceiveShadows(true)
	self.platform:SetPosition(WVector3(.9, -.5, -2.5))
	self.platform:SetScale(WVector3(1.5, 1.5, 1.5))
	self.platform:SetOrientation(WQuaternion(0, -20, 0))
	self.currentSpinDegree = -20
	self.platformSpinSpeed = 80

	self:InitSounds()

	--Don't show the platform or kart until the animation starts
	self.platform:SetVisible(false)
	if IsValid(self.kart) then
		self.kart:SetVisible(false)
	end

	self.mainMenuWaitClock = WTimer()

	self.firstRunThrough = false

end


function GUIMainMenuBackground:BuildInterfaceDefIBase()

	self:AddClassDef("GUIMainMenuBackground", "IBase", "Manages all the GUIs in the main menu")

end


function GUIMainMenuBackground:LoadCustomItems()

	self:UnloadCustomItems()

	self.settingsSerializer = SavedItemsSerializer()

	local spawnParams = self.settingsSerializer:GetSettingsAsParameters()

	--Extra params
	spawnParams:AddParameter(Parameter("WheelConnectionX", 0.354*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionY", 0.12*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZFront", 0.282*1.5))
	spawnParams:AddParameter(Parameter("WheelConnectionZBack", -0.3*1.5))
	spawnParams:AddParameter(Parameter("CastShadows", true))
	spawnParams:AddParameter(Parameter("ReceiveShadows", false))

	print("Starting kart init in GUIMainMenuBackground:LoadCustomItems()")
	self.kart = OGREPlayerKart()
	--Don't flatten the colors in the main menu
	self.kart:SetFlattenColors(false)
	self.kart:SetName("MainMenuKart")
	self.kart:Init(spawnParams)
	self.kart:SetVisible(false)
	print("Finished kart init in GUIMainMenuBackground:LoadCustomItems()")

	--Set the colors for the items
	self.settingsSerializer:ApplyColors(self.kart)

	--AttachObjectToBone expects a IOGREObject as the first param, do the conversion
	self.platform:AttachObjectToBone(ToIOGREObject(self.kart), "kartanchor", WVector3(), WQuaternion())
end


function GUIMainMenuBackground:UnloadCustomItems()

	if IsValid(self.kart) then
		self.kart:UnInit()
		self.kart = nil
	end

end


function GUIMainMenuBackground:InitIBase()

end


function GUIMainMenuBackground:InitSounds()

	self.logoSound = SoundSource()
	self.logoSound:SetName("mmLogoSound")
	self.logoSound:Init(Parameters())
	self.logoSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "GUI\\Menu\\sound\\Main_Menu_ZG_Logo.wav"))
	self.logoSound:SetLooping(false)
	self.logoSound:SetReferenceDistance(0)
	self.logoSound:SetVolume(0.25)
	self.logoSound:SetDelayedPlayTime(self.logoSoundDelayTime)

	self.engineSound = SoundSource()
	self.engineSound:SetName("mmEngineSound")
	self.engineSound:Init(Parameters())
	self.engineSound:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "GUI\\Menu\\sound\\Main_Menu_Engine.wav"))
	self.engineSound:SetLooping(false)
	self.engineSound:SetReferenceDistance(0)
	self.engineSound:SetVolume(1)
	self.engineSound:SetDelayedPlayTime(self.engineSoundDelayTime)

	self.soundStopSlot = self:CreateSlot("SoundStop", "SoundStop")
	self.engineSound:GetSignal("Stop", true):Connect(self.soundStopSlot)

	self.soundsStoppedSignal = self:CreateSignal("SoundsStopped")

end


function GUIMainMenuBackground:UnInitSounds()

	if IsValid(self.logoSound) then
		self.logoSound:UnInit()
		self.logoSound = nil
	end

	if IsValid(self.engineSound) then
		self.engineSound:UnInit()
		self.engineSound = nil
	end

end


function GUIMainMenuBackground:UnInitIBase()

	if IsValid(self.background) then
		self.background:UnInit()
	end
	self.background = nil

	if IsValid(self.logoGUI) then
		GetMyGUISystem():UnloadLayout(self.logoGUI)
	end
	self.logoGUI = nil

	if IsValid(self.platform) then
		self.platform:UnInit()
	end
	self.platform = nil

	self:UnInitSounds()

	self:UnloadCustomItems()

end


function GUIMainMenuBackground:Process(frameTime)

	if not self.firstRunThrough then
		self.firstRunThrough = true
		self.mainMenuWaitClock:Reset()
	end

	local skip = false
	if IsValid(self.mainMenuWaitClock) then
		if self.mainMenuWaitClock:GetTimeSeconds() > 0.5 then
			self.platformLoadAnim = self.platform:GetAnimation("load", true)
			self.platformLoadAnim:SetLooping(false)
			self.platformLoadAnim:SetSpeed(3)
			self.platformLoadAnim:Play()
			--Now it is safe to show the platform and kart
			self.platform:SetVisible(self.visible)
			if IsValid(self.kart) then
				self.kart:SetVisible(self.visible)
				self.kart:SetCastShadows(self.visible)
			else
				print("Kart not valid in GUIMainMenuBackground.lua!!!!")
			end
			self.mainMenuWaitClock = nil
		else
			skip = true
		end
	end


	if not skip then
		--if self.logo:GetVisible() then
			--Move the logo into view
		--end

		self.background:Process(frameTime)
		self.platform:Process(frameTime)
		self.platformLoadAnim:Process(frameTime)
		if IsValid(self.kart) then
			self.kart:Process(frameTime)
		end

		if IsValid(self.logoSound) then
			self.logoSound:Process(frameTime)
		end
		if IsValid(self.engineSound) then
			self.engineSound:Process(frameTime)
		end

		self.currentSpinDegree = self.currentSpinDegree - (self.platformSpinSpeed * frameTime)
		local setQuat = WQuaternion()
		setQuat:FromEuler(0, self.currentSpinDegree, 0)
		self.platform:SetOrientation(setQuat)

		if self.visible then
			--Make sure nothing is messing with the camera
			self.camera = GetCamera()
			self.camera:SetPosition(WVector3())
			self.camera:SetOrientation(WQuaternion())
		end
	end

end

function GUIMainMenuBackground:GetVisible()
	return self.visible
end

function GUIMainMenuBackground:SetVisible(setVis)

	self.visible = setVis

	self.background:SetVisible(setVis)
	self.logoGUI:SetVisible(setVis)
	if (not setVis) or (setVis and IsValid(self.platformLoadAnim)) then
		if IsValid(self.platform) then
			self.platform:SetVisible(setVis)
		end
		if IsValid(self.kart) then
			self.kart:SetVisible(setVis)
			--BRIAN TODO: This is an attempt to solve the weird shadows
			--the kart is casting when invisible
			self.kart:SetCastShadows(setVis)
		end
	end

	if setVis then
		self.camera = GetCamera()
		self.camera:SetPosition(WVector3())
		self.camera:SetOrientation(WQuaternion())
		self:LoadCustomItems()
		if IsValid(self.kart) then
		end
		if IsValid(self.platformLoadAnim) then
			self.platformLoadAnim:Play()
		end
		self.platform:SetOrientation(WQuaternion(0, -20, 0))
		self.currentSpinDegree = -20
		self.mainMenuWaitClock = WTimer()
		self.logoSound:Play()
		self.engineSound:Play()
		self.firstRunThrough = false
	else
		--self.logo:SetPosition(WVector3(self.logoStartX, -125, 0))
		--self.logoMoveTimePassed = 0
		self:UnloadCustomItems()
	end

end


function GUIMainMenuBackground:SoundStop(stopParams)

	self.soundsStoppedSignal:Emit(Parameters())

end

--GUIMAINMENUBACKGROUND CLASS END
