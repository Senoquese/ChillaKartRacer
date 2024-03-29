UseModule("IBase", "Scripts/")

--RACENODE CLASS START

--RaceNode is a point that marks a spot on a race track
--It is used in a few different ways
--BRIAN TODO: Make an IScriptObject
class 'RaceNode' (IBase)

function RaceNode:__init() super()

	self.name = "DefaultRaceNodeName"

	self.nodePos = WVector3()
	self.nodeNormal = WVector3()
	self.cross = WVector3()
	self.plane = WPlane()
	self.nextNode = nil
	self.distToNextNode = 0
	self.prevNode = nil
	self.index = 0

end


function RaceNode:BuildInterfaceDefIBase()

	self:AddClassDef("RaceNode", "IBase", "Defines a node")

end


function RaceNode:SetName(setName)

	self.name = setName

end


function RaceNode:GetName()

	return self.name

end


function RaceNode:InitIBase()

end


function RaceNode:UnInitIBase()

end


function RaceNode:NotifyPositionChange(setPos)

	self.nodePos.x = setPos.x
	self.nodePos.y = setPos.y
	self.nodePos.z = setPos.z

end


function RaceNode:NotifyOrientationChange(setOrien)

end


function RaceNode:NotifyScaleChange(setScale)

end


function RaceNode:SetParameter(param)

	if param:GetName() == "Index" then
		self.index = param:GetIntData()
	end

end


function RaceNode:EnumerateParameters(params)

	params:AddParameter(Parameter("Index", Parameter.INT, self.index))

end


function RaceNode:SetNormal(setNormal)

	self.nodeNormal.x = setNormal.x
	self.nodeNormal.y = setNormal.y
	self.nodeNormal.z = setNormal.z

	--We can also calculate the cross product based on this normal and the up vector
	local crossProduct = self.nodeNormal:CrossProduct(WVector3(0, 1, 0))
	self.cross.x = crossProduct.x
	self.cross.y = crossProduct.y
	self.cross.z = crossProduct.z

	--Finally, calculate the plane
	self.plane:Redefine(self.nodeNormal, self.nodePos)
	self.plane:Normalise()

end


function RaceNode:GetNormal()

	return self.nodeNormal

end


--Return the vector that is the cross product of this vectors normal and the up vector
function RaceNode:GetCross()

	return self.cross

end


--Return the plane that the cross product of this node creates
function RaceNode:GetPlane()

	return self.plane

end


function RaceNode:SetNextNode(nextNode)

	self.nextNode = nextNode

end


function RaceNode:SetPrevNode(prevNode)

	self.prevNode = prevNode

end


function RaceNode:GetNextNode()

	return self.nextNode

end


function RaceNode:GetPrevNode()

	return self.prevNode

end


function RaceNode:SetDistToNextNode(dist)

    self.distToNextNode = dist

end


function RaceNode:GetDistToNextNode()

    return self.distToNextNode

end


function RaceNode:GetIndex()

	return self.index

end


function RaceNode:GetSpawnPoint()

	return self.spawnPos, self.spawnOrien

end

--RACENODE CLASS END