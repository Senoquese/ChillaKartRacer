UseModule("AIBot", "Scripts/Bots/")

--SUMOBOT CLASS START

--SumoBot
class 'SumoBot' (AIBot)

function SumoBot:__init() super()

	self.name = "DefaultSumoBotName"

	self.BOT_STATES = 
	{	
		CREATED = 0,
		RESET = 1,
		PLAY = 2
	}

	self.state = self.BOT_STATES.CREATED

	self.botClock = WTimer()
	self.accelTimer = WTimer()
	self.fullSpeedDist = 100
	--At the min distance to the goal spot, how often should the accelerator be used?
    self.minDistSpeedTime = 0.25
	self.lastUpdate = 0
	self.lastInputUpdate = 0
	self.updateRate = 1 / 15
	self.inputRate = 1 / 15

    self.hopTimer = WTimer(2)
    --What percent chance that the bot will hop after the hop timer
	self.randomHopChance = 0.4

end


function SumoBot:ProcessAI(frameTime)

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end

	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		--Do anything that needs to be done to reset the bot so it will be ready for a new round.
		self.state = self.BOT_STATES.PLAY
	elseif self.state == self.BOT_STATES.PLAY then
        self:GoTo(WVector3(0, 0, 0))
        local distToGoal = WVector3(0, 0, 0):Distance(self.player:GetPosition())
        local timeTillAccel = ((1 - Clamp(distToGoal / self.fullSpeedDist, 0, 1)) * self.minDistSpeedTime)
        if self.accelTimer:GetTimeSeconds() > timeTillAccel then
            self.accelTimer:Reset()
            self.goForward = true
        else
            self.goForward = false
        end

        if self.hopTimer:IsTimerUp() then
            self.hopTimer:Reset()
            if SRANDOM() < self.randomHopChance then
                local hopLeft = SRANDOM() < 0.5
                self:UseHop(hopLeft)
            end
        end

        --Check if we have a weapon
        if self:GetPlayer():GetWeaponInQueue() then
            self:UseWeapon(false, false, nil)
        end 
	end

	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end

end

--SUMOBOT CLASS END


function CreateSumoBot()
	
	return SumoBot()

end