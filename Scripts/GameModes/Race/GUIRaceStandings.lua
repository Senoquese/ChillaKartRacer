--GUIRACESTANDINGS CLASS START

class 'GUIRaceStandings' (IBase)

function GUIRaceStandings:__init() super()

    self.standPrefix = "Standings_"
	self.standGUILayout = GetMyGUISystem():LoadLayout("results.layout", self.standPrefix)
	self.standCont = self.standGUILayout:GetWidget(self.standPrefix .. "standingscont")
    self.name1Text = self.standCont:FindWidget(self.standPrefix .. "name1")
    self.name2Text = self.standCont:FindWidget(self.standPrefix .. "name2")
    self.name3Text = self.standCont:FindWidget(self.standPrefix .. "name3")
    self.render1 = self.standCont:FindWidget(self.standPrefix .. "renderbox1")
    self.render2 = self.standCont:FindWidget(self.standPrefix .. "renderbox2")
    self.render3 = self.standCont:FindWidget(self.standPrefix .. "renderbox3")
    self.resultList = ToList(self.standCont:FindWidget(self.standPrefix .. "results"))

	--Overlays init
	self.overlays = { }
	local i = 1
	while i < 4 do
		self.overlays[i] = OGREScreenOverlay()
		self.overlays[i]:Init(Parameters())
		self.overlays[i]:SetPosition(WVector3(0, 0.3, 0))
		i = i + 1
	end

    self.name1Text:SetCaption(StringToUTFString(""))
    self.name2Text:SetCaption(StringToUTFString(""))
    self.name3Text:SetCaption(StringToUTFString(""))

	self.standings = { }
	self.params = Parameters()
	self.standingsEnabled = false

	self.camerasProcessEndSlot = self:CreateSlot("CamerasProcessEnd", "CamerasProcessEnd")
	GetCameraManager():GetSignal("ProcessEnd"):Connect(self.camerasProcessEndSlot)

end

function GUIRaceStandings:BuildInterfaceDefIBase()

	self:AddClassDef("GUIRaceStandings", "IBase", "The race results GUI manager")

end

function GUIRaceStandings:InitIBase()

end


function GUIRaceStandings:UnInitIBase()

	GetMyGUISystem():UnloadLayout(self.standGUILayout)
	self.standGUILayout = nil

end

function GUIRaceStandings:SetVisible(visible)
    self.standGUILayout:SetVisible(visible)
    if visible then
        --self:Show3DControllers()
    else
        --self:Hide3DControllers()
    end
end

function GUIRaceStandings:GetVisible()
    return self.standGUILayout:GetVisible()
end

--Pass in a table in this format:
--{ { player, 2 }, { player, 1 }, { player, 3 }, etc }
--Where the first item is the Player object and the second is
--Their current standing (position) in the race.
--The players can be in any order.
function GUIRaceStandings:ShowStandings(standingsTable, sortLowerIsBetter)

    self.standingsEnabled = true

    self:SetVisible(true)

    --Clear the names
    self.name1Text:SetCaption(StringToUTFString(""))
    self.name2Text:SetCaption(StringToUTFString(""))
    self.name3Text:SetCaption(StringToUTFString(""))
    --Clear the list
    self.resultList:RemoveAllItems()

    --First sort the passed in table
    if sortLowerIsBetter == nil or sortLowerIsBetter then
        table.sort(standingsTable, function(playerA, playerB) return playerA[2] < playerB[2] end)
    else
        table.sort(standingsTable, function(playerA, playerB) return playerA[2] > playerB[2] end)
    end

    --Clear the old table first
    self.standings = { }
    for standingIndex, standing in pairs(standingsTable) do
        table.insert(self.standings, standing)

        local nameText = nil
        if standingIndex == 1 then
            nameText = self.name1Text
        elseif standingIndex == 2 then
            nameText = self.name2Text
        elseif standingIndex == 3 then
            nameText = self.name3Text
        else
            self.resultList:AddItem(StringToUTFString(standingIndex.."   " .. standing[1]:GetName()), MyGUIAny())
        end

        if IsValid(nameText) then
            nameText:SetCaption(StringToUTFString(tostring(standing[1]:GetName())))
        end
    end

    --Show the 3D controllers on the GUI
    self:Show3DControllers()

end


function GUIRaceStandings:HideStandings()

	self.standingsEnabled = false

	self:SetVisible(false)
	self:Hide3DControllers()

end


function GUIRaceStandings:Show3DControllers()

	for standingIndex, standing in pairs(self.standings) do
		if standingIndex < 4 then
			if standing[1]:GetControllerValid() then
				standing[1]:GetController():SetOverlay(true, true)
				standing[1]:GetController():SetPosition(WVector3(0, 0, 0))
				standing[1]:GetController():SetOrientation(WQuaternion())
				standing[1]:GetController():SetVisible(true)
			end
		else
			break
		end
	end

end


function GUIRaceStandings:Hide3DControllers()

	for standingIndex, standing in pairs(self.standings) do
		if standingIndex < 4 then
			if IsValid(standing[1]:GetController()) then
				standing[1]:GetController():SetOverlay(false, true)
			end
		else
			break
		end
	end

end


function GUIRaceStandings:CamerasProcessEnd(processParams)

	if self.standingsEnabled then
		--Ensure that the visible controllers on the GUI are visible
		if #self.standings > 0 then
		    local rbox = self.render1
			local renderPos = self.standCont:GetPosition()
            local renderX = renderPos.left + rbox:GetPosition().left + rbox:GetSize().width/2
            local renderY = renderPos.top + rbox:GetPosition().top + rbox:GetSize().height/2
            renderX = renderX / GetOGRESystem():GetViewportWidth()
            renderY = renderY / GetOGRESystem():GetViewportHeight()
			local screenVector = GetCamera():GetCameraToViewportVector(renderX, renderY)
			local screenOrigin = GetCamera():GetCameraToViewportOrigin(renderX, renderY)
			if self.standings[1][1]:GetControllerValid() then
				self.standings[1][1]:GetController():SetPosition(screenOrigin + (screenVector * 8))
				self.standings[1][1]:GetController():SetOrientation(GetCamera():GetOrientation() * WQuaternion(20, -30, 0))
				self.standings[1][1]:GetController():SetVisible(true)
			end
		end
		if #self.standings > 1 then
			local rbox = self.render2
			local renderPos = self.standCont:GetPosition()
            local renderX = renderPos.left + rbox:GetPosition().left + rbox:GetSize().width/2
            local renderY = renderPos.top + rbox:GetPosition().top + rbox:GetSize().height/2
            renderX = renderX / GetOGRESystem():GetViewportWidth()
            renderY = renderY / GetOGRESystem():GetViewportHeight()
			local screenVector = GetCamera():GetCameraToViewportVector(renderX, renderY)
			local screenOrigin = GetCamera():GetCameraToViewportOrigin(renderX, renderY)
			if self.standings[2][1]:GetControllerValid() then
				self.standings[2][1]:GetController():SetPosition(screenOrigin + (screenVector * 9))
				self.standings[2][1]:GetController():SetOrientation(GetCamera():GetOrientation() * WQuaternion(20, -30, 0))
				self.standings[2][1]:GetController():SetVisible(true)
			end
		end
		if #self.standings > 2 then
			local rbox = self.render3
			local renderPos = self.standCont:GetPosition()
            local renderX = renderPos.left + rbox:GetPosition().left + rbox:GetSize().width/2
            local renderY = renderPos.top + rbox:GetPosition().top + rbox:GetSize().height/2
            renderX = renderX / GetOGRESystem():GetViewportWidth()
            renderY = renderY / GetOGRESystem():GetViewportHeight()
			local screenVector = GetCamera():GetCameraToViewportVector(renderX, renderY)
			local screenOrigin = GetCamera():GetCameraToViewportOrigin(renderX, renderY)
			if self.standings[3][1]:GetControllerValid() then
				self.standings[3][1]:GetController():SetPosition(screenOrigin + (screenVector * 10))
				self.standings[3][1]:GetController():SetOrientation(GetCamera():GetOrientation() * WQuaternion(20, -30, 0))
				self.standings[3][1]:GetController():SetVisible(true)
			end
		end
	end

end


function GUIRaceStandings:SystemInited(initParams)

end

--GUIRACESTANDINGS CLASS END