local objectSelectorEnabled = false
local newObjectName = nil
local newObjectProfile = nil
local newObjectProfiles = nil
local newClassType = nil
local currentlySelectedObjectName = "nillikeapil"
local indicatorsVisible = true

local rightPressed = false
local leftPressed = false
local upPressed = false
local downPressed = false
local objectMoved = false

-- Move along X-axis
local constrainXAxis = false

-- Move along Y-axis
local constrainYAxis = false

-- Move along Z-axis
local constrainZAxis = false

local lastMousePosX = 0
local lastMousePosY = 0

function InitObjectSelector()

end


function ObjectSelectorEnabled(guiArgs)

	local enabled = GetNaviMultiValue(guiArgs, "Enabled")
	objectSelectorEnabled = enabled:toBool()

	HighlightAllIndicators(false)

	local inputRegister = GetScriptInputRegister()
    local scriptSystem = GetScriptSystem()
	if objectSelectorEnabled then
		ShowMapEditorIndicators()
		indicatorsVisible = true
		inputRegister:AddScriptMouseListener("PlaceNewObject")
		scriptSystem:AddAutoCall("UpdateTextBoxToObjectName")
		inputRegister:AddScriptKeyListener("KeyboardAdjustObjectPosition")
		scriptSystem:AddAutoCall("AdjustObjectPosition")
	else
		HideMapEditorIndicators()
		indicatorsVisible = false
		inputRegister:RemoveScriptMouseListener("PlaceNewObject")
        inputRegister:RemoveScriptKeyListener("KeyboardAdjustObjectPosition")
		scriptSystem:RemoveAutoCall("UpdateTextBoxToObjectName")
        scriptSystem:RemoveAutoCall("AdjustObjectPosition")
	end

end


function ObjectSelectorClassChange(guiArgs)

	local objectType = GetNaviMultiValue(guiArgs, "ClassType")
	newClassType = objectType:str()

end


function ObjectSelectorProfileChange(guiArgs)

	local objectProfiles = GetNaviMultiValue(guiArgs, "Profiles")
	local tableProfiles = WUtil_StringSplit(";", objectProfiles:str())
	newObjectProfiles = Parameters()
	local index = 1
	while index < #tableProfiles do
		newObjectProfiles:AddParameter(Parameter(tableProfiles[index], StringToParamType("STRING"), ""))
		index = index + 1
	end
	
end


function SpawnObjectAtPosition(position)

	local console = GetConsole()
	if newObjectName == nil or string.len(newObjectName) == 0 then

		console:Print("No name set for object when trying to spawn object")
		return

	end

	if newObjectProfile == nil or string.len(newObjectProfile) == 0 then

		console:Print("No profile set for object when trying to spawn object: " .. newObjectName)
		return

	end

	local foundObjectWithName = GetObjectSystem():GetObjectByName(newObjectName, false)
	if foundObjectWithName.__ok then

		console:Print("Object with name " .. newObjectName .. " already in the Map")

	else

		local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
		if mapEditor.__ok then

			local params = Parameters()
			local paramData = FloatToString(position.x)
			params:AddParameter(Parameter("PositionX", StringToParamType("FLOAT"), paramData))
			paramData = FloatToString(position.y)
			params:AddParameter(Parameter("PositionY", StringToParamType("FLOAT"), paramData))
			paramData = FloatToString(position.z)
			params:AddParameter(Parameter("PositionZ", StringToParamType("FLOAT"), paramData))
			--Client is the intended profile, since this code is only ever called from the Client
			mapEditor:SpawnObject("Client", newObjectName, newClassType, newObjectProfile, params)

			--Highlight this newly spawned object
			local indicatorObject = mapEditor:GetIndicatorFromObjectName(newObjectName)
			--First Un-Highlight all indicators
			HighlightAllIndicators(false)
			--Now Highlight the new indicator
			indicatorObject:Highlight(true)

			AddObjectToGUI(newObjectName)
			return

		else

			console:Print("Could not find MapEditor object in system. Name should be MapEditor")

		end

	end

end

function KeyboardAdjustObjectPosition(keyEvent)
	-- KEY CODES
	-- UP = 200
	-- DOWN = 208
	-- LEFT = 203
	-- RIGHT = 205

	-- UP
	if keyEvent:KeyPressed() and keyEvent:GetKey() == 200 then
        upPressed = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == 200 then
        upPressed = false
	
	-- DOWN
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == 208 then
	    downPressed = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == 208 then
        downPressed = false
	
	-- RIGHT
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == 205 then
	    rightPressed = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == 205 then
        rightPressed = false
	
	--LEFT
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == 203 then
	    leftPressed = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == 203 then
        leftPressed = false
    
    -- Y
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == StringToKeyCode("y", false) then
	    constrainXAxis = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == StringToKeyCode("y", false) then
        constrainXAxis = false	

    -- U
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == StringToKeyCode("u", false) then
	    constrainYAxis = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == StringToKeyCode("u", false) then
        constrainYAxis = false

    -- I
	elseif keyEvent:KeyPressed() and keyEvent:GetKey() == StringToKeyCode("i", false) then
	    constrainZAxis = true
    elseif keyEvent:KeyReleased() and keyEvent:GetKey() == StringToKeyCode("i", false) then
        constrainZAxis = false

	end
end

function PlaceNewObject(mouseEvent)

	--Check if mouse is over a navi window
	if GetNaviGUISystem():IsMouseOverPage() then
		return
	end

	local console = GetConsole()

	if objectSelectorEnabled == false then
		return
	end

	local buttonID = StringToMouseButtonID("MB_Left")
	--Check if the user pressed the left mouse button
	if mouseEvent:MouseButtonPressed() and mouseEvent:GetMouseButton() == buttonID then

		local mousePosX = mouseEvent:GetMousePositionX()
		local mousePosY = mouseEvent:GetMousePositionY()

		--passed in true as last param to GetObjectFromScreen to specify a precise (polygon level) cast
		rcResult = GetRayCastSystem():GetObjectFromScreen(mousePosX, mousePosY, true)

		if rcResult:IsObjectHit() then
			local objectName = rcResult:GetIOGREObject():GetName()
			if objectName == "MapEditor" then

				local entityName = rcResult:GetEntityName()

				--Check if it is an axis widget
				if string.find(entityName, "AxisWidget") ~= nil then
					if string.find(entityName, "XPOS") ~= nil then
						--console:Print("Hit AxisWidget X Positive")
						constrainXAxis = true
					elseif string.find(entityName, "XNEG") ~= nil then
						--console:Print("Hit AxisWidget X Negative")
						constrainXAxis = true
					elseif string.find(entityName, "YPOS") ~= nil then
						--console:Print("Hit AxisWidget Y Positive")
						constrainYAxis = true
					elseif string.find(entityName, "YNEG") ~= nil then
						--console:Print("Hit AxisWidget Y Negative")
						constrainYAxis = true
					elseif string.find(entityName, "ZPOS") ~= nil then
						--console:Print("Hit AxisWidget Z Positive")
						constrainZAxis = true
					elseif string.find(entityName, "ZNEG") ~= nil then
						--console:Print("Hit AxisWidget Z Negative")
						constrainZAxis = true
					end
				else
					console:Print("Hit Map Editor Indicator: " .. rcResult:GetEntityName())
					--Find this entity in the editor and get it's object's name
					local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
					if mapEditor.__ok then
						local indicatorObject = mapEditor:GetIndicatorFromEntityName(entityName)

						if indicatorObject.__ok then
							--Select the indicated object in the GUI
							NewCurrentObjectSelected(indicatorObject:GetObjectName())
						else
							GetConsole():Print("Error while trying to GetIndicatorFromEntityName() in the map editor for " .. entityName)
						end
					end
				end

			else

				console:Print("Hit Object: " .. rcResult:GetIOGREObject():GetName())

			end

		elseif rcResult:IsWorldHit() then
			--The user clicked somewhere in the map, so un-highlight any object they had highlighted before
			HighlightAllIndicators(false)
			local hitPosition = rcResult:GetPosition()
			SpawnObjectAtPosition(hitPosition)
		else
			console:Print("Hit Nothing but the void where your soulless heart once dwelled")
		end

	--Check if the user released the left mouse button
	elseif mouseEvent:MouseButtonReleased() and mouseEvent:GetMouseButton() == buttonID then

		constrainXAxis = false
		constrainYAxis = false
		constrainZAxis = false

	--Check if the user moved the mouse
	elseif mouseEvent:MouseMoved() then

		local currMousePosX = mouseEvent:GetMousePositionX()
		local currMousePosY = mouseEvent:GetMousePositionY()
		local mouseDiffX = (lastMousePosX - currMousePosX) * 10
		local mouseDiffY = (lastMousePosY - currMousePosY) * 10

		local axisContrained = false
		if constrainXAxis then
			GetConsole():Print("constrainXAxis!")
			axisContrained = true
			local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
			if currentObject.__ok then
				local ogreObject = ToIOGREObject(currentObject)
				if ogreObject.__ok then
					local newX = ogreObject:GetPosition():GetX() + mouseDiffX
					local newY = ogreObject:GetPosition():GetY()
					local newZ = ogreObject:GetPosition():GetZ()
					ogreObject:SetPosition(WVector3(newX, newY, newZ))
				end
			end

		elseif constrainYAxis then
			GetConsole():Print("constrainYAxis!")
			axisContrained = true
			local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
			if currentObject.__ok then
				local ogreObject = ToIOGREObject(currentObject)
				if ogreObject.__ok then
					local newX = ogreObject:GetPosition():GetX()
					local newY = ogreObject:GetPosition():GetY() + mouseDiffY
					local newZ = ogreObject:GetPosition():GetZ()
					ogreObject:SetPosition(WVector3(newX, newY, newZ))
				end
			end

		elseif constrainZAxis then
			GetConsole():Print("constrainZAxis!")
			axisContrained = true
			local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
			if currentObject.__ok then
				local ogreObject = ToIOGREObject(currentObject)
				if ogreObject.__ok then
					local newX = ogreObject:GetPosition():GetX()
					local newY = ogreObject:GetPosition():GetY()
					local newZ = ogreObject:GetPosition():GetZ() + mouseDiffX
					ogreObject:SetPosition(WVector3(newX, newY, newZ))
				end
			end
		end

		if axisContrained then
			UpdateObjectEditorDisplay()
		end

		lastMousePosX = currMousePosX
		lastMousePosY = currMousePosY

	end

end


function MapLoadedAddObjectsToGUI()

	--First clear the GUI list
	local jsCode = "JS_ClearObjectList();"
	GetNaviGUISystem():GetPage("selector", true):EvaluateJS(jsCode);

	--And clear the Object Parameter Editor GUI
	jsCode = "document.forms[1].innerHTML = '<fieldset><legend>Object Editor</legend></fieldset>'"
	GetNaviGUISystem():GetPage("selector", true):EvaluateJS(jsCode);

	--Now add all the objects in the map to the GUI list
	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		allObjectNames = mapEditor:GetObjectNames()
		--Add each of the object names to the GUI
		i = 0
		while i < allObjectNames:GetNumberOfParameters() do
			currentObjectName = allObjectNames:GetParameterAtIndex(i, true)
			AddObjectToGUI(currentObjectName:GetName())
			i = i + 1
		end
	end

end


function AddObjectToGUI(objectName)

	local jsCode = "JS_AddObjectToList('" .. objectName .. "');"
	GetNaviGUISystem():GetPage("selector", true):EvaluateJS(jsCode);

end


function UpdateTextBoxToObjectName(timePassed)

	local jsCode = "document.forms[0].ObjectName.value"
	newObjectName = GetNaviGUISystem():GetPage("selector", true):EvaluateJS(jsCode)

end


--BRIAN TODO: This needs to be moved somewhere else, too specific
function AdjustObjectPosition(timePassed)
    
	-- Check which keys are down
    if constrainXAxis then
        local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
        if currentObject.__ok then
            local OgreObject = ToIOGREObject(currentObject)
            if OgreObject.__ok then
                if (upPressed) then
                    local newX = OgreObject:GetPosition():GetX() + timePassed
                    local newY = OgreObject:GetPosition():GetY() 
                    local newZ = OgreObject:GetPosition():GetZ() 
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                elseif (downPressed) then
                    local newX = OgreObject:GetPosition():GetX() - timePassed
                    local newY = OgreObject:GetPosition():GetY() 
                    local newZ = OgreObject:GetPosition():GetZ() 
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                end
            end
        end

    elseif constrainYAxis then
        local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
        if currentObject.__ok then
            local OgreObject = ToIOGREObject(currentObject)
            if OgreObject.__ok then 
                if (upPressed) then
                    local newX = OgreObject:GetPosition():GetX()
                    local newY = OgreObject:GetPosition():GetY() + timePassed
                    local newZ = OgreObject:GetPosition():GetZ() 
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                elseif (downPressed) then
                    local newX = OgreObject:GetPosition():GetX()
                    local newY = OgreObject:GetPosition():GetY() - timePassed
                    local newZ = OgreObject:GetPosition():GetZ() 
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                end
            end
        end

    elseif constrainZAxis then
        local currentObject = GetObjectSystem():GetObjectByName(currentlySelectedObjectName, false)
        if currentObject.__ok then
            local OgreObject = ToIOGREObject(currentObject)
            if OgreObject.__ok then 
                if (upPressed) then
                    local newX = OgreObject:GetPosition():GetX()
                    local newY = OgreObject:GetPosition():GetY()
                    local newZ = OgreObject:GetPosition():GetZ() + timePassed
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                elseif (downPressed) then
                    local newX = OgreObject:GetPosition():GetX()
                    local newY = OgreObject:GetPosition():GetY()
                    local newZ = OgreObject:GetPosition():GetZ() - timePassed
                    OgreObject:SetPosition(WVector3(newX, newY, newZ))
                    objectMoved = true
                end
            end
        end

    end

    if objectMoved then
        UpdateObjectEditorDisplay()
        objectMoved = false
    end

end


--Updates the on screen display fields for the parameters of the currently selected object (ObjectCreator)
function UpdateObjectEditorDisplay()

	local jsCode = nil
	htmlHeader = "document.forms[1].innerHTML = '<fieldset><legend>Object Editor</legend>"
	htmlFooter = "<br><input name=\"SubmitChanges\" type=\"button\" value=\"Submit Changes\" onclick=\"JS_SubmitObjectChanges();\"/></fieldset>';"

	--Now that we have the object name, lets get the actual object
	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		local selectedObject = mapEditor:GetMapObject(currentlySelectedObjectName)
		if selectedObject.__ok then

			local paramList = ""
			local selectedObjectParameters = selectedObject:GetParameters()
			i = 0
			while i < selectedObjectParameters:GetNumberOfParameters() do
				local currentParam = selectedObjectParameters:GetParameterAtIndex(i, true)

				--This sets up the html to create a text box for this item in this format
				--<label>Object Name<input type="text" name="ObjectNameText" id="ObjectNameID" value="1.0"/></label>

				paramList = paramList .. "<br><label>" .. currentParam:GetName() .. "<input type=\"text\" name=\"" 
				paramList = paramList .. currentParam:GetName() .. "\" id=\"" .. currentParam:GetName() .. "ID\" value=\"" .. currentParam:GetStringData() .. "\"/></label>"
				i = i + 1
			end
			jsCode = htmlHeader .. "<p><b>" .. currentlySelectedObjectName .. " Parameters:</b></p>" .. paramList .. htmlFooter

		else

			jsCode = htmlHeader .. "<p><b>" .. "Could not find object: " .. currentlySelectedObjectName .. " in map</b></p>" .. htmlFooter

		end

		jsCode = jsCode .. "JS_ForceObjectSelection('" .. currentlySelectedObjectName .. "');"
		GetNaviGUISystem():GetPage("selector", true):EvaluateJS(jsCode)
	end

end


function NewCurrentObjectSelectedFromGUI(guiArgs)

	local objectNameValue = GetNaviMultiValue(guiArgs, "ObjectName")
	currentlySelectedObjectName = objectNameValue:str()
	--Call the Lua function to complete the request
	NewCurrentObjectSelected(currentlySelectedObjectName)

end


--This is called when a new object is selected in the object selector or map editor
function NewCurrentObjectSelected(newCurrentlySelectedObjectName)

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		currentlySelectedObjectName = newCurrentlySelectedObjectName
		SelectPathPoint(newCurrentlySelectedObjectName)
		UpdateObjectEditorDisplay()

		local indicatorObject = mapEditor:GetIndicatorFromObjectName(newCurrentlySelectedObjectName)
		--First Un-Highlight all indicators
		HighlightAllIndicators(false)
		--Now Highlight the selected indicator
		indicatorObject:Highlight(true)
		GetNaviGUISystem():DeFocusAllPages()
	end

end


--This is called for each parameter of the currently selected object
function SetParamOfObjectSelected(guiArgs)

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		selectedObject = mapEditor:GetMapObject(currentlySelectedObjectName)
		if selectedObject.__ok then

			paramNameValue = GetNaviMultiValue(guiArgs, "ParamName")
			paramName = paramNameValue:str()
			
			paramValueValue = GetNaviMultiValue(guiArgs, "ParamValue")
			paramValue = paramValueValue:str()
			
			selectedObject:SetParameter(Parameter(paramName, StringToParamType("STRING"), paramValue))

		else

			GetConsole():Print("Could not find object: " .. currentlySelectedObjectName .. " in map when trying to set a parameter")

		end
	end

end


function InitObjectSelected(guiArgs)

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		selectedObject = mapEditor:GetMapObject(currentlySelectedObjectName)
		if selectedObject.__ok then
			selectedObject:Init()
		end
	end

end


function DeleteActiveObjectFromMapEditor(guiArgs)

	local objectNameValue = GetNaviMultiValue(guiArgs, "ObjectName")
	local activeObjectName = objectNameValue:str()

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then

		mapEditor:RemoveObject(activeObjectName)

	end

end


function HighlightAllIndicators(shouldHighlight)
	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then

		i = 0
		while i < mapEditor:GetNumberOfIndicators() do
			local indicator = mapEditor:GetIndicatorObjectAtIndex(i, true)
			indicator:Highlight(shouldHighlight)
			i = i + 1
		end

	end
end


function ToggleIndicators(guiArgs)

	if indicatorsVisible == true then
		HideMapEditorIndicators()
		indicatorsVisible = false
		HighlightAllIndicators(false)
	else
		ShowMapEditorIndicators()
		indicatorsVisible = true
	end

end


function ShowMapEditorIndicators()

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		mapEditor:ShowIndicators()
	end

end


function HideMapEditorIndicators()

	local mapEditor = ToMapEditor(GetObjectSystem():GetObjectByName("MapEditor", false))
	if mapEditor.__ok then
		mapEditor:HideIndicators()
	end

end