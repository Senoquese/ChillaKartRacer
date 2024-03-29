UseModule("AIBot", "Scripts/Bots/")

--SOCCERBOT CLASS START

--SoccerBot
class 'SoccerBot' (AIBot)

function SoccerBot:__init() super()

	self.name = "DefaultSoccerBotName"
	

	self.BOT_STATES = 
	{	
		CREATED = 0,
		RESET = 1,
		STARTUP = 2,
		TAG = 3
	}
	
	self.state = self.BOT_STATES.CREATED
	
	self.playerIT = nil
	
	self.resetITposition = WVector3(0,0,0)
	
	self.botClock = WTimer()
	self.lastUpdate = 0
	self.lastInputUpdate = 0
	self.updateRate = 1/15
	self.inputRate = 1/15
	
	--self.toleranceLR = 0.25
	
end


function SoccerBot:ProcessAI(frameTime)

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
			--print("SoccerBot Connected")
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		--Do anything that needs to be done to reset the bot so it will be ready for a new round.
		self.state = self.BOT_STATES.STARTUP
		--print("SoccerBot Reset")
		
	elseif self.state == self.BOT_STATES.STARTUP then

		self.state = self.BOT_STATES.TAG
		
		
	elseif self.state == self.BOT_STATES.TAG then
	    
	    -- Get ball position
	    --print("SoccerBot update")
	    local gm = GetGameMode()
	    local goal = nil
	    local oppGoal = nil
	    if self.player.userData.teamID == "Blue" then
	        goal = gm:GetGoal(2)
	        oppGoal = gm:GetGoal(1)
	    else
	        goal = gm:GetGoal(1)
	        oppGoal = gm:GetGoal(2)
	    end
        local ball = gm:GetBall(1)
        local ballPos = ball:GetPosition()
        local ballDist = (ball:GetPosition()-self.player:GetPosition()):Length()
        local gtg = (goal:GetPosition()-oppGoal:GetPosition()):Length()
        local dBG = (goal:GetPosition()-ballPos):Length()
        local dPG = (goal:GetPosition()-self.player:GetPosition()):Length()
        --local dPOG = (oppGoal:GetPosition()-self.player:GetPosition()):Length()

        if dBG < dPG then
            self:GoTo(ballPos)
        elseif (ball:GetPosition()-goal:GetPosition()):Length() > gtg or (ball:GetPosition()-oppGoal:GetPosition()):Length() > gtg then
            self:GoTo(ballPos)
        else
            self:GoTo(oppGoal:GetPosition())
        end
        if self.player:GetLinearVelocity():Length() > ballDist then
            self.goForward = false
        end
        
        if self.player:GetLinearVelocity():Length() < 0.5 then
            --if not IsValid(self.lastHop) or self.botClock:GetTimeSeconds()-self.lastHop > 1.0 then
                self:UseHop(true)
                self.lastHop = self.botClock:GetTimeSeconds()
            --end
        end
        
        -- check if we have a weapon
        if self:GetPlayer():GetWeaponInQueue() then
            if self:GetPlayer():GetQueuedWeaponTypeName() == "SyncedPuncher" then
                if ballDist < 3 then
                    self:UseWeapon(false, false, nil)
                end
            else        
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
        end 
        
		--self:WorldCollisionAvoidance()
	end
	
	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end

end

--SoccerBOT CLASS END


function CreateSoccerBot()
	
	return SoccerBot()

end