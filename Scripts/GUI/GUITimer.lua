--GUITIMER CLASS START

class 'GUITimer' (IBase)

function GUITimer:__init() super()

    self.timerPrefix = "Timer_"
	self.timerGUILayout = GetMyGUISystem():LoadLayout("timer.layout", self.timerPrefix)
	self.timerCont = self.timerGUILayout:GetWidget(self.timerPrefix .. "timercont")
    self.timer = self.timerCont:FindWidget(self.timerPrefix .. "timer")
	
	self.time = 0

	--Init the timer meter with 0
    self:SetTime(0)
end

function GUITimer:BuildInterfaceDefIBase()

	self:AddClassDef("GUITimer", "IBase", "The timer GUI manager")

end

function GUITimer:InitIBase()

end


function GUITimer:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.timerGUILayout)
	self.timerGUILayout = nil
	
end

function GUITimer:SetVisible(visible)
    self.timerCont:SetVisible(visible)
end

function GUITimer:SetTime(setSeconds)

    if setSeconds < 0 then
        self.timer:SetCaption(StringToUTFString("O.T."))
        return
    end

	if self.time ~= math.floor(setSeconds) then
		self.time = math.floor(setSeconds)
		
		local mins = math.floor(setSeconds/60)
		local minStr = ""..mins
		if mins < 10 then
		    minStr = "0"..minStr
		end
		
		local secs = math.floor(setSeconds - math.floor(60*math.floor(setSeconds/60)))
		local secStr = ""..secs
		if secs < 10 then
		    secStr = "0"..secStr
		end
		--print(minStr .. ":" .. secStr)
		self.timer:SetCaption(StringToUTFString(minStr .. ":" .. secStr))
	end

end


--GUITIMER CLASS END