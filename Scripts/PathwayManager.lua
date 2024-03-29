local currentlySelectedPathway = ""
local batchRenderer = BatchRenderer()
local pathwayManagerEnabled = false

local PlayerCam = nil
local movingDownPath = false
local curPointIndex = 0
local timeOnPoint = 0
local pathwayObject = nil
local PathDoneFunc = nil
local percentDone = 0
local drawPathsEnabled = true

function InitializePathwayManagerUI(guiArgs)

	local jsCode = "JS_ClearPathwayList(); JS_ClearAllPathPointsList();"
	GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)

	--Go find all the Pathways in the system and add them to the list
	local i = 0
	numObjects = GetObjectSystem():GetNumberOfObjects()
	while i < numObjects do
		local currentObject = GetObjectSystem():GetObjectAtIndex(i, true)
		--Make sure this object is a Pathway
		local pathwayObject = ToPathway(currentObject)

		if pathwayObject.__ok then
			jsCode = "JS_AddPathway('" .. pathwayObject:GetName() .. "');"
			GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)
		end

		i = i + 1
	end

	--Go find all the PathPoints in the system and add them to the list
	i = 0
	numObjects = GetObjectSystem():GetNumberOfObjects()
	while i < numObjects do
		local currentObject = GetObjectSystem():GetObjectAtIndex(i, true)
		--Make sure this object is a PathPoint
		local pathPointObject = ToPathPoint(currentObject)

		if pathPointObject.__ok then
			jsCode = "JS_AddToAllPathPointsList('" .. pathPointObject:GetName() .. "');"
			GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)
		end

		i = i + 1
	end

	-- Get reference to the playerCam
	PlayerCam = GetObjectSystem():GetObjectByName("PlayerCam", true)

	if PlayerCam.__ok then
		PlayerCam = ToWCamera(PlayerCam)
	end

	if not GetScriptSystem():DoesAutoCallExist("FollowPath") then
		GetScriptSystem():AddAutoCall("FollowPath")
	end

end


function PathwayManagerEnabled(guiArgs)

	local enabled = GetNaviMultiValue(guiArgs, "Enabled")
	pathwayManagerEnabled = enabled:toBool()

	if pathwayManagerEnabled then
		if not GetScriptSystem():DoesAutoCallExist("DrawPathwayLines") then
			GetScriptSystem():AddAutoCall("DrawPathwayLines")
		end
	else
		batchRenderer:Clear()
		if GetScriptSystem():DoesAutoCallExist("DrawPathwayLines") then
			GetScriptSystem():RemoveAutoCall("DrawPathwayLines")
		end
	end

end


function StartFollowingPath(doneFunction)

	PathDoneFunc = doneFunction
	pathwayObject:GeneratePointTimes()
	movingDownPath = true

end


function StopFollowingPath()

	movingDownPath = false
	if PathDoneFunc ~= nil then
		PathDoneFunc()
	end

end


function ResetPath()

	curPointIndex = 0

	if pathwayObject:GetNumberOfPathPoints() > 0 then
		PlayerCam:SetPosition(pathwayObject:GetPathPointAtIndex(curPointIndex, true):GetPosition())
	end

end


function FollowPath(timePassed)

	if movingDownPath then

		if pathwayObject:GetNumberOfPathPoints() <= 0 then
		
			GetConsole:Print("There are no points set in this Pathway")
			return
		end

		if curPointIndex == pathwayObject:GetNumberOfPathPoints() - 2  or percentDone >= 1 then

			StopFollowingPath()
            percentDone = 0
		else

			percentDone = MoveTowardsNextPoint(timePassed)
            if(percentDone < 1) then
			    InterpolateLookAtPoint(percentDone)
            end
		end
	end

end


function MoveTowardsNextPoint(timePassed)

	-- Make sure that there are some points in the pathway
	if pathwayObject:GetNumberOfPathPoints() <= 0 then

		GetConsole:Print("There are no points set in this Pathway")
		return
	end

	-- check if we have reached the destination point if we have, move to next point.
	timeOnPoint = timeOnPoint + timePassed
	
	if pathwayObject:UsePathwayTime() then
		if timeOnPoint >= pathwayObject:GetPointTime(curPointIndex, false) then
		
			timeOnPoint = 0
			curPointIndex = curPointIndex + 1
		end
	else
		if timeOnPoint >= pathwayObject:GetPathPointAtIndex(curPointIndex, true):GetTime() then
		
			timeOnPoint = 0
			curPointIndex = curPointIndex + 1
		end
	end

	local indexOfLastTravelPoint = pathwayObject:GetNumberOfPathPoints() - 2
    if curPointIndex < indexOfLastTravelPoint then
        -- calculate the movePercent based on the amount of time 
        local movePercent
        if pathwayObject:UsePathwayTime() then
            movePercent = timeOnPoint / pathwayObject:GetPointTime(curPointIndex, false)
        else
            movePercent = timeOnPoint / pathwayObject:GetPathPointAtIndex(curPointIndex, true):GetTime()
        end

        local newCamPosition = FindPoints(movePercent, pathwayObject, curPointIndex)
        PlayerCam:SetPosition(newCamPosition)

	    return movePercent
    end

    -- If we have reached the final travel point then return 1 for 100% done
    return 1

end


-- percentDone = the current percentage completed between this point and the next
-- curPathway = the current pathway object
-- index = the index of the point you want to use as the current point.  Look at points will be one point ahead of position points
-- returns a WVector3 that represents either the new position or the new look at point
function FindPoints(percentDone, curPathway, index)

	local numPathPoints = curPathway:GetNumberOfPathPoints()

	-- Make sure that there are some points in the pathway
	if curPathway:GetNumberOfPathPoints() <= 0 then
		GetConsole:Print("There are no points set in Pathway " .. curPathway:GetName())
		return
	end

	local selectPoint = index - 1
	if selectPoint < 0 then
		selectPoint = 0
	end
	local prevPoint = curPathway:GetPathPointAtIndex(selectPoint, true):GetPosition()

	selectPoint = index
	if selectPoint >= numPathPoints then
		selectPoint = numPathPoints - 1
	end
	local curPoint = curPathway:GetPathPointAtIndex(selectPoint, true):GetPosition()

	selectPoint = index + 1
	if selectPoint >= numPathPoints then
		selectPoint = numPathPoints - 1
	end
	local nextPoint = curPathway:GetPathPointAtIndex(selectPoint, true):GetPosition()

	selectPoint = index + 2
	if selectPoint >= numPathPoints then
		selectPoint = numPathPoints - 1
	end
	local pointAfterNext = curPathway:GetPathPointAtIndex(selectPoint, true):GetPosition()

	--Handle Ease
	--if (index == 0) or (index == numPathPoints - 2) then
	--	percentDone = Ease(percentDone, 0, 1)
	--end

	local outPosition = WVector3(0, 0, 0)
	PointOnCurve(outPosition, percentDone, prevPoint, curPoint, nextPoint, pointAfterNext)
	return outPosition

end


function InterpolateLookAtPoint(percentDone)

	-- called with curPointIndex + 1 because we are interpreting look at point
	local newLookAt = FindPoints(percentDone, pathwayObject, curPointIndex + 1)
	PlayerCam:GetLookAt():SetPosition(newLookAt)

end


function NewCurrentPathwaySelectedFromGUI(guiArgs)

	local pathwayNameValue = GetNaviMultiValue(guiArgs, "PathwayName")
	local newPathway = pathwayNameValue:str()
	--Call the Lua function to complete the request
	NewCurrentPathwaySelected(newPathway)

end


function NewCurrentPathwaySelected(newPathway)

	currentlySelectedPathway = newPathway
	local object = GetObjectSystem():GetObjectByName(currentlySelectedPathway, true)
	pathwayObject = ToPathway(object)

	--ReInit the current path point list and add the correct points for this pathway
	local jsCode = "JS_ClearCurrentPathPointsList();"
	GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)

	--Validate the points in this path are active
	pathwayObject:ValidatePoints()
	local i = 0
	local numPoints = pathwayObject:GetNumberOfPathPoints()
	while i < numPoints do
		local currentPoint = pathwayObject:GetPathPointAtIndex(i, true)

		if currentPoint.__ok then
			jsCode = "JS_AddToCurrentPathPointsList('" .. currentPoint:GetName() .. "');"
			GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)
		end

		i = i + 1
	end

end


function RunPathway(guiArgs)

	ResetPath()
	StartFollowingPath()

end


function ToggleDrawPaths(guiArgs)

	if drawPathsEnabled then
		drawPathsEnabled = false
		batchRenderer:Clear()
		if GetScriptSystem():DoesAutoCallExist("DrawPathwayLines") then
			GetScriptSystem():RemoveAutoCall("DrawPathwayLines")
		end
	else
		drawPathsEnabled = true
		if not GetScriptSystem():DoesAutoCallExist("DrawPathwayLines") then
			GetScriptSystem():AddAutoCall("DrawPathwayLines")
		end
	end

end


function AddPathPoint(guiArgs)

	local pathPointNameValue = GetNaviMultiValue(guiArgs, "PathPointName")
	local pathPointName = pathPointNameValue:str()

	if string.len(currentlySelectedPathway) == 0 then
		GetConsole():Print("No Pathway selected when trying to Add a PathPoint")
		return
	end

	local object = GetObjectSystem():GetObjectByName(currentlySelectedPathway, true)
	local pathwayObject = ToPathway(object)

	if pathwayObject.__ok then
		object = GetObjectSystem():GetObjectByName(pathPointName, true)
		pathPointObject = ToPathPoint(object)
		if pathPointObject.__ok then
			pathwayObject:AddPathPoint(pathPointObject)
			pathwayObject:GeneratePointTimes()
		end
	end
end


function RemovePathPoint(guiArgs)

	local pathPointNameValue = GetNaviMultiValue(guiArgs, "PathPointName")
	local pathPointName = pathPointNameValue:str()

	local pathwayNameValue = GetNaviMultiValue(guiArgs, "PathwayName")
	local pathwayName = pathwayNameValue:str()
	if string.len(pathwayName) == 0 then
		GetConsole():Print("No Pathway selected when trying to Remove a PathPoint")
		return
	end

	local object = GetObjectSystem():GetObjectByName(pathwayName, true)
	local pathwayObject = ToPathway(object)
	if pathwayObject.__ok then
		object = GetObjectSystem():GetObjectByName(pathPointName, true)
		pathPointObject = ToPathPoint(object)
		if pathPointObject.__ok then
			pathwayObject:RemovePathPoint(pathPointObject)
			pathwayObject:GeneratePointTimes()
		end
	end
end


function SelectPathPoint(pathPointName)

	local jsCode = "JS_ForceAllPathPointSelection('" .. pathPointName .. "');"
	jsCode = jsCode .. "JS_ForceCurrentPathPointSelection('" .. pathPointName .. "');"
	GetNaviGUISystem():GetPage("pathwayManager", true):EvaluateJS(jsCode)
	GetNaviGUISystem():DeFocusAllPages()
end


function DrawPathwayLines(timePassed)

	if not pathwayManagerEnabled then
		return
	end

	local object = GetObjectSystem():GetObjectByName(currentlySelectedPathway, false)
	if object.__ok then
		local pathwayObject = ToPathway(object)

		if pathwayObject.__ok then
			local i = 0
			-- Using the second to last point as the last point that the camera gets to
			local numPoints = pathwayObject:GetNumberOfPathPoints() - 1
			while i < numPoints do

				local fromPosition = pathwayObject:GetPathPointAtIndex(i, true):GetPosition()
				local fromPoint = WVector3(fromPosition:GetX(), fromPosition:GetY(), fromPosition:GetZ())
				local toPoint = WVector3(0, 0, 0)
				local percent = 0.1
				while percent < 1 or percent == 1 do
					toPoint = FindPoints(percent, pathwayObject, i)
					if (toPoint.__ok) then
						batchRenderer:AddLine(fromPoint:GetX(), fromPoint:GetY(), fromPoint:GetZ(), toPoint:GetX(), toPoint:GetY(), toPoint:GetZ())
						fromPoint:SetX(toPoint:GetX())
						fromPoint:SetY(toPoint:GetY())
						fromPoint:SetZ(toPoint:GetZ())
					end
					percent = percent + 0.1
				end

				i = i + 1
			end
		end

		batchRenderer:Draw()
	end
end