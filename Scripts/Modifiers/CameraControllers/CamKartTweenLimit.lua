UseModule("ScriptModifier", "Scripts/Modifiers/")

--CAMKARTTWEENLIMIT CLASS START

class 'CamKartTweenLimit' (ScriptModifier)

function CamKartTweenLimit:__init(followObject, setCamera) super(followObject)

	self.followObject = followObject
	self.camera = setCamera
	self.clock = WTimer()
	self.enabled = true

    self.theta = 0.0

    self.lastDistance = 0

	self.cameraSpeedPercent = 0
	self.cameraSpeedPercentStep = 0.75

	self.cameraMinDistance = 4.5
	self.cameraMaxDistance = 10
	self.cameraMinHeight = 2.0
	self.cameraMaxHeight = 4.0

	self.cameraMinLookAtHeight = 2.0
	self.cameraMaxLookAtHeight = 2.5

	self.camVector = WVector3()

	--true when the player wants to look behind instead of forward
	self.lookBehind = false

	self.lookBackSlot = self:CreateSlot("ControlLookBack", "ControlLookBack")

end


function CamKartTweenLimit:SetEnabled(setEnabled)

	self.enabled = setEnabled

end


function CamKartTweenLimit:GetEnabled()

	return self.enabled

end


function CamKartTweenLimit:SetFollowObjectImp(followObject)

	self.followObject = followObject

end


function CamKartTweenLimit:Process()

	local timeDiff = self.clock:GetTimeDifference()

	if (not IsValid(self.followObject)) then
		return
	end

	if self.enabled then
		local objectPos = nil
		if IsValid(self.followObject.GetGraphicalPosition) then
			objectPos = self.followObject:GetGraphicalPosition()
		else
			objectPos = self.followObject:GetPosition()
		end
		local camUpNormal = self.followObject:GetUpNormal()

		self:SmoothCamSpeed(timeDiff)

		local forwardVector = WVector3(self.followObject:GetLinearVelocity())
		if forwardVector:Equals(WVector3(0, 0, 0), 0.5) then
			if IsValid(self.followObject.GetGraphicalOrientation) then
				forwardVector = WVector3(self.followObject:GetGraphicalOrientation():zAxis())
			else
				forwardVector = WVector3(self.followObject:GetOrientation():zAxis())
			end
		end

		local kartSpeed = forwardVector:Length()

		if self.lookBehind then
			forwardVector:Negate()
		end
		forwardVector:Normalise()

		local targetPosition = WVector3(objectPos)

		-- Base camera position
		targetPosition = targetPosition - forwardVector

        -- Calculate cam vector
		local camVector = objectPos - targetPosition
		camVector:Normalise()

        local curCameraPos = self.camera:GetPosition()
	
        -- Repel camera from kart
        local dAlpha = timeDiff *5.5
        dAlpha = Clamp(dAlpha, 0, 1)
        local vAlpha = self.cameraSpeedPercent
        vAlpha = Clamp(vAlpha, 0, 1)
        local hAlpha = timeDiff * 3.5
        hAlpha = Clamp(hAlpha, 0, 1)
        local targetDistance = self.cameraMinDistance
        targetDistance = self.lastDistance + (targetDistance - self.lastDistance)*timeDiff
        self.lastDistance = targetDistance
        local kartVelPos = objectPos+((forwardVector*targetDistance)*vAlpha)
		local cameraToObj = (curCameraPos) - kartVelPos
        cameraToObj:Normalise()
        local targetDistancePosition = objectPos + cameraToObj*targetDistance
        local distanceForceVector = (targetDistancePosition - curCameraPos)*dAlpha
        
        local targetHeightPos = objectPos+(camUpNormal*self.cameraMinHeight+self.cameraSpeedPercent*3)
        -- http://chortle.ccsu.edu/VectorLessons/vch11/vch11_6.html
        -- V is gravUp normal
        -- W is cam minus targetHeightPos
        -- kv is projection of W onto V
        local V = WVector3(camUpNormal)
        local W = targetHeightPos - curCameraPos 
        local Wu = W/W:Length()
        local Vu = V/V:Length()
        local kv = W:Length()*Wu:DotProduct(Vu)*Vu
 
        local heightForceVector = kv * hAlpha

        -- check if the distance from camera to kartVelPos is greater than camera to objPos
        local dKVPVector = curCameraPos - kartVelPos
        local dKVP = (dKVPVector):Length()
        local dOPVector = curCameraPos - objectPos
        local dOP = (dOPVector):Length()
        if dKVP < dOP then
            local kartSideVector = forwardVector:CrossProduct(camUpNormal)
            local dotProd = dOPVector:DotProduct(kartSideVector)

            sideForce = cameraToObj:CrossProduct(camUpNormal)*dAlpha
            if dotProd < 0 then
                sideForce = sideForce * -1
            end
            distanceForceVector = distanceForceVector + sideForce
        end

        --Apply repel force to position
        curCameraPos = curCameraPos + distanceForceVector + heightForceVector

		--print("dist: " .. tostring(distanceForceVector:Length()) .. " height: " .. tostring(heightForceVector:Length()))

        --Clamp the max distance to attempt to smooth out the camera (isn't working correctly
        --because it ends up adjusting the height too much)
        --[[if curCameraPos:Distance(objectPos) > self.cameraMaxDistance then
            local camDistNorm = curCameraPos - objectPos
            camDistNorm:Normalise()
            local adjustPos = objectPos + camDistNorm * self.cameraMaxDistance
            --Ignore the y component to avoid the height from adjusting too much
            curCameraPos.x = adjustPos.x
            curCameraPos.z = adjustPos.z
        end--]]

        self.camera:SetPosition(curCameraPos)

		--Camera Look At Position
		self.camera:GetLookAt():SetPosition(objectPos+camUpNormal)
	end

end


function CamKartTweenLimit:SmoothCamVector(timeDiff, targetVector)

	local lerpAmount = (timeDiff * 3.5)
	if lerpAmount > 1 then
		lerpAmount = 1
	end
	self.camVector = self.camVector + ((targetVector - self.camVector) * lerpAmount)
	self.camVector:Normalise()
	return self.camVector

end


function CamKartTweenLimit:SmoothCamSpeed(timeDiff)

	local targetSpeedPercent = self.followObject:GetSpeedPercent()

	local lerpAmount = (timeDiff * 3.5)
	if lerpAmount > 1 then
		lerpAmount = 1
	end
	self.cameraSpeedPercent = self.cameraSpeedPercent + ((targetSpeedPercent - self.cameraSpeedPercent) * lerpAmount)

end


function CamKartTweenLimit:ControlLookBack(lookBackParams)

	local pressed = lookBackParams:GetParameter("Pressed", true):GetBoolData()
	if pressed then
		self.lookBehind = true
	else
		self.lookBehind = false
	end

end


function CamKartTweenLimit:RayTest(startPos, endPos)

	local rayResult = GetBulletPhysicsSystem():RayCast(startPos, endPos)
	if IsValid(rayResult) and IsValid(rayResult:GetHitObject()) then
		return rayResult:GetHitPointWorld()
	end
	return nil

end

--CAMKARTTWEENLIMIT CLASS END