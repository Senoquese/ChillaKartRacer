UseModule("AIBot", "Scripts/Bots/")

--TargetBot CLASS START

--TargetBot
class 'TargetBot' (AIBot)

function TargetBot:__init() super()

	self.name = "DefaultTargetBotName"
	

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
	
	--self.toleranceLR = 0.25
	
end


function TargetBot:ProcessAI()

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end

	PUSH_PROFILE("TargetBot:ProcessAI()")
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
			--print("TargetBot Connected")
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		--Do anything that needs to be done to reset the bot so it will be ready for a new round.
		self.state = self.BOT_STATES.STARTUP
		--print("TargetBot Reset")
		
	elseif self.state == self.BOT_STATES.STARTUP then

		self.state = self.BOT_STATES.TAG
		print("Getting target")
		self.target = GetGameMode():GetRandomTarget()
		print("Got valid target:"..tostring(IsValid(self.target)))
		
	elseif self.state == self.BOT_STATES.TAG then
	    
	    -- Go to target
	    --print("TargetBot update")
	    if IsValid(self.target) then
	        self:GoTo(self.target:GetPosition())
	    end
	end
	    
	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end

	POP_PROFILE("TargetBot:ProcessAI()")

end

--TargetBot CLASS END


function CreateTargetBot()
	
	return TargetBot()

end