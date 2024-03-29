--GUIBOOST CLASS START

class 'GUIBoost' (IBase)

function GUIBoost:__init() super()

    self.boostPrefix = "Boost_"
	self.boostGUILayout = GetMyGUISystem():LoadLayout("boost.layout", self.boostPrefix)
	self.boostCont = self.boostGUILayout:GetWidget(self.boostPrefix .. "boostcont")
    self.boostMeter = ToProgress(self.boostCont:FindWidget(self.boostPrefix .. "boostmeter"))
	
	self.limitClock = WTimer()
	self.limitTimer = 0.1

	--Init the boost meter with 0
    self:SetBoostPercent(0)
end

function GUIBoost:BuildInterfaceDefIBase()

	self:AddClassDef("GUIBoost", "IBase", "The boost GUI manager")

end

function GUIBoost:InitIBase()

end

function GUIBoost:SetVisible(visible)
    self.boostGUILayout:SetVisible(visible)
end

function GUIBoost:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.boostGUILayout)
	self.boostGUILayout = nil
	
end

function GUIBoost:SetBoostPercent(percent)

	--setBoostPercent expects the value to be between 0 and 100
	--It is passed into this function between 0 and 1
	self.target = percent*100
    if percent == 0 then
        self.boostMeter:SetProgressPosition(math.ceil(percent*100))
    end
end

function GUIBoost:Process()
    --[[
    local cb = self.boostMeter:GetProgressPosition()
    local nb = cb + (self.target - cb)/10
    if nb < 1 then
        self.boostMeter:SetProgressPosition(0)
    elseif nb > 99 then
        self.boostMeter:SetProgressPosition(99)
    else
        self.boostMeter:SetProgressPosition(math.round(nb))
    end
    --]]
    local cb = self.boostMeter:GetProgressPosition()
    if cb < math.round(self.target) then
        self.boostMeter:SetProgressPosition(cb+1)
    elseif cb > math.round(self.target) then
        self.boostMeter:SetProgressPosition(cb-1)
    end
    
    if self.boostMeter:GetProgressPosition() >=99 and self.target == 100 then
        self.boostMeter:SetProgressPosition(100)
    elseif self.boostMeter:GetProgressPosition() <= 1 and self.target == 0 then
        self.boostMeter:SetProgressPosition(0)
    end 
end

function math.round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end

--GUIBOOST CLASS END