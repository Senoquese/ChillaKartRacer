UseModule("IBase", "Scripts/")

--SOCCERCOLLISIONMANAGER CLASS START

--The SoccerCollisionManager manages the collisions between the balls and goals
class 'SoccerCollisionManager' (IBase)

function SoccerCollisionManager:__init(map) super()

	self.map = map
	self.soccerGoals = { }
	self.soccerBalls = { }

	self.objectEnterSlot = self:CreateSlot("ObjectEnterSoccerGoal", "ObjectEnterSoccerGoal")

	--This is emitted when a goal is scored
	self.goalScored = self:CreateSignal("GoalScored")
	self.goalScoredParams = Parameters()

	self:_InitSoccerGoals()
	self:_InitSoccerBalls()

end


function SoccerCollisionManager:BuildInterfaceDefIBase()

	self:AddClassDef("SoccerCollisionManager", "IBase", "Tracks collisions for soccer mode")

end


function SoccerCollisionManager:InitIBase()

end


function SoccerCollisionManager:UnInitIBase()

	self:_UnInitSoccerGoals()
	self:_UnInitSoccerBalls()

end


function SoccerCollisionManager:GetGoalByIndex(index)
    
    if index > 0 and index <= #self.soccerGoals then
        return self.soccerGoals[index]
    else
        return nil
    end
    
end


function SoccerCollisionManager:_InitSoccerGoals()

	--Find all the soccer goals in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "ScriptObject" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "SoccerGoal" then
				table.insert(self.soccerGoals, scriptObject)
				scriptObject:GetSignal("ObjectEnterSoccerGoal", true):Connect(self.objectEnterSlot)
			end
		end
		mapObjectIter:Next()
	end

end


function SoccerCollisionManager:_UnInitSoccerGoals()

	self.soccerGoals = { }

end


function SoccerCollisionManager:_InitSoccerBalls()

	--Find all the soccer balls in the map
	local mapObjectIter = self.map:GetMapObjectIterator()
	while not mapObjectIter:IsEnd() do
		local currentMapObject = mapObjectIter:Get()
		if currentMapObject:GetTypeName() == "SyncedBall" and IsValid(currentMapObject:Get()) then
			local scriptObject = ToScriptObject(currentMapObject:Get())
			if scriptObject:GetScriptObjectTypeName() == "SyncedBall" then
				--Insert the ball and the initial position
				table.insert(self.soccerBalls, { scriptObject, WVector3(scriptObject:GetPosition()) })
			end
		end
		mapObjectIter:Next()
	end

end


function SoccerCollisionManager:_UnInitSoccerBalls()

	self.soccerBalls = { }

end


function SoccerCollisionManager:Process()

end


function SoccerCollisionManager:GetNumSoccerGoals()

	return #self.soccerGoals

end


function SoccerCollisionManager:GetNumSoccerBalls()

	return #self.soccerBalls

end


--Pass in the soccer goal name or index and it will be returned
function SoccerCollisionManager:GetSoccerGoal(soccerGoalID)

	for index, goal in ipairs(self.soccerGoals) do
		if type(soccerGoalID) == "string" then
			if goal:GetName() == soccerGoalID then
				return goal
			end
		elseif type(soccerGoalID) == "number" then
			if index == soccerGoalID then
				return goal
			end
		end
	end

	return nil

end


--Pass in the soccer ball index and it will be returned
function SoccerCollisionManager:GetSoccerBallByIndex(index)

	if type(index) ~= "number" then
		error("Passed in parameter was not an ID, it is of type " .. type(index))
	end

    if index > 0 and index <= #self.soccerBalls then
	    return self.soccerBalls[index][1]
	else
	    return nil
	end
	
end


--Pass in the soccer ball name or index and it will be returned
function SoccerCollisionManager:GetSoccerBallByID(soccerBallID)

	if type(soccerBallID) ~= "number" then
		error("Passed in parameter was not an ID, it is of type " .. type(soccerBallID))
	end

	for index, ball in ipairs(self.soccerBalls) do
		if ball[1]:Get():DoesOwn(soccerBallID) then
			return ball[1]
		end
	end

	return nil

end


--Respawn all the soccer balls
function SoccerCollisionManager:RespawnBalls()

	for index, ball in ipairs(self.soccerBalls) do
		--Clear velocities, forces, etc
		ball[1]:Get():Reset()
		ball[1]:SetPosition(ball[2])
	end

end


function SoccerCollisionManager:ObjectEnterSoccerGoal(enterParams)

	local soccerGoalName = enterParams:GetParameter("SoccerGoal", true):GetStringData()
	local soccerGoal = self:GetSoccerGoal(soccerGoalName)
	local soccerBallID = enterParams:GetParameter("EnterObjectID", true):GetIntData()
	local soccerBall = self:GetSoccerBallByID(soccerBallID)

	if IsValid(soccerGoal) and IsValid(soccerBall) then
		self.goalScoredParams:GetOrCreateParameter("TeamID"):SetStringData(soccerGoal:Get():GetTeamID())
		self.goalScoredParams:GetOrCreateParameter("GoalID"):SetIntData(soccerGoal:Get():GetGoalID())
		self.goalScored:Emit(self.goalScoredParams)
	end

end

--SOCCERCOLLISIONMANAGER CLASS END