UseModule("ICamController", "Scripts/Modifiers/CameraControllers/")

--CAMCONTROLLERFOLLOW CLASS START



--BRIAN TODO: Camera collision from Bullet CharacterDemo.cpp -
--[[
//use the convex sweep test to find a safe position for the camera (not blocked by static geometry)
	btSphereShape cameraSphere(0.2f);
	btTransform cameraFrom,cameraTo;
	cameraFrom.setIdentity();
	cameraFrom.setOrigin(characterWorldTrans.getOrigin());
	cameraTo.setIdentity();
	cameraTo.setOrigin(m_cameraPosition);
	
	btCollisionWorld::ClosestConvexResultCallback cb( characterWorldTrans.getOrigin(), cameraTo.getOrigin() );
	cb.m_collisionFilterMask = btBroadphaseProxy::StaticFilter;
		
	m_dynamicsWorld->convexSweepTest(&cameraSphere,cameraFrom,cameraTo,cb);
	if (cb.hasHit())
	{

		btScalar minFraction  = cb.m_closestHitFraction;//btMax(btScalar(0.3),cb.m_closestHitFraction);
		m_cameraPosition.setInterpolate3(cameraFrom.getOrigin(),cameraTo.getOrigin(),minFraction);
	}
--]]



class 'CamControllerFollow' (ICamController)

function CamControllerFollow:__init(followObject, setCamera) super(followObject)

	self.followObject = followObject
	self.camera = setCamera

	self.cameraMinDistance = 3.5*1.5
	self.cameraMaxDistance = 3.5*1.5
	self.cameraMinHeight = 1.3*1.5

	self.rotationDamping = 5.5
	self.heightDamping = 4.5
	self.distanceDamping = 1.0

    --This is how slow the follow object has to move in order to lock into the forward vector
    --instead of the velocity
	self.lockForwardVelThres = 7

    --This changes how fast the camera moves when the kart is moving slow
    self.slowCamSpeedMod = 3

	self.targetDistance = self.cameraMinDistance

    self.mouseLookEnabled = true
    self.mouseLookDistance = self.cameraMaxDistance

    self:Reset()

end


function CamControllerFollow:SetMouseLookEnabled(setEnabled)

    self.mouseLookEnabled = setEnabled
    
end


function CamControllerFollow:GetMouseLookEnabled()

    return self.mouseLookEnabled
    
end


function CamControllerFollow:Reset()
    
    if not IsValid(self.followObject) or not IsValid(self.camera) then
        return
    end
    
    local objectPos = self:GetObjectPosition(self.followObject)
    local objectForward = self:GetObjectForward(self.followObject)
    local camUpNormal = self.followObject:GetUpNormal()
    self.camera:SetPosition(objectPos - objectForward * self.cameraMinDistance)
    self.camera:SetPosition(WVector3(self.camera:GetPosition().x, objectPos.y + self.cameraMinHeight, self.camera:GetPosition().z))
    self.camera:GetLookAt():SetPosition(objectPos + camUpNormal)
    print("RESETTING CAMERA to "..tostring(self.camera:GetPosition()))
    self.targetDistance = self.cameraMaxDistance

end


function CamControllerFollow:SetFollowObjectImp(followObject)

	self.followObject = followObject
    self:Reset()

end


function CamControllerFollow:ProcessCamController(frameTime)

	--BRIAN TODO: Consider updating by a fixed amount

	--Early out
	if self.followObject == nil then
		return
	end

	local objectPos = self:GetObjectPosition(self.followObject)
	local objectForward = self:GetObjectForward(self.followObject)
	local camUpNormal = self.followObject:GetUpNormal()
	local curCameraPos = self.camera:GetPosition()

	local cameraTarget = objectPos + objectForward
	local relativePos = curCameraPos - cameraTarget
	if relativePos:Length() == 0 then
		relativePos = objectForward
	end
	local wantedRotation = GetRotationOnAxis(relativePos, camUpNormal)

    local velocityMin = 0.0
    local velocityMax = 20.0
    local objectSpeed = objectForward:Length()
    --i am just making sure the velocity is within min and max to make sure that newTargetDistance calc wont blow up.
    --this also makes it so like if the target is falling with a high velocity the camera wont be able to keep up thus giving appearance of
    --falling.
    local velocityClamped = Clamp(objectSpeed, velocityMin, velocityMax)

    --map the velocity ratio to a distance ratio to find desired distance
    --local newTargetDistance = ((velocityClamped - velocityMin) / (velocityMax - velocityMin)) * (self.cameraMaxDistance - self.cameraMinDistance) + self.cameraMinDistance
    --smooth out the moving to targetDistance
    --self.targetDistance = Lerp(self.distanceDamping * frameTime, self.targetDistance, newTargetDistance)
    self.targetDistance = self.cameraMinDistance

    --Note: Commented out the second half of this when converting over to frameTime, why would it be needed? This was the only operation on followClock
    if (not self.mouseLookEnabled or not self.followObject:IsMouseLooking()) then-- and self.followClock:GetTimeSeconds() > 1 then
        --Calculate the current rotation angles
        --BRIAN TODO: We need to somehow project this into the camUpNormal
        local currentRotationAngle = self.camera:GetOrientation():GetEulerY()
        --BRIAN TODO: We need to somehow project this into the camUpNormal
        local wantedRotationAngle = wantedRotation:GetEulerY()

        --The cam should rotate faster at slower speeds
        local camRotSpeed = self.rotationDamping * frameTime
        if velocityClamped < self.lockForwardVelThres then
            camRotSpeed = camRotSpeed * (self.slowCamSpeedMod * (1 - (velocityClamped / self.lockForwardVelThres)))
        end

	    currentRotationAngle = LerpAngle(camRotSpeed, currentRotationAngle, wantedRotationAngle)
	    --Convert the angle into a rotation
	    local currentRotation = WQuaternion(0, currentRotationAngle, 0)

        --BRIAN TODO: We need to somehow project this into the camUpNormal
        local wantedHeight = objectPos.y + self.cameraMinHeight - Clamp(objectForward.y,-1,0)/20
        --BRIAN TODO: We need to somehow project this into the camUpNormal
        local currentHeight = self.camera:GetPosition().y
        --Damp the height
        --BRIAN TODO: We need to somehow project this into the camUpNormal
        currentHeight = Lerp(self.heightDamping * frameTime, currentHeight, wantedHeight)

        --Set the position of the camera on the x-z plane to:
        --targetDistance meters behind the target
        self.camera:SetPosition(objectPos - (currentRotation * WQuaternion():zAxis() * self.targetDistance))

        --Set the height of the camera
        self.camera:SetPosition(WVector3(self.camera:GetPosition().x, currentHeight, self.camera:GetPosition().z))

        --Always look at the target
        self.camera:GetLookAt():SetPosition(objectPos + camUpNormal)
	else
        --MOUSE LOOK
        self.camera:SetPosition(objectPos - self.followObject:GetLookForward() * self.targetDistance)

        --Set the height of the camera
        local wantedHeight = objectPos.y + self.cameraMinHeight
        self.camera:SetPosition(WVector3(self.camera:GetPosition().x, wantedHeight, self.camera:GetPosition().z))    

        --Always look at the target
        self.camera:GetLookAt():SetPosition(objectPos + camUpNormal)
    end

end

function CamControllerFollow:LLerp(dt, current, target)
    
    local gt = target > current
    local new = current
    if gt then
        new = current + dt * 5
        if new > target then
            new = target
        end
    else
        new = current - dt * 5
        if new < target then
            new = target
        end
    end
    
    return new
    
end

function CamControllerFollow:NotifyActive()

    self:Reset()

end


function CamControllerFollow:GetObjectPosition(object)

	if IsValid(object.GetGraphicalPosition) then
		return object:GetGraphicalPosition()
	else
		return object:GetPosition()
	end

end

function CamControllerFollow:GetObjectForward(object)

	local forwardVector = WVector3(object:GetLinearVelocity())
	--Note: Maybe we should do a true distance check here against self.lockForwardVelThres
	--so it is in sync with the self.slowCamSpeedMod code?
	if forwardVector:Length() < self.lockForwardVelThres then
		if IsValid(object.GetGraphicalOrientation) then
			forwardVector = WVector3(object:GetGraphicalOrientation():zAxis())
		else
			forwardVector = WVector3(object:GetOrientation():zAxis())
		end
	end
	--if self.mouseLookEnabled and object:IsMouseLooking() then
	--    forwardVector = object:GetLookForward()
	--end
	return forwardVector

end

--CAMCONTROLLERFOLLOW CLASS END