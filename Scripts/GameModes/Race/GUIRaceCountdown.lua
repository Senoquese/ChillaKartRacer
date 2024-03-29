UseModule("IBase", "Scripts/")

--GUIRACECOUNTDOWN CLASS START

class 'GUIRaceCountdown' (IBase)

function GUIRaceCountdown:__init() super()

    --Timer
    self.clock = WTimer()

	--MyGUI init
	self.countdownPrefix = "Countdown_"
	self.countdownGUILayout = GetMyGUISystem():LoadLayout("countdown.layout", self.countdownPrefix)
	self.number1 = self.countdownGUILayout:GetWidget(self.countdownPrefix .. "count1")
	self.number2 = self.countdownGUILayout:GetWidget(self.countdownPrefix .. "count2")
	self.number3 = self.countdownGUILayout:GetWidget(self.countdownPrefix .. "count3")
	self:SetVisible(false)
	
	--Sound init
	self.countdownSingle = SoundSource()
	self.countdownSingle:SetName("CountdownSingle")
	self.countdownSingle:Init(Parameters())
	self.countdownSingle:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/countdown_single.wav"))
	self.countdownSingle:SetLooping(false)
	self.countdownSingle:SetSpatialMode(SoundSource.LOCAL)
	self.countdownSingle:SetVolume(1)
	
	self.countdownStart = SoundSource()
	self.countdownStart:SetName("CountdownStart")
	self.countdownStart:Init(Parameters())
	self.countdownStart:SetResource(GetSoundSystem():GetSoundResource(ASSET_DIR .. "sound/countdown_start.wav"))
	self.countdownStart:SetLooping(false)
	self.countdownStart:SetSpatialMode(SoundSource.LOCAL)
	self.countdownStart:SetVolume(1)

	self.roundStartTime = 0

end


function GUIRaceCountdown:BuildInterfaceDefIBase()

	self:AddClassDef("GUIRaceCountdown", "IBase", "Manages the countdown GUI")

end


function GUIRaceCountdown:InitIBase()

end


function GUIRaceCountdown:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.countdownGUILayout)
	self.countdownGUILayout = nil
	
	self.countdownSingle:UnInit()
	self.countdownSingle = nil
	
	self.countdownStart:UnInit()
	self.countdownStart = nil

end

function GUIRaceCountdown:SetVisible(visible)

    self.countdownGUILayout:SetVisible(visible)
    
end

function GUIRaceCountdown:GetVisible()

    return self.countdownGUILayout:GetVisible()
    
end

function GUIRaceCountdown:Process()

    if not self:GetVisible() then
        return
    end

    local curTime = GetClientSystem():GetTime()
    local tts = self.roundStartTime - curTime

    --print("tts:"..tts)

    if tts <= 0 then
        self.countdownStart:Play()
        self:SetVisible(false)
    elseif tts < 1 then
        if not self.number1:IsVisible() then
            self.countdownSingle:Play()
        end
        self.number1:SetVisible(true)
	    self.number2:SetVisible(false)
	    self.number3:SetVisible(false)
	    self.number1:SetAlpha(tts)
    elseif tts < 2 then
        if not self.number2:IsVisible() then
            self.countdownSingle:Play()
        end
        self.number1:SetVisible(false)
	    self.number2:SetVisible(true)
	    self.number3:SetVisible(false)
	    self.number2:SetAlpha(tts-1)
    else
        self.number1:SetVisible(false)
	    self.number2:SetVisible(false)
	    self.number3:SetVisible(true)
	    self.number3:SetAlpha(tts-2)
    end 

end


function GUIRaceCountdown:Start(startTime)

	if not IsValid(startTime) then
		error("startTime is not valid")
	end

    print("GUI Countdown startTime:"..startTime)
    print("Current time:"..GetClientSystem():GetTime())

    self.roundStartTime = startTime

	--Make sure the countdown model is visible
	self.number1:SetVisible(false)
	self.number2:SetVisible(false)
	self.number3:SetVisible(true)
    self:SetVisible(true)
    self.clock:Reset()

    self.countdownSingle:Play()

	--Play countdown sound
	--self.countdownSound:Play()

end

--GUIRACECOUNTDOWN CLASS END