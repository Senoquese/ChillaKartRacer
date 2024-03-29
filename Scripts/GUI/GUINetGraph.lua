UseModule("IGUI", "Scripts/GUI/")

--GUINETGRAPH CLASS START

class 'GUINetGraph' (IGUI)

function GUINetGraph:__init() super()

	self.guiContainer = GetWGUISystem():AddContainer()

	self.guiLines = WGUILines("NetLines")
	self.guiContainer:Attach(ToWGUIElement(self.guiLines))

	self.guiLinesMat = WGUIMaterial("NetLinesMat", "menu_logo")
	self.guiContainer:Attach(ToWGUIElement(self.guiLinesMat))
	self.guiContainer:SetDimensions(128, 64)

	--Register this GUI with the IGUI base
	self:Set(self.guiContainer)

end


function GUINetGraph:InitIGUI()

	self.guiLines:Begin():
		AddLine(WVector3(0, 0, 0), WVector3(1, 1, 0), WColorValue(1, 0, 0, 0)):
		AddLine(WVector3(0.5, 1, 0), WVector3(0.5, 0, 0), WColorValue(0, 1, 0, 0)):
	End()

end


function GUINetGraph:UnInitIGUI()

	self.guiLines = nil
	self.guiLinesMat = nil

	GetWGUISystem():RemoveContainer(self.guiContainer:GetID())
	self.guiContainer = nil

end


function GUINetGraph:ProcessImp()

end

--GUINETGRAPH CLASS END