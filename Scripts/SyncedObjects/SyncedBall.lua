UseModule("ISynced", "Scripts/SyncedObjects/")

--SYNCEDBALL CLASS START

--SyncedBall
class 'SyncedBall' (ISynced)

function SyncedBall:__init() super()

	self.initParams = Parameters()

	--"Ball" and "Cylinder" supported
	self.shapeType = "Ball"

	self.graphicalBall = nil
	self.physicalBall = nil

	self.forceSync = true

end


function SyncedBall:BuildInterfaceDefISynced()

	self:AddClassDef("SyncedBall", "ISynced", "A SyncedBall is a shape that is able to be synced")

end


function SyncedBall:InitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:InitGraphical()
	end
	--Both the client and server simulate a physical object
	self:InitPhysical()

end


function SyncedBall:InitGraphical()

	self.graphicalBall = OGREModel()
	self.graphicalBall:SetName(self:GetName() .. "G")
	self.graphicalBall:Init(self.initParams)
	self.graphicalBall:SetPosition(self:GetPosition())
	self.graphicalBall:SetOrientation(self:GetOrientation())
	
	self:InitDebugDrawing()

end


function SyncedBall:InitDebugDrawing()

	--BRIAN TODO: For testing only, draw the client and server physical balls
	self.clientRenderer = OGRELines()
	self.clientRenderer:Init(Parameters())
	self.clientRenderer:SetOverlay(true, false)
	self.serverRenderer = OGRELines()
	self.serverRenderer:Init(Parameters())
	self.serverRenderer:SetOverlay(true, false)

	self.clientRenderer:CreateLineBox(WColorValue(1, 0, 0, 0), 1)
	self.serverRenderer:CreateLineBox(WColorValue(1, 1, 1, 0), 1)

	--Assume not visible by default
	self.clientRenderer:SetVisible(false)
	self.serverRenderer:SetVisible(false)

end


function SyncedBall:UnInitGraphical()

	if IsValid(self.graphicalBall) then
		self.graphicalBall:UnInit()
		self.graphicalBall = nil
	end

	self:UnInitDebugDrawing()

end


function SyncedBall:UnInitDebugDrawing()

	self.clientRenderer:UnInit()
	self.clientRenderer = nil
	self.serverRenderer:UnInit()
	self.serverRenderer = nil

end


function SyncedBall:InitPhysical()

	if self.shapeType == "Ball" then
		self.physicalBall = BulletSphere()
	elseif self.shapeType == "Cylinder" then
		self.physicalBall = BulletCylinder()
	elseif self.shapeType == "Box" then
		self.physicalBall = BulletBox()
	elseif self.shapeType == "ConvexHull" then
		self.physicalBall = BulletConvexHull()
	else
		error("Invalid shape type: " .. tostring(self.shapeType) .. " for SyncedBall")
	end
	--Match the physical object's name to the name of the SyncedBall
	--so collision is easier to check
	self.physicalBall:SetName(self:GetName())
	if IsValid(self.shapeDims) then
		self.physicalBall:SetDimensions(self.shapeDims)
	end
	self.physicalBall:SetPosition(self:GetPosition())
	self.physicalBall:SetOrientation(self:GetOrientation())
	self.physicalBall:Init(self.initParams)

	--[[if self.shapeType == "Cylinder" then
		--There is currently some issue if a cylinder does not deactivate
		self.physicalBall:SetDeactivates(true)
	end--]]

    --BRIAN TODO: Used for testing
	--[[self.collisionStartSlot = self:CreateSlot("BulletCollisionStart", "BulletCollisionStart")
	self.physicalBall:GetSignal("StartCollision", true):Connect(self.collisionStartSlot)
	--Make sure it is awake
	self.physicalBall:ApplyWorldImpulse(WVector3(), WVector3())--]]

end


function SyncedBall:BulletCollisionStart(params)

    if IsServer() then
        if Random() * 2 > 1 then
            GetServerWorld():DestroyObject(self:GetID())
        end
    end

end


function SyncedBall:UnInitPhysical()

	if IsValid(self.physicalBall) then
		self.physicalBall:UnInit()
		self.physicalBall = nil
	end

end


function SyncedBall:UnInitIBase()

	--Only the client has a graphical object
	if IsClient() then
		self:UnInitGraphical()
	end
	--Both the client and server simulate a physical object
	self:UnInitPhysical()

end


function SyncedBall:DoesOwn(ownObjectID)

	if self.physicalBall:GetID() == ownObjectID then
		return true
	end
	if IsClient() then
		if self.graphicalBall:GetID() == ownObjectID then
			return true
		end
	end

	return false

end


function SyncedBall:NotifyScriptObjectPositionChange(setPos)

	if IsValid(self.graphicalBall) then
		self.graphicalBall:SetPosition(setPos)
	end

	if IsValid(self.physicalBall) then
		self.physicalBall:SetPosition(setPos)
	end

end


function SyncedBall:NotifyScriptObjectOrientationChange(setOrien)

	if IsValid(self.graphicalBall) then
		self.graphicalBall:SetOrientation(setOrien)
	end

	if IsValid(self.physicalBall) then
		self.physicalBall:SetOrientation(setOrien)
	end

end


function SyncedBall:NotifyScriptObjectScaleChange(setScale)

	if IsValid(self.graphicalBall) then
		self.graphicalBall:SetScale(setScale)
	end

end


function SyncedBall:GetGraphicalPosition()

	if IsValid(self.graphicalBall) then
		return self.graphicalBall:GetPosition()
	end
	return WVector3()

end


function SyncedBall:GetGraphicalOrientation()

	if IsValid(self.graphicalBall) then
		return self.graphicalBall:GetOrientation()
	end
	return WQuaternion()

end


function SyncedBall:Reset()

	if IsValid(self.physicalBall) then
		self.physicalBall:Reset()
	end

end


function SyncedBall:GetUpNormal()

	if IsValid(self.physicalBall) then
		return self.physicalBall:GetUpNormal()
	end
	return WVector3(0, 1, 0)

end


function SyncedBall:GetLinearVelocity()

	if IsValid(self.physicalBall) then
		return self.physicalBall:GetLinearVelocity()
	end
	return WVector3(0, 0, 0)

end


function SyncedBall:ApplyWorldImpulse(impulse, localPos)

	if IsValid(self.physicalBall) then
		self.physicalBall:ApplyWorldImpulse(impulse, localPos)
	end

end


function SyncedBall:ApplyWorldTorqueImpulse(impulse)

	if IsValid(self.physicalBall) then
		self.physicalBall:ApplyWorldTorqueImpulse(impulse)
	end

end


function SyncedBall:GetSyncedActive()

	return not self.physicalBall:GetSleeping()

end


function SyncedBall:SetSynced(setSynced)

	self.forceSync = setSynced

end


function SyncedBall:GetSynced()

	return self.forceSync

end


function SyncedBall:SetSyncedStateData(stateBuiltTime, setState)

	local pos = setState:ReadWVector3()
	local orien = setState:ReadWQuaternion()
	--local vel = setState:ReadWVector3()
	--local angVel = setState:ReadWVector3()

	local state = BulletWorldObjectState()
	state:SetPosition(pos)
	state:SetOrientation(orien)
	--state:SetLinearVelocity(vel)
	--state:SetAngularVelocity(angVel)

	GetBulletPhysicsSystem():SetObjectState("Main", self.physicalBall:GetID(), state)

	--We must update the transform of this object now so the ClientWorld can lerp properly
	self:SetPosition(pos, false)
	self:SetOrientation(orien, false)

	--Sync the server physical renderer to the last update we received from the server
	if IsValid(self.serverRenderer) then
		self.serverRenderer:SetPosition(pos)
		--self.serverRenderer:SetOrientation(orien)
	end

end


function SyncedBall:GetSyncedStateData(returnState)

	returnState:WriteWVector3(self.physicalBall:GetPosition())
	returnState:WriteWQuaternion(self.physicalBall:GetOrientation())
	--returnState:WriteWVector3(self.physicalBall:GetLinearVelocity())
	--returnState:WriteWVector3(self.physicalBall:GetAngularVelocity())

end


function SyncedBall:SetParameter(param)

	if param:GetName() == "ShapeType" then
		self.shapeType = param:GetStringData()
	elseif param:GetName() == "Dimensions" then
		self.shapeDims = param:GetWVector3Data()
	else
		self.initParams:AddParameter(Parameter(param))
	end

end


function SyncedBall:EnumerateParameters(params)

	params:AddParameter(Parameter("ShapeType", self.shapeType))
	if IsValid(self.shapeDims) then
		params:AddParameter(Parameter("Dimensions", self.shapeDims))
	end

	local i = 0
	while i < self.initParams:GetNumberOfParameters() do
		params:AddParameter(Parameter(self.initParams:GetParameter(i, true)))
		i = i + 1
	end

end


function SyncedBall:ProcessSyncedObject(frameTime)

	self.physicalBall:Process(frameTime)

	--Update the ScriptObject every process
	self:SetPosition(self.physicalBall:GetPosition(), false)
	self:SetOrientation(self.physicalBall:GetOrientation(), false)
	self:SetLinearVelocity(self.physicalBall:GetLinearVelocity(), false)

	if IsClient() then
		self.graphicalBall:Process(frameTime)

		--Sync the client physical renderer to the client physical current position
		if IsValid(self.clientRenderer) then
			self.clientRenderer:SetPosition(self.physicalBall:GetPosition())
			--self.clientRenderer:SetOrientation(self.physicalBall:GetOrientation())
		end
	end

end


function SyncedBall:NotifyDebugDrawEnabled(enabled)

	self.clientRenderer:SetVisible(enabled)
	self.serverRenderer:SetVisible(enabled)

end

--SYNCEDBALL CLASS END