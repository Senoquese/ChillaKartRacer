UseModule("GUITimer", "Scripts\\GameModes\\Race\\")

--GUISCORETIMER CLASS START

class 'GUIScoreTimer' (IBase)

function GUIScoreTimer:__init(anchorOverride, positionOverride) super()

	self.time = 0
	self.leftScore = 0
	self.rightScore = 0

    self.stimerPrefix = "ScoreTimer_"
	self.stimerGUILayout = GetMyGUISystem():LoadLayout("timer_score.layout", self.stimerPrefix)
    self.stimerCont = self.stimerGUILayout:GetWidget(self.stimerPrefix .. "cont")
    self.redScore = self.stimerCont:FindWidget(self.stimerPrefix .. "redscore")
    self.blueScore = self.stimerCont:FindWidget(self.stimerPrefix .. "bluescore")
    self.redBorder = self.stimerCont:FindWidget(self.stimerPrefix .. "redteam")
    self.blueBorder = self.stimerCont:FindWidget(self.stimerPrefix .. "blueteam")
    
    self.redText = self.stimerCont:FindWidget(self.stimerPrefix .. "redtext")
    self.blueText = self.stimerCont:FindWidget(self.stimerPrefix .. "bluetext")
    
    self.blueScored = self.stimerGUILayout:GetWidget(self.stimerPrefix .. "scoredblue")
    self.redScored = self.stimerGUILayout:GetWidget(self.stimerPrefix .. "scoredred")
    self.redWin = self.stimerGUILayout:GetWidget(self.stimerPrefix .. "redwin")
    self.blueWin = self.stimerGUILayout:GetWidget(self.stimerPrefix .. "bluewin")
    
    self.blueScored:SetVisible(false)
    self.redScored:SetVisible(false)
    self.blueBorder:SetVisible(false)
    self.redBorder:SetVisible(false)
    self.blueText:SetVisible(false)
    self.redText:SetVisible(false)
    self.redWin:SetVisible(false)
    self.blueWin:SetVisible(false)
    
	self.timerGUI = GUITimer()

end


function GUIScoreTimer:InitIBase()

end


function GUIScoreTimer:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.stimerGUILayout)
	self.stimerGUILayout = nil
	self.timerGUI:UnInit()
	self.timerGUI = nil

end

function GUIScoreTimer:BuildInterfaceDefIBase()

	self:AddClassDef("GUIScoreTimer", "IBase", "The score timer GUI manager")

end

function GUIScoreTimer:SetVisible(visible)
    self.stimerGUILayout:SetVisible(visible)
    self.timerGUI:SetVisible(visible)
end

function GUIScoreTimer:GetVisible()
    self.stimerGUILayout:GetVisible()
end

function GUIScoreTimer:ShowRedScored(visible)
    self.redScored:SetVisible(visible)
end

function GUIScoreTimer:ShowBlueScored(visible)
    self.blueScored:SetVisible(visible)
end

function GUIScoreTimer:ShowWin(redWon)

    self.redWin:SetVisible(redWon)
    self.blueWin:SetVisible(not redWon)
    
end

function GUIScoreTimer:HideWin()

    self.redWin:SetVisible(false)
    self.blueWin:SetVisible(false)
    
end

function GUIScoreTimer:SetTime(setSeconds)

	if self.time ~= math.floor(setSeconds) then
		self.time = math.floor(setSeconds)
        self.timerGUI:SetTime(self.time)
        
        -- five second warning
        if self.time <= 5 and self.time > 0 then
            GetSoundSystem():EmitSound(ASSET_DIR .. "sound/countdown_single.wav", WVector3(),1.0, 100, false, SoundSystem.HIGH)
        end
	end

end

function GUIScoreTimer:GetTime()

    return self.time

end

function GUIScoreTimer:SetTeam(redTeam)

	self.redBorder:SetVisible(redTeam)
	self.redText:SetVisible(redTeam)
	self.blueBorder:SetVisible(not redTeam)
	self.blueText:SetVisible(not redTeam)

end

function GUIScoreTimer:SetLeftScore(setScore)
    --RED
	if self.leftScore ~= setScore then
		self.leftScore = setScore
		self.redScore:SetCaption(StringToUTFString(tostring(self.leftScore)))
	end

end


function GUIScoreTimer:SetRightScore(setScore)
    --BLUE
	if self.rightScore ~= setScore then
		self.rightScore = setScore
        self.blueScore:SetCaption(StringToUTFString(tostring(self.rightScore)))
	end

end

--GUISCORETIMER CLASS END