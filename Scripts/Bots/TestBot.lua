UseModule("AIBot", "Scripts/Bots/")

--TESTBOT CLASS START

--TestBot
class 'TestBot' (AIBot)

function TestBot:__init() super()

	self.name = "DefaultTestBotName"
	
	self.timer = WTimer()
		
	--define time in seconds to wait after enter reset state
	self.resetTime = 3
	
	--define random time in seconds to turn on accel at startup
	self.startTime = 3
	
	--define time in seconds in between search attempts
	self.searchTime = 1
	
	--define range to search for target in meters.
	self.searchRange = 100
	
	self.BOT_STATES = 
	{	
		CREATED = 0,
		RESET = 1,
		STARTING_LINE = 2,
		SEARCHING = 3,
		FOLLOWING = 4
	}
	
	self.state = self.BOT_STATES.CREATED
	
	
	self.isCat = isCat
end

--[23:22] Brian: local numPlayers = GetPlayerManager():GetNumberOfPlayers()
--[23:22] Brian: local player = GetPlayerManager():GetPlayer(i)    <<index, starts at 0>>
--[23:26] Brian: local player = GetPlayerManager():GetPlayerFromID(ourID)
--[23:26] Brian: that should return the bot's player
--[23:26] Brian: local rayResult = GetBulletPhysicsSystem():RayCast(startPos, endPos)
--[23:27] Brian: both params are of type WVector3
--[23:27] Brian: if IsValid(rayResult) and IsValid(rayResult:GetHitObject()) then
--[23:27] Brian: local hitObject = rayResult:GetHitObject()
--[23:27] Brian: local hitMaterial = rayResult:GetHitMaterial()
--[23:28] Brian: local hitPoint = rayResult:GetHitPointWorld()
--[23:28] Brian: local hitNormal = rayResult:GetHitNormal()
--[23:29] Brian: local matName = hitMaterial:GetParameters():GetName()
--local myVel = self.player:GetController():GetLinearVelocity()

function TestBot:Process(frameTime)

	PUSH_PROFILE("TestBot:Process()")

	--[[

	local timeDiff = self.timer:GetTimeSeconds()
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.timer:Reset()
			self.state = self.BOT_STATES.RESET
			--print("TestBot Connected")
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		if timeDiff > self.resetTime then
			self.state = self.BOT_STATES.STARTING_LINE
			self.timer:Reset()
			--print("TestBot Reset")
		end
		
	elseif self.state == self.BOT_STATES.STARTING_LINE then
	
		self.goForward = true
		if timeDiff > self.startTime then
			self.goForward = false
			self.state = self.BOT_STATES.SEARCHING
			self.timer:Reset()
			--print("TestBot Started")
		end
		
		
	elseif self.state == self.BOT_STATES.SEARCHING then
	
			local closestPlayerID = self:FindClosestPlayerID(self.searchRange)
			
			if closestPlayerID ~= self.id then
				self.targetPlayer = GetPlayerManager():GetPlayerFromID(closestPlayerID)
				self.state = self.BOT_STATES.FOLLOWING
				--print("TestBot Found Target: " .. self.targetPlayer:GetName())
			end

		
	elseif self.state == self.BOT_STATES.FOLLOWING then
	
		local targetPosition = self.targetPlayer:GetPosition()
		
		if self.isCat then
			local coughtTarget = self:GoTo(targetPosition, 2)
			if coughtTarget then
				print(self.name .." Cought Target: " .. self.targetPlayer:GetName())
				self.isCat = false
				self.state = self.BOT_STATES.SEARCHING
			end
		else
			local evadedTarget = self:Evade(targetPosition, self.searchRange/2)
			if evadedTarget then
				print(self.name .. " Evaded Target: " .. self.targetPlayer:GetName())
				self.isCat = true
				self.state = self.BOT_STATES.SEARCHING
			end
		end
		
		self:WorldCollisionAvoidance()
		
	end
	
	self:SetInputs()

	--]]

	POP_PROFILE("TestBot:Process()")

end



--TESTBOT CLASS END


function CreateTestBot()
	if IsValid(isCat) then
		isCat = not isCat
	else
		isCat = true
	end
	
	return TestBot()

end