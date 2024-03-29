UseModule("IScriptObject", "Scripts/")

--PATHMOVER CLASS START

--PathMover
class 'PathMover' (IScriptObject)

function PathMover:__init() super()

	self.name = "DefaultPathMoverName"
	self.ID = 0
	self.object = nil
	self.serverObject = ""
	self.clientObject = ""
	self.pathPoints = { }
	self.currParsePathPoint = 1
	self.currPathPoint = 1
	self.offsetTime = 0
	self.resetCount = 0
	self.stateParam = Parameter()

end


function PathMover:BuildInterfaceDefIScriptObject()

	self:AddClassDef("PathMover", "IScriptObject", "Defines a path mover which can move another object along a path based on synced network time")

end


function PathMover:GetActive()

    --PathMover never actually synced over the network
    return false

end


function PathMover:SetName(setName)

	self.name = setName

end


function PathMover:GetName()

	return self.name

end


function PathMover:SetID(setID)

	self.ID = setID

end


function PathMover:GetID()

	return self.ID

end


function PathMover:SetOffsetTime(setTime)

    self.offsetTime = setTime
    if IsServer() then
        self.stateParam:SetFloatData(self.offsetTime)
        GetServerSystem():GetSendStateTable("Map"):SetState(self.offsetTimeName, self.stateParam)
    end

end


function PathMover:OffsetTimeSlot(params)

    local setOffsetTime = params:GetParameterAtIndex(0, true):GetFloatData()
    self:SetOffsetTime(setOffsetTime)

end


function PathMover:GetOffsetTime()

    return self.offsetTime

end


function PathMover:InitIBase()

    self:InitState()

end


function PathMover:UnInitIBase()

    self:UnInitState()

end


function PathMover:InitState()

    self.offsetTimeName = self:GetName() .. "OffsetTime"
    self.resetCountName = self:GetName() .. "ResetCount"
    if IsServer() then
        GetServerSystem():GetSendStateTable("Map"):NewState(self.offsetTimeName)
        self.stateParam:SetFloatData(self.offsetTime)
        GetServerSystem():GetSendStateTable("Map"):SetState(self.offsetTimeName, self.stateParam)

        GetServerSystem():GetSendStateTable("Map"):NewState(self.resetCountName)
        self.stateParam:SetIntData(self.resetCount)
        GetServerSystem():GetSendStateTable("Map"):SetState(self.resetCountName, self.stateParam)
    else
        self.offsetTimeSlot = self:CreateSlot("OffsetTimeSlot", "OffsetTimeSlot")
	    GetClientSystem():GetReceiveStateTable("Map"):WatchState(self.offsetTimeName, self.offsetTimeSlot)
        self.resetCountSlot = self:CreateSlot("ResetCountSlot", "ResetCountSlot")
	    GetClientSystem():GetReceiveStateTable("Map"):WatchState(self.resetCountName, self.resetCountSlot)
    end

end


function PathMover:UnInitState()

    if IsServer() then
        GetServerSystem():GetSendStateTable("Map"):RemoveState(self.offsetTimeName)
        GetServerSystem():GetSendStateTable("Map"):RemoveState(self.resetCountName)
    end

end


function PathMover:InitObject(objName)

    local objIter = GetNetworkedWorld():GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetName() == objName then
			local transformObject = ToWTransform(worldObject)
			if IsValid(transformObject) then
			    self.object = transformObject
			    break
			end
		end
		objIter:Next()
	end

end


function PathMover:DoesOwn(ownObjectID)

	return false

end


--Reset the object following this path to the start of the path
function PathMover:ResetPathObject()

    self.currPathPoint = 1
    if #self.pathPoints > 0 then
        self.object:SetPosition(self.pathPoints[1].position)
    end
    if IsServer() then
        self.resetCount = self.resetCount + 1
        self.stateParam:SetIntData(self.resetCount)
        GetServerSystem():GetSendStateTable("Map"):SetState(self.resetCountName, self.stateParam)
    end

end


function PathMover:ResetCountSlot(params)

    self.resetCount = params:GetParameter(0, true):GetIntData()
    self:ResetPathObject()

end


function PathMover:ProcessScriptObject(frameTime)

    if not IsValid(self.object) then
        return
    end

    --an offsetTime of less than 0 indicates we shouldn't even process the path
    if self.offsetTime >= 0 then
        self:ProcessPath()
    end

end


function PathMover:ProcessPath()

    --Make sure we aren't at the end of the path
    if self.currPathPoint + 1 <= #self.pathPoints then
        local currTime = GetNetworkSystem():GetTime()
        if currTime > self.pathPoints[self.currPathPoint].moveDelay + self.offsetTime then
            local pathPointStartTime = self:GetPathPointStartTime(self.currPathPoint) + self.offsetTime
            --Do not add the offset below as this is just supposed to be the start plus however long
            --the object should move for to get to the next point
            local pathPointEndTime = pathPointStartTime + self.pathPoints[self.currPathPoint].moveTime
            local lerpAmount = (currTime - pathPointStartTime) / (pathPointEndTime - pathPointStartTime)
            if lerpAmount > 1 then
                --Manually set to the end just in case this is the last point
                self.object:SetPosition(self.pathPoints[self.currPathPoint + 1].position)
                self.currPathPoint = self.currPathPoint + 1
                --This will cause the correct position past the last node to be computed
                self:ProcessPath()
            else
                local newPos = WVector3Lerp(lerpAmount, self.pathPoints[self.currPathPoint].position, self.pathPoints[self.currPathPoint + 1].position)
                self.object:SetPosition(newPos)
            end
        end
    end

end


function PathMover:GetPathPointStartTime(pathPointIndex)

    local startTime = 0
    for index, pathPoint in ipairs(self.pathPoints) do
        startTime = startTime + pathPoint.moveDelay
        if index == pathPointIndex then
            break
        else
            startTime = startTime + pathPoint.moveTime
        end
    end
    return startTime

end


function PathMover:SetParameter(param)
 
	if param:GetName() == "ServerObject" then
	    self.serverObject = param:GetStringData()
	    if IsServer() then
		    self:InitObject(self.serverObject)
		end
	elseif param:GetName() == "ClientObject" then
	    self.clientObject = param:GetStringData()
	    if IsClient() then
		    self:InitObject(self.clientObject)
		end
	elseif param:GetName() == "PathPointMoveDelay" then
		self.pathPoints[self.currParsePathPoint] = { }
		self.pathPoints[self.currParsePathPoint].moveDelay = param:GetFloatData()
		self.pathPoints[self.currParsePathPoint].moveTime = 0
		self.pathPoints[self.currParsePathPoint].position = WVector3()
		self.pathPoints[self.currParsePathPoint].orientation = WVector3()
	elseif param:GetName() == "PathPointMoveTime" then
	    if not IsValid(self.pathPoints[self.currParsePathPoint]) then
	        error("PathPointMoveDelay must come before PathPointMoveTime in a PathMover")
	    end
		self.pathPoints[self.currParsePathPoint].moveTime = param:GetFloatData()
	elseif param:GetName() == "PathPointPos" then
	    if not IsValid(self.pathPoints[self.currParsePathPoint]) then
	        error("PathPointMoveDelay must come before PathPointPos in a PathMover")
	    end
		self.pathPoints[self.currParsePathPoint].position = param:GetWVector3Data()
	elseif param:GetName() == "PathPointOrien" then
	    if not IsValid(self.pathPoints[self.currParsePathPoint]) then
	        error("PathPointMoveDelay must come before PathPointOrien in a PathMover")
	    end
		self.pathPoints[self.currParsePathPoint].orientation = param:GetWVector3Data()
		self.currParsePathPoint = self.currParsePathPoint + 1
	end

end


function PathMover:EnumerateParameters(params)

	params:AddParameter(Parameter("ServerObject", self.serverObject))
	params:AddParameter(Parameter("ClientObject", self.clientObject))
	for index, pathPoint in ipairs(self.pathPoints) do
	    params:AddParameter(Parameter("PathPointMoveDelay", Parameter.FLOAT, pathPoint.moveDelay))
	    params:AddParameter(Parameter("PathPointMoveTime", Parameter.FLOAT, pathPoint.moveTime))
	    params:AddParameter(Parameter("PathPointPos", Parameter.WVECTOR3, pathPoint.position))
	    params:AddParameter(Parameter("PathPointOrien", Parameter.WVECTOR3, pathPoint.orientation))
	end

end

--PathMover CLASS END