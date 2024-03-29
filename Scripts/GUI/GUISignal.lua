--GUISignal CLASS START

class 'GUISignal' (IBase)

function GUISignal:__init() super()

    self.sgPrefix = "Signal_"
	self.sgGUILayout = GetMyGUISystem():LoadLayout("signal.layout", self.sgPrefix)
	self.sgCont = self.sgGUILayout:GetWidget(self.sgPrefix .. "signal")
    self.quality1 = self.sgCont:FindWidget(self.sgPrefix .. "4")
    self.quality2 = self.sgCont:FindWidget(self.sgPrefix .. "3")
    self.quality3 = self.sgCont:FindWidget(self.sgPrefix .. "2")
    self.quality4 = self.sgCont:FindWidget(self.sgPrefix .. "1")
    self.warning = self.sgGUILayout:GetWidget(self.sgPrefix .. "notification")
	
	self.qCount = 0
	
	--Hide icons
    self:SetQuality(0)
    
end


function GUISignal:BuildInterfaceDefIBase()

	self:AddClassDef("GUISignal", "IBase", "The quality signal gui manager")

end


function GUISignal:InitIBase()

end


function GUISignal:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.sgGUILayout)
	self.sgGUILayout = nil
	
end


function GUISignal:SetVisible(visible)
    --print("GUISignal:SetVisible: "..tostring(visible))
    self.sgGUILayout:SetVisible(visible)
end


function GUISignal:SetQuality(quality)

    --print("GUISignal:SetQuality: "..tostring(quality))    

    -- test
    --quality = 201

    self.quality1:SetVisible(false)
    self.quality2:SetVisible(false)
    self.quality3:SetVisible(false)
    self.quality4:SetVisible(false)
    self.warning:SetVisible(false)
    
    if quality < 0 then
        return
    end
    
    if quality <= 100 then
        self.quality1:SetVisible(true)
    elseif quality <= 150 then
        self.quality2:SetVisible(true)
    elseif quality <= 200 then
        self.quality3:SetVisible(true)
    else    
        self.qCount = self.qCount + 1
        self.quality4:SetVisible(true)
        if math.floor(self.qCount/70) % 2 == 0 then
            self.warning:SetVisible(true)
        else
            self.warning:SetVisible(false)
        end
    end 

end

--GUISignal CLASS END