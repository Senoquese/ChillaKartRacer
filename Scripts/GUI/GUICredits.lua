--GUICREDITS CLASS START

class 'GUICredits' (IBase)

function GUICredits:__init() super()

    self.creditsPrefix = "Credits_"
	self.creditsGUILayout = GetMyGUISystem():LoadLayout("credits.layout", self.creditsPrefix)
	self.creditsCont = self.creditsGUILayout:GetWidget(self.creditsPrefix.."credits")
	self:SetVisible(false)

    self.nullParams = Parameters()
    self.selectExitSignal = self:CreateSignal("ExitCredits")
    
    --Listen for close button
    self.mouseClickSlot = self:CreateSlot("MouseClick", "MouseClick")
    GetMyGUISystem():RegisterEvent(self.creditsCont, "eventWindowButtonPressed", self.mouseClickSlot)

end


function GUICredits:BuildInterfaceDefIBase()

	self:AddClassDef("GUICredits", "IBase", "Displays the credits")

end


function GUICredits:InitIBase()

end


function GUICredits:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.creditsGUILayout)
	self.creditsGUILayout = nil

end


function GUICredits:SetVisible(setVisible)

	self.creditsGUILayout:SetVisible(setVisible)

end


function GUICredits:GetVisible()

	return self.creditsGUILayout:GetVisible()

end

function GUICredits:MouseClick(pressedParams)
    
    self.selectExitSignal:Emit(self.nullParams)
    
end
--GUICredits CLASS END