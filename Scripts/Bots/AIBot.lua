UseModule("IBase", "Scripts/")

--AIBOT CLASS START

--AIBot - base class for AI bot
--BRIAN TODO: Rename to IBotAI or IBot as it is an interface
class 'AIBot' (IBase)

function AIBot:__init() super()

	self.name = "DefaultAIBotName"

	--this bots ptr to bot class
	self.ourBot = nil
	self.isConnected = false

	--this bots unique player ID
	self.id = nil
	--this bots player class ptr
	self.player = nil

	self.goForward = false
	self.goReverse = false
	self.goLeft = false
	self.goRight = false

	self.useHop = false
	self.useReset = false

	self.useBoost = false
	self.lengthToUseBoost = 20

	self.turnSpeed = 16
	self.fullSpeed = 99
	self.speedCap = 16

	self.toleranceLR = 0.15

    self.weaponParam = Parameter()

    self.enableControlsSlot = self:CreateSlot("EnableControls", "EnableControls")

    self.localClientState = ClientState()

    self.useWeaponCommands = { }
    self.useWeaponAllowedTimer = WTimer(0.25)

end


function AIBot:GetPlayer()

    return self.player

end


function AIBot:BuildInterfaceDefIBase()

	self:AddClassDef("AIBot", "IBase", "The base class for any type of bot")

end


function AIBot:InitIBase()

end


function AIBot:UnInitIBase()

end


function AIBot:SetName(setName)

	self.name = setName

end


function AIBot:GetName()

	return self.name

end


function AIBot:SetBot(setBot)

	self.ourBot = setBot

end


function AIBot:Connected()

    self.isConnected = true
    self.id = self.ourBot:GetID()
    self.player = GetPlayerManager():GetPlayerFromID(self.id)
    print("Bot " .. self.player:GetName() .. " connected, valid controller: "..tostring(IsValid(self.player:GetController())))
    self.player:GetController():GetSignal("EnableControls"):Connect(self.enableControlsSlot)

end


function AIBot:Process(frameTime)

    --Update fake camera details to the server
    if IsValid(self.ourBot) and self.isConnected and self.player:GetControllerValid() then
        self.localClientState:SetCameraState(self.player:GetController():GetPosition(), GetNetworkSystem():GetTime())
        local followObjID = self.player:GetController():GetID()
        self.localClientState:SetCameraFollowObjectID(followObjID)
        self.ourBot:GetClientSystem():UpdateLocalClientState(self.localClientState)
    end

    self:ProcessUseWeaponCommands()

	self:ProcessAI(frameTime)

end


function AIBot:ProcessUseWeaponCommands()

    --Only process one at a time
    if self.useWeaponAllowedTimer:IsTimerUp() and #self.useWeaponCommands > 0 then
        self.useWeaponAllowedTimer:Reset()
        self:_UseWeapon(self.useWeaponCommands[1][1], self.useWeaponCommands[1][2],
                        self.useWeaponCommands[1][3], self.useWeaponCommands[1][4])
        table.remove(self.useWeaponCommands, 1)
    end

end


function AIBot:ProcessAI(frameTime)

	--Define this function with your AI in your derived Bot class

end


function AIBot:SetInputs()

	if self.isConnected == true then
		--print("F:" .. tostring(self.goForward) .. " Rv:" .. tostring(self.goReverse) .. " L:" .. tostring(self.goLeft) .. " Rt:" .. tostring(self.goRight))
		
		if IsValid(self.player) and self.player:GetControllerValid() and
           self.player:GetController().inAir then
		    self.goForward = false
		    self.goReverse = false
		    self.goRight = false
		    self.goLeft = false
		end
		
		self.ourBot:Control(InputMap.ControlAccel, self.goForward, false, nil)
		self.ourBot:Control(InputMap.ControlReverse, self.goReverse, false, nil)
		self.ourBot:Control(InputMap.ControlLeft, self.goLeft, false, nil)
		self.ourBot:Control(InputMap.ControlRight, self.goRight, false, nil)
		self.ourBot:Control(InputMap.ControlBoost, self.useBoost, false, nil)
	    self.ourBot:Control(InputMap.Hop, self.useHop, false, nil)
        	
	end
	
end


function AIBot:EnableControls(enabledParams)

    local enabled = enabledParams:GetParameter("Enable", true):GetBoolData()

    print("Bot controls enabled:"..tostring(enabled))

    self.goForward = false
	self.goReverse = false
	self.goLeft = false
	self.goRight = false
	self.useHop = false
	self.useReset = false
	self.useBoost = false
	
	self:SetInputs()

end


function AIBot:UseHop(left)

    if not IsValid(self.player) or not self.player:GetControllerValid() or self.player:GetController().inAir then
        return
    end

    if left then
        self.ourBot:Control(InputMap.ControlLeft, true, false, nil)
    else
        self.ourBot:Control(InputMap.ControlRight, true, false, nil)
    end
    
    self.ourBot:Control(InputMap.Hop, true, false, nil)
    self.ourBot:Control(InputMap.Hop, false, false, nil)
    self.ourBot:Control(InputMap.ControlRight, false, false, nil)
    self.ourBot:Control(InputMap.ControlLeft, false, false, nil)

end


function AIBot:UseRespawn()

    self.ourBot:Control(InputMap.ControlReset, true, false, nil)
    self.ourBot:Control(InputMap.ControlReset, false, false, nil)

end


function AIBot:UseWeapon(dropBehind, aimed, direction)

    table.insert(self.useWeaponCommands, { true, dropBehind, aimed, direction })
    table.insert(self.useWeaponCommands, { false, dropBehind, aimed, direction })

end


function AIBot:_UseWeapon(press, dropBehind, aimed, direction)

    if aimed and IsValid(direction) then
        self.weaponParam:SetWVector3Data(direction)
    end
    if dropBehind then
        self.ourBot:Control(InputMap.UseItemDown, press, false, nil)
    else
        self.ourBot:Control(InputMap.UseItemUp, press, aimed, self.weaponParam)
    end

end


--GoTo() --modifies controls to attempt to travel to target position within tolerance radius
--WVector3 targetPosition - is the desired position to go to
--float tolerance - is radius in meters to consider yourself at destination
function AIBot:GoTo(targetPosition, tolerance)
	local arrived = false
	local myPosition = self.player:GetPosition()
	local relPosition = targetPosition - (myPosition)
	local distanceSquared = relPosition:SquaredLength()
	
	if not IsValid(tolerance) then
		tolerance = 0
	end
	
	if distanceSquared <= (tolerance*tolerance) then
		arrived = true
		self.goLeft = false
		self.goRight = false
		self.goForward = false
		if self.player:GetLinearVelocity():Length() > 1 then
		    self.goReverse = true
		else
		    self.goReverse = false
		end
		self.useBoost = false
	else
		relPosition:Normalise()
		local orientation = self.player:GetOrientation()
		local forwardNormal = orientation:zAxis()
		local leftNormal = orientation:xAxis()
		forwardNormal:Normalise()
		leftNormal:Normalise()
		local front = forwardNormal:DotProduct(relPosition)
		local left = leftNormal:DotProduct(relPosition)
		
		-- most cases go forward
		self.goForward = true
		self.goReverse = false
		
        self.useBoost = false

        local speed = self.player:GetLinearVelocity():Length()
		if left > self.toleranceLR then
			--target is to the left, go left
			self.goLeft = true
			self.goRight = false
		elseif left < -self.toleranceLR then
			--target is to the right, go right.
			self.goLeft = false
			self.goRight = true
		elseif front < 0.5 then
		
		    if front < 0 then
		        self.goReverse = true
		        self:UseHop(left < 0)
		    end
			--target is directly behind, go reverse
			--self.goLeft = false
			--self.goRight = false
			self.goForward = false
			
			self.useBoost = false
			--self.goRight = true
		else
			-- target is directly in front, do not turn
			self.goLeft = false
			self.goRight = false
			
			--if distanceSquared > (self.lengthToUseBoost*self.lengthToUseBoost) then
				self.useBoost = true
			--end
		end
	end
	
	return arrived
end

function AIBot:GoThrough(targetPosition)
	local arrived = false
	local myPosition = self.player:GetPosition()
	local relPosition = targetPosition - myPosition
	local distanceSquared = relPosition:SquaredLength()
	
	if not IsValid(tolerance) then
		tolerance = 0
	end
	
	if false and distanceSquared <= (tolerance*tolerance) then
		arrived = true
		self.goLeft = false
		self.goRight = false
		self.goForward = false
		self.goReverse = false
		self.useBoost = false
	else
		relPosition:Normalise()
		local orientation = self.player:GetOrientation()
		local forwardNormal = orientation:zAxis()
		local leftNormal = orientation:xAxis()
		forwardNormal:Normalise()
		leftNormal:Normalise()
		local front = forwardNormal:DotProduct(relPosition)
		local left = leftNormal:DotProduct(relPosition)
		
		-- most cases go forward
		self.goForward = true
		self.goReverse = false

        self.useBoost = false

        local speed = self.player:GetLinearVelocity():Length()
		if left > self.toleranceLR then
			--target is to the left, go left
			self.goLeft = true
			self.goRight = false
		elseif left < -self.toleranceLR then
			--target is to the right, go right.
			self.goLeft = false
			self.goRight = true
		elseif math.abs(front) < 0.5 then
		    self:UseHop(front < 0)
			--target is directly behind, go reverse
			--self.goLeft = false
			--self.goRight = false
			--self.goForward = false
			--self.goReverse = true
			
			self.goRight = true
		else
			-- target is directly in front, do not turn
			self.goLeft = false
			self.goRight = false
			
			--if distanceSquared > (self.lengthToUseBoost*self.lengthToUseBoost) then
				self.useBoost = true
			--end
		end
	end
	
	return arrived
end

--Evade() --modifies controls to attempt to Evade the target position if its within tolerance radius.
--WVector3 targetPosition - is the position to evade.
--float tolerance - is radious in meters to get outside of.
function AIBot:Evade(targetPosition, tolerance)

	local evaded = false
	local myPosition = self.player:GetPosition()
	local relPosition = targetPosition - myPosition
	local distanceSquared = relPosition:SquaredLength()
		
	if IsValid(tolerance) and distanceSquared >= (tolerance*tolerance) then
		evaded = true
		self.goLeft = false
		self.goRight = false
		self.goForward = false
		self.goReverse = false
	else
		relPosition:Normalise()
		local orientation = self.player:GetOrientation()
		local forwardNormal = orientation:zAxis()
		local leftNormal = orientation:xAxis()
		forwardNormal:Normalise()
		leftNormal:Normalise()
		local front = forwardNormal:DotProduct(relPosition)
		local left = leftNormal:DotProduct(relPosition)
		
		-- most cases go forward
		self.goForward = true
		self.goReverse = false

		if left > self.toleranceLR then
			--target is to the left, go right
			self.goLeft = false
			self.goRight = true
		elseif left < -self.toleranceLR then
			--target is to the right, go left.
			self.goLeft = true
			self.goRight = false
		elseif front > 0 then
			--target is directly in front, go reverse
			self.goLeft = false
			self.goRight = false
			self.goForward = false
			self.goReverse = true
		else
			-- target is directly behind, do not turn
			self.goLeft = false
			self.goRight = false
		end
	end
	
	return evaded
end

function AIBot:WorldCollisionAvoidance()
	local myPosition = self.player:GetPosition()
	--print("forwardNormal: " .. tostring(self:GetForwardNormal()))
	--print("leftNormal: " .. tostring(self:GetLeftNormal()))
	
	
	local leftNormal = self:GetLeftNormal()
	local forwardNormal = self:GetForwardNormal()
	local speed = self.player:GetController():GetLinearVelocity():Length()
	local frontSensorLength = 20
	local frontSensorOffset = .5
	local forwardRightSensorStart = myPosition + (leftNormal * -frontSensorOffset)
	local forwardRightSensorEnd = myPosition + ((forwardNormal * frontSensorLength)  + (leftNormal * -frontSensorOffset))
	--print("forwardRightSensorLength: " .. tostring(forwardRightSensorStart:Distance(forwardRightSensorEnd)))
	local forwardLeftSensorStart = myPosition + (leftNormal * frontSensorOffset)
	local forwardLeftSensorEnd = myPosition + ((forwardNormal * frontSensorLength)  + (leftNormal * frontSensorOffset))
	--print("forwardLeftSensorLength: " .. tostring(forwardLeftSensorStart:Distance(forwardLeftSensorEnd)))
	
	local rayResultRight = GetBulletPhysicsSystem():RayCast(forwardRightSensorStart, forwardRightSensorEnd)
	local rayResultLeft = GetBulletPhysicsSystem():RayCast(forwardLeftSensorStart, forwardLeftSensorEnd)
	
	local isWorldHitRight, isWorldHitLeft = false, false
	local forwardRightDistance, forwardLeftDistance = frontSensorLength, frontSensorLength
	
	if IsValid(rayResultRight) then
		local hitPointRight = rayResultRight:GetHitPointWorld()
		local hitObjectRight = GetNetworkedWorld():GetObjectFromID(rayResultRight:GetHitObjectID())
		if IsValid(hitPointRight) then
			--print("world collision to my right")
			if IsValid(hitObjectRight) then
				isWorldHitRight = hitObjectRight:GetCollisionResponse()
				--print("isWorldHitRight: " .. tostring(isWorldHitRight) .. "objectName: " .. tostring(hitObjectRight:GetName()))
				if isWorldHitRight and hitObjectRight:GetName() == "SingleWorldMeshP" then
				  	hitNormal = WVector3(rayResultRight:GetHitNormalWorld())
				  	--print("hitNormalRight: " .. tostring(hitNormal))
				  	hitNormal:Normalise()
	  			  	incline = -hitNormal:DotProduct(forwardNormal)
	  			  	--the incline angle is arccosine(-incline), for a shallow angle, incline will be closer to 0, 
					--and a steep angle is closer to 1.0
					--0.7 is about 45 degree angle of incline
	  			  	if incline < 0.7 then
	  			  		isWorldHitRight = false
	  			  	else
	  			  		--print("steep incline: " .. tostring(incline))
	  			  	end
				end
			else
				isWorldHitRight = true
			end
			
			if isWorldHitRight then
				forwardRightDistance = myPosition:Distance(hitPointRight)
			end
			--print("forwardRightDistance: " .. forwardRightDistance)
		end
	end

	if IsValid(rayResultLeft) then
		hitPointLeft = rayResultLeft:GetHitPointWorld()
		hitObjectLeft = GetNetworkedWorld():GetObjectFromID(rayResultLeft:GetHitObjectID())
		if IsValid(hitPointLeft) then
			--print("world collision to my left")
			if IsValid(hitObjectLeft) then
				isWorldHitLeft = hitObjectLeft:GetCollisionResponse()
				
				if isWorldHitLeft and hitObjectLeft:GetName() == "SingleWorldMeshP" then
				  	hitNormal = WVector3(rayResultLeft:GetHitNormalWorld())
				  	hitNormal:Normalise()
	  			  	incline = -hitNormal:DotProduct(forwardNormal)
	  			  	if incline < 0.7 then
	  			  		isWorldHitLeft = false
	  			  	end
				end
			else
				isWorldHitLeft = true
			end
			
			if isWorldHitLeft then
				forwardLeftDistance = myPosition:Distance(hitPointLeft)
			end
			--print("forwardLeftDistance: " .. forwardLeftDistance)
		end
	end
	
	if isWorldHitRight and isWorldHitLeft and forwardRightDistance < 2 and forwardLeftDistance < 2 then
		self.goForward = false
		self.goReverse = true
	end
	
	if isWorldHitRight or isWorldHitLeft then
		if forwardRightDistance > forwardLeftDistance then
			--print("turn right to avoid world")
			self.goRight = true
			self.goLeft = false
		elseif forwardRightDistance < forwardLeftDistance then
			--print("turn left to avoid world")
			self.goRight = false
			self.goLeft = true
		else
			--print("the world in front of you")
		end
	end
end

function AIBot:GetRotatedZNormal(rotDegree)
	local orientation = WQuaternion(self.player:GetOrientation())
	local eulerX,eulerY,eulerZ = orientation:GetEulerX(),orientation:GetEulerY(),orientation:GetEulerZ()
	eulerY = eulerY - rotDegree
	orientation:FromEuler(eulerX,eulerY,eulerZ)
	local vector = orientation:zAxis()
	vector:Normalise()
	return vector
end

--Sensor() returns rayResult starting from players position and
--going out in the passed WVector3 direction, the Scalar distance given.
function AIBot:Sensor(direction, distance)
	local startPos = self.player:GetPosition()
	local endPos = startPos + (direction * distance)
	local rayResult = GetBulletPhysicsSystem():RayCast(startPos, endPos)
	return rayResult
end

function AIBot:GetForwardNormal()
	local orientation = self.player:GetOrientation()
	local forwardNormal = orientation:zAxis()
	forwardNormal:Normalise()
	return forwardNormal
end

function AIBot:GetLeftNormal()
	local orientation = self.player:GetOrientation()
	local leftNormal = orientation:xAxis()
	leftNormal:Normalise()
	return leftNormal
end

--FindClosestPlayerID() returns closest player withing given range, or returns own ID if no target found.
function AIBot:FindClosestPlayerID(range)
	--init target as self, if still self as target at end of check then no target was found.
	local targetPlayerID = self.id
	--only look up to 'range' distance away for a target
	local bestDistance = range
	local myPosition = self.player:GetPosition()

	local numPlayers = GetPlayerManager():GetNumberOfPlayers()
	-- index seems to start at 1
	local playerIndex = 1
	local otherPlayer = nil
	while playerIndex <= numPlayers do
		otherPlayer = GetPlayerManager():GetPlayer(playerIndex)
		if otherPlayer:GetUniqueID() ~= self.id then
			local otherPlayerPosition = otherPlayer:GetPosition()
			local distance = myPosition:Distance(otherPlayerPosition)
			if distance < bestDistance then
				bestDistance = distance
				targetPlayerID = otherPlayer:GetUniqueID()
			end
		end

		playerIndex = playerIndex + 1
	end

	return targetPlayerID

end


--AIBOT CLASS END
