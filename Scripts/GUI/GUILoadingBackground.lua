--GUILOADINGBACKGROUND CLASS START

class 'GUILoadingBackground' (IBase)

function GUILoadingBackground:__init() super()

    self.loadingPrefix = "Loading_"
    local layoutFile = "loading.layout"
    if true or GetClientManager().launchCount <= 10 then
        layoutFile = "loading_noob.layout"
    end
	self.loadingGUILayout = GetMyGUISystem():LoadLayout(layoutFile, self.loadingPrefix)
	self.loadingCont = self.loadingGUILayout:GetWidget(self.loadingPrefix.."cont")
	self:SetVisible(false)

	--Set key bindings
	if layoutFile ==  "loading_noob.layout" then
	    self.loadingCont:FindWidget(self.loadingPrefix.."freelook"):SetCaption(StringToUTFString(self:ConvertKeyCodeToString("ControlMouseLook")))
	    if GetClientInputManager().autoMouseLook then
	        self.loadingCont:FindWidget(self.loadingPrefix.."freelook"):SetCaption(StringToUTFString("MOVE MOUSE"))
	    end
	    self.loadingCont:FindWidget(self.loadingPrefix.."hop"):SetCaption(StringToUTFString(self:ConvertKeyCodeToString("Hop")))
	    self.loadingCont:FindWidget(self.loadingPrefix.."reset"):SetCaption(StringToUTFString(self:ConvertKeyCodeToString("ControlReset")))
	end

end


function GUILoadingBackground:BuildInterfaceDefIBase()

	self:AddClassDef("GUILoadingBackground", "IBase", "Displays a loading indicator")

end


function GUILoadingBackground:InitIBase()

end


function GUILoadingBackground:UnInitIBase()

    GetMyGUISystem():UnloadLayout(self.loadingGUILayout)
	self.loadingGUILayout = nil

end


function GUILoadingBackground:SetVisible(setVisible)

	self.loadingGUILayout:SetVisible(setVisible)
    if setVisible then
        if not IsValid(self.savedVol) then
            self.savedVol = GetSoundSystem():GetSFXVolume()
            print("savedVol: "..self.savedVol)
        end
        GetSoundSystem():SetSFXVolume(0)
    else
        if IsValid(self.savedVol) then
            print("restoring volume: "..self.savedVol)
            GetSoundSystem():SetSFXVolume(self.savedVol)
            self.savedVol = nil
        end
    end

end


function GUILoadingBackground:GetVisible()

	return self.loadingGUILayout:GetVisible()

end

function GUILoadingBackground:ConvertKeyCodeToString(key)
    
     local keyCode = KeyCodeToString(GetClientInputManager():GetKeyCode(1, key))
     
     if keyCode == " " then
        keyCode = "SPACE BAR"
     elseif keyCode == "MB_RIGHT" then
        keyCode = "RIGHT CLICK"
     elseif keyCode == "MB_LEFT" then
        keyCode = "LEFT CLICK"
     end
     
     return keyCode

end

--GUILOADINGBACKGROUND CLASS END