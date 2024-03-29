UseModule("IBase", "Scripts/")

--RACENODEMANAGER CLASS START

--The RaceNodeManager scans the world for RaceNodes and connects them
class 'RaceNodeManager' (IBase)

local globalSide = WPlane.POSITIVE_SIDE

function RaceNodeManager:__init(world) super()

	self.world = world
	self.nodes = { }
    self.lapLength = 0
	self:InitNodes()

	self.visualizationEnabled  = false

end


function RaceNodeManager:BuildInterfaceDefIBase()

	self:AddClassDef("RaceNodeManager", "IBase", "Manages and connects all nodes")

end


function RaceNodeManager:InitIBase()

end


function RaceNodeManager:InitNodes()

    print("Starting RaceNodeManager:InitNodes()")

	--Find all the nodes in the world
	local objIter = self.world:GetObjectIterator()
	while not objIter:IsEnd() do
		local worldObject = objIter:Get()
		if IsValid(worldObject) and worldObject:GetTypeName() == "ScriptObject" then
			local scriptObject = ToScriptObject(worldObject)
			if scriptObject:GetScriptObjectTypeName() == "RaceNode" then
			    --Insert in the correct order based on the node index
				table.insert(self.nodes, scriptObject)
			end
		end
		objIter:Next()
	end

    --Reorder based on index
    table.sort(self.nodes, function(a, b) return a:Get():GetIndex() < b:Get():GetIndex() end)

	--Set all nodes prev and next and compute normals
	for index, node in ipairs(self.nodes) do
		--Prev
		if index == 1 then
			node:Get():SetPrevNode(self.nodes[#self.nodes])
		else
			node:Get():SetPrevNode(self.nodes[index - 1])
		end
		--Next
		if index == #self.nodes then
			node:Get():SetNextNode(self.nodes[1])
		else
			node:Get():SetNextNode(self.nodes[index + 1])
		end
		
		--Normal is computed based on the vector from this node to the next node
		local normVec = WVector3(node:Get():GetNextNode():GetPosition() - node:GetPosition())
		local toFront = WVector3(node:Get():GetNextNode():GetPosition() - node:GetPosition())
        local fromBehind = WVector3(node:GetPosition() - node:Get():GetPrevNode():GetPosition())
        
        --Record distances
        self.lapLength = self.lapLength + toFront:Length()
        node:Get():SetDistToNextNode(toFront:Length())

        toFront:Normalise()
        fromBehind:Normalise()
		local normVec = toFront + fromBehind
		
        normVec:Normalise()
		node:Get():SetNormal(normVec)
	end

    print("Lap Distance: "..self.lapLength)

end


function RaceNodeManager:UnInitIBase()

end


function RaceNodeManager:Process()

end

function RaceNodeManager:DistBetweenNodes(startIndex, endIndex)
    if startIndex < 1 or endIndex < 1 or startIndex > #self.nodes or endIndex >#self.nodes or startIndex == endIndex then
        return 0
    end
    
    local sNode = self:GetNode(startIndex)
    local eNode = self:GetNode(endIndex)
    local dist = 0
    
    while sNode:Get():GetIndex() ~= eNode:Get():GetIndex() do
        dist = dist + sNode:Get():GetDistToNextNode()
        sNode = sNode:Get():GetNextNode()
    end
    
    return dist
end


function RaceNodeManager:GetNumNodes()

	return #self.nodes

end

function RaceNodeManager:GetLapLength()
    
    return self.lapLength
    
end

--Pass in the node name or index and it will be returned
function RaceNodeManager:GetNode(nodeID)

	for index, node in ipairs(self.nodes) do
		if type(nodeID) == "string" then
			if node:GetName() == nodeID then
				return node
			end
		elseif type(nodeID) == "number" then
			if node:Get():GetIndex() == nodeID then
				return node
			end
		end
	end

	return nil

end


--Return the node that is closest to the passed in position
--inFront is assumed to be true if nil
function RaceNodeManager:GetNextClosestNode(inCheckpoint, toPosition, inFront)

	local findClosestNodeClock = WTimer()

	local closestNode = nil
	local tempClosestDist = nil
	--First find the closest node to the position based on distance
	for index, node in ipairs(inCheckpoint:Get():GetNodes()) do
		local dist = node:GetPosition():SquaredDistance(toPosition)
		if not IsValid(tempClosestDist) or dist < tempClosestDist then
			closestNode = node
			tempClosestDist = dist
		end
	end

	if GetSystemManager():GetSpikeDetectionEnabled() then
	--	print("RaceNodeManager:GetNextClosestNode() findClosestNodeClock time: " .. tostring(findClosestNodeClock:GetTimeSeconds()) .. " num nodes: " .. tostring(#inCheckpoint:Get():GetNodes()))
	end

	local behindOrAheadClock = WTimer()

	--Now determine if the position is behind or ahead of this closest node
	--Find out which side of the node the position is on
	local nodePlane = closestNode:Get():GetPlane()
	local side = nodePlane:GetPointOnSide(toPosition)

	if GetSystemManager():GetSpikeDetectionEnabled() then
	--	print("RaceNodeManager:GetNextClosestNode() behindOrAheadClock time: " .. tostring(behindOrAheadClock:GetTimeSeconds()))
	end

	local check2NodesClock = WTimer()

	local closestDist = nil
	if IsValid(closestNode) then
		local onto = nil
		if side == WPlane.POSITIVE_SIDE then
			onto = closestNode:Get():GetNextNode():GetPosition() - closestNode:GetPosition()
		else
			onto = closestNode:Get():GetPrevNode():GetPosition() - closestNode:GetPosition()
		end
		local toKart = toPosition - closestNode:GetPosition()
		local proj = toKart:Project(onto)
		local projLen = proj:Length()
		if side ~= WPlane.POSITIVE_SIDE then
			projLen = projLen * -1
		end
		if projLen < 0 and side == WPlane.POSITIVE_SIDE then
			print("IMPOSSIBLE")
		end
		closestDist = projLen
	end

	if GetSystemManager():GetSpikeDetectionEnabled() then
	--	print("RaceNodeManager:GetNextClosestNode() check2NodesClock time: " .. tostring(check2NodesClock:GetTimeSeconds()))
	end

	return closestNode, closestDist

end


function RaceNodeManager:SetVisualizationEnabled(setEnabled)

	self.visualizationEnabled = setEnabled

	if self.visualizationEnabled and not IsValid(self.lines) then
		self.lines = { OGRELines(), OGRELines() }
		self.lines[1]:Init(Parameters())
		self.lines[2]:Init(Parameters())

		local currNode = self:GetNode(1)
		if IsValid(currNode) then
			local nextNode = currNode:Get():GetNextNode()
			self.lines[1]:Begin()
			self.lines[2]:Begin()
			local i = 0
			local numNodes = self:GetNumNodes()
			while i < numNodes do
				if IsValid(nextNode) then
					self.lines[1]:AddLine(currNode:GetPosition(), nextNode:GetPosition(), WColorValue(1, 0, 0, 0))
					-- node normal
                    self.lines[2]:AddLine(currNode:GetPosition() + WVector3(0, 1, 0),
										  currNode:GetPosition() + currNode:Get():GetNormal() + WVector3(0, 1, 0), WColorValue(0, 0, 1, 0))
					-- plane normal
                    self.lines[2]:AddLine(currNode:Get():GetPlane().distance*currNode:Get():GetPlane().normal + WVector3(0, 1.1, 0),
										  currNode:Get():GetPlane().distance*currNode:Get():GetPlane().normal + currNode:Get():GetPlane().normal + WVector3(0, 1.1, 0), WColorValue(1, 0, 1, 0))
					-- node cross 
                    self.lines[2]:AddLine(currNode:GetPosition() + WVector3(0, 1, 0),
										  currNode:GetPosition() + currNode:Get():GetCross() + WVector3(0, 1, 0), WColorValue(0, 1, 0, 0))
				end
				currNode = currNode:Get():GetNextNode()
				if IsValid(currNode) then
					nextNode = currNode:Get():GetNextNode()
				else
					nextNode = nil
				end
				i = i + 1
			end
			self.lines[1]:End()
			self.lines[2]:End()
		end
	end

	self.lines[1]:SetVisible(self.visualizationEnabled)
	self.lines[2]:SetVisible(self.visualizationEnabled)

end


function RaceNodeManager:GetVisualizationEnabled()

	return self.visualizationEnabled

end

--RACENODEMANAGER CLASS END