UseModule("AIBot", "Scripts/Bots/")

--REVERSETAGBOT CLASS START

--ReverseTagBot
class 'ReverseTagBot' (AIBot)

function ReverseTagBot:__init() super()

	self.name = "DefaultReverseTagBotName"
	

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
	
	self.tagStates = ReverseTagStates()
	
	self.botClock = WTimer()
	self.lastUpdate = 0
	self.lastInputUpdate = 0
	self.updateRate = 1/15
	self.inputRate = 1/15
	
	--self.toleranceLR = 0.25
	
end

function ReverseTagBot:PlayerIT(params)


	self.playerITid = params:GetParameter(0, true):GetIntData()
	--print("New It person is " .. self.playerITid)
	
end


function ReverseTagBot:ProcessAI(frameTime)

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
			--print("ReverseTagBot Connected")
		end
	elseif self.state == self.BOT_STATES.RESET then
		--TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
		--Do anything that needs to be done to reset the bot so it will be ready for a new round.
		self.state = self.BOT_STATES.STARTUP
		--print("ReverseTagBot Reset")
		
	elseif self.state == self.BOT_STATES.STARTUP then

		self.state = self.BOT_STATES.TAG
		
		
	elseif self.state == self.BOT_STATES.TAG then
	    local playerIT = GetGameMode():GetIT()

        if playerIT == nil then
            --nobody is it, go for it in the reset position
			self:GoTo(self.resetITposition, 1)
		else
			local playerITid = playerIT:GetUniqueID()
			if playerITid == self.id then
			    --you are it, evade!!
			    if GetGameMode():GetGameState() == self.tagStates.GAME_STATE_PLAY then
                    local closestPlayerID = self:FindClosestPlayerID(20)
                    if closestPlayerID ~= self.id then
                        local closestPlayer = GetPlayerManager():GetPlayerFromID(closestPlayerID)
                        local closestPlayerPosition = closestPlayer:GetPosition()
                        self:Evade(closestPlayerPosition, 50)
                    else
                        self:GoTo(self.resetITposition,10)
                    end
                else
                    local closestPlayerID = self:FindClosestPlayerID(1000)
                    local closestPlayer = GetPlayerManager():GetPlayerFromID(closestPlayerID)
                    local closestPlayerPosition = closestPlayer:GetPosition()
                    local closestDist = (closestPlayerPosition-self:GetPlayer():GetPosition()):Length()
                    self:GoTo(closestPlayerPosition)
                    if self.player:GetLinearVelocity():Length() > closestDist then
                        self.goForward = false
                    end
                end
			else 
			    --someone else is it, go get em unless the arrow is red!
			    local targetPlayerPosition = playerIT:GetPosition()
			    local targetDist = (targetPlayerPosition-self:GetPlayer():GetPosition()):Length()
			    if GetGameMode():GetGameState() == self.tagStates.GAME_STATE_PLAY then
			        self:GoTo(targetPlayerPosition)
			    else
			        local distToIt = (targetPlayerPosition - self:GetPlayer():GetPosition()):Length()
                    if distToIt < 20 then
                        self:Evade(targetPlayerPosition, 50)
                    else
                        self:GoTo(self.resetITposition,10)
                        if self.player:GetLinearVelocity():Length() > targetDist then
                            self.goForward = false
                        end
                    end
			    end
		    end
		    
		end
        
        -- check if we have a weapon
        if self:GetPlayer():GetWeaponInQueue() then
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
        
		--self:WorldCollisionAvoidance()
	end

	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end

end

--REVERSETAGBOT CLASS END


function CreateReverseTagBot()
	
	return ReverseTagBot()

end