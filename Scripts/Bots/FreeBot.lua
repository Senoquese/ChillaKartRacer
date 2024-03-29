UseModule("AIBot", "Scripts/Bots/")

--FreeBot CLASS START

--FreeBot
class 'FreeBot' (AIBot)

function FreeBot:__init() super()

    print("FREEBOT")

	self.name = "DefaultFreeBotName"
	

	self.BOT_STATES = 
	{	
		CREATED = 0,
		RESET = 1,
		STARTUP = 2,
		TAG = 3
	}
	
	self.state = self.BOT_STATES.CREATED
	
	self.botClock = WClock()
	self.lastUpdate = 0
	self.lastInputUpdate = 0
	self.updateRate = 1/15
	self.inputRate = 1/15
	self.lastNodeCheck = 0
	
	--self.toleranceLR = 0.25
	
end


function FreeBot:ProcessAI()

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end

	PUSH_PROFILE("FreeBot:ProcessAI()")
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
			--print("FreeBot Connected")
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		--Do anything that needs to be done to reset the bot so it will be ready for a new round.
		self.state = self.BOT_STATES.STARTUP
		--print("FreeBot Reset")
		
	elseif self.state == self.BOT_STATES.STARTUP then

		self.state = self.BOT_STATES.TAG
		print("Getting target")
		if IsValid(GetGameMode().GetRandomTarget) then
            self.target = GetGameMode():GetRandomTarget()
            print("Got valid target:"..tostring(self.target))
        end
		
	elseif self.state == self.BOT_STATES.TAG then
	    
	    -- Go to target
	    --print("FreeBot update")
	    if IsValid(self.target) then
	        self:GoThrough(self.target)
	        if (self:GetPlayer():GetPosition()-self.target):Length() < 5 then
	            self.target = GetGameMode():GetRandomTarget()
	        end
        end
        
        local airsteer = self:GetPlayer():GetController().inAir
        --print("airTime: "..tostring(self:GetPlayer():GetController().inAir))
        if airsteer and not self.goReverse then
            --print("FREEBOT AIRSTEER")
            self.goReverse = true
            self:GetPlayer():GetController().controlReverseDown = true
            self:SetInputs()
        elseif not airsteer and self.goReverse then
            self.goReverse = false
            self:GetPlayer():GetController().controlReverseDown = false
            self:SetInputs()
        end
        
         --check if we're stuck
        if IsValid(self.target) and self.botClock:GetTimeSeconds() > self.lastNodeCheck + 2.5 then
            local botVel = self:GetPlayer():GetLinearVelocity()
            botVel.y = 0
            if botVel:Length() < 0.25 then
                self:UseRespawn()
            end
            self.lastNodeCheck = self.botClock:GetTimeSeconds()
        end
        
	    
	end
	    
	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end
    
    -- check if we have a weapon
    if IsValid(self:GetPlayer()) and self:GetPlayer():GetWeaponInQueue() and SRANDOM() < 0.01 then
        local closestID = self:FindClosestPlayerID(50)
        
        if closestID == self:GetPlayer():GetUniqueID() then
                
            if self:GetPlayer().userData.place == 1 then
                self:UseWeapon(true, false, nil)
            else
                self:UseWeapon(false, false, nil)
            end
                
        else
            local target = GetPlayerManager():GetPlayerFromID(closestID)
            local toTarget = target:GetPosition()-self:GetPlayer():GetPosition()
            toTarget.y = 0
            toTarget:Normalise()
                
            self:UseWeapon(false, true, toTarget)
        end
    end

	POP_PROFILE("FreeBot:ProcessAI()")

end

--FreeBot CLASS END


function CreateFreeBot()
	
	return FreeBot()

end