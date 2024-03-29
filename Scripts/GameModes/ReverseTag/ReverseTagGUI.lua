--REVERSETAGGUI CLASS START

class 'ReverseTagGUI' (IBase)

function ReverseTagGUI:__init() super()

    self.tagPrefix = "Tag_"
	self.tagGUILayout = GetMyGUISystem():LoadLayout("tagbar.layout", self.tagPrefix)
	self.tagCont = self.tagGUILayout:GetWidget(self.tagPrefix .. "tagbarcont")
    self.scoreBar = ToProgress(self.tagCont:FindWidget(self.tagPrefix .. "tagbarmeter"))
    self.scoreBarName = self.tagCont:FindWidget(self.tagPrefix .. "tagbarname")
    self.alertPositive = self.tagGUILayout:GetWidget(self.tagPrefix .. "alertpos")
    self.alertNegative = self.tagGUILayout:GetWidget(self.tagPrefix .. "alertneg")

    self:ShowPositiveAlert(false)
    self:ShowNegativeAlert(false)
    self:ShowScoreBar(false)

end

function ReverseTagGUI:BuildInterfaceDefIBase()

	self:AddClassDef("ReverseTagGUI", "IBase", "The Reverse Tag GUI Manager")

end

function ReverseTagGUI:InitIBase()

end

function ReverseTagGUI:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.tagGUILayout)
	self.tagGUILayout = nil
	
end

function ReverseTagGUI:ShowPositiveAlert(show)

    self.alertPositive:SetVisible(show)

end

function ReverseTagGUI:ShowNegativeAlert(show)

    self.alertNegative:SetVisible(show)

end

function ReverseTagGUI:ShowScoreBar(show)

    self.tagCont:SetVisible(show)

end

function ReverseTagGUI:SetScoreBar(percent)

    self.scoreBar:SetProgressPosition(math.ceil(percent*100))
    
end

function ReverseTagGUI:SetScoreBarName(name)

    self.scoreBarName:SetCaption(StringToUTFString(name))

end

function ReverseTagGUI:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.tagGUILayout)
	self.tagGUILayout = nil
	
end

--REVERSETAGGUI CLASS END