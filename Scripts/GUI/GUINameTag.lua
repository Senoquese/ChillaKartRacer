--GUINAMETAG CLASS START

class 'GUINameTag' (IBase)

function GUINameTag:__init(followPlayer, setRed, setGreen, setBlue) super()

	if not IsValid(followPlayer) then
		error("Invalid player passed into GUINameTag constructor")
	end

    self.tagPrefix = "NameTag_"..followPlayer:GetUniqueID()
	self.tagGUILayout = GetMyGUISystem():LoadLayout("nametag.layout", self.tagPrefix)
    self.nametag = ToStaticText(self.tagGUILayout:GetWidget(self.tagPrefix .. "nametag"))

    self.halfTagWidth = self.nametag:GetSize().width/2
    self.tagHeight = self.nametag:GetSize().height

	self.followPlayer = followPlayer
	
	--Start off invisible
	self:SetVisible(false)

	self.forceVisible = false
	self.forceInvisible = false

	self.colorParams = Parameters()
	self:UpdateName()
	self:SetColor(setRed, setGreen, setBlue)

end


function GUINameTag:BuildInterfaceDefIBase()

	self:AddClassDef("GUINameTag", "IBase", "The Nametag GUI")

end


function GUINameTag:SetPosition(nameTagPos)

   -- print("Setting name tag position:"..tostring(nameTagPos))
    local point = MyGUIIntPoint(nameTagPos.x*GetOGRESystem():GetViewportWidth()-self.halfTagWidth, nameTagPos.y*GetOGRESystem():GetViewportHeight()-self.tagHeight)
    self.nametag:SetPosition(point)
    
end


function GUINameTag:SetOpacity(opacity)

    self.nametag:SetAlpha(opacity)
    
end


function GUINameTag:SetVisible(setVisible)

    if self.forceVisible then
        setVisible = true
    elseif self.forceInvisible then
        setVisible = false
    end

	self.nametag:SetVisible(setVisible)

end


function GUINameTag:UpdateName()

	self.currentName = self.followPlayer:GetName()
    self.nametag:SetCaption(StringToUTFString(self.currentName))

end


function GUINameTag:InitIBase()

end


function GUINameTag:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.tagGUILayout)
	self.tagGUILayout = nil

end


function GUINameTag:SetColor(setRed, setBlue, setGreen)
    
    self.nametag:SetTextColour(MyGUIColour(setRed, setBlue, setGreen, 1.0))

end


function GUINameTag:SetForceVisible(setVis)

	self.forceVisible = setVis
	self:SetVisible(setVis)

end


function GUINameTag:GetForceVisible()

	return self.forceVisible

end


function GUINameTag:SetForceInvisible(setInvis)

    self.forceInvisible = setInvis
    self:SetVisible(not setInvis)
    
end


function GUINameTag:GetForceInvisible()

	return self.forceInvisible

end


--Return the Player that this name tag is assigned to
function GUINameTag:GetPlayer()

	return self.followPlayer

end


function GUINameTag:GetDisplayedName()

	return self.currentName

end


function GUINameTag:SystemInited(initParams)

	self:UpdateName()

end

--GUINAMETAG CLASS END