UseModule("AIBot", "Scripts/Bots/")

--RACEBOT CLASS START

--RaceBot
class 'RaceBot' (AIBot)

function RaceBot:__init() super()

	self.name = "DefaultRaceBotName"
	

	self.BOT_STATES = 
	{	
		CREATED = 0,
		RESET = 1,
		STARTING_LINE = 2,
		RACE = 3
	}
	
	self.state = self.BOT_STATES.CREATED
	
	--self.raceNodeManager = nil
	self.raceNodeManager = RaceNodeManager(GetServerWorld())
	
	self.raceStates = RaceStates()
	
	self.targetNode = nil
	self.nodeIndex = 1
	self.nodeCheck = 0
	self.lastNodeCheck = 0
	
	self.raceRestartSlot = self:CreateSlot("GameReset", "GameReset")
	GetServerManager():GetGameMode():GetSignal("GameReset", true):Connect(self.raceRestartSlot)
	
	--This is emitted to when a player is respawned
	self.playerRespawnedSlot = self:CreateSlot("PlayerRespawned", "PlayerRespawned")
	GetServerManager():GetSignal("PlayerRespawned"):Connect(self.playerRespawnedSlot)
	
	self.botClock = WTimer()
	self.lastUpdate = 0
	self.lastInputUpdate = 0
	self.updateRate = 1/15
	self.inputRate = 1/15
end

function RaceBot:GameReset(params)
    self.state = self.BOT_STATES.RESET
end

function RaceBot:PlayerRespawned(respawnParams)
    
    --[[
	local player = self:GetPlayer()
    local checkpointIndex = GetServerManager():GetGameMode().raceCheckpointManager:GetPlayerCheckpoint(player)
	local playerCP = GetServerManager():GetGameMode().raceCheckpointManager:GetCheckpoint(checkpointIndex)
    if IsValid(playerCP) then
		local node, dist = GetServerManager():GetGameMode().raceNodeManager:GetNextClosestNode(playerCP, player:GetPosition(), false)
        self.targetNode = node:Get():GetNextNode()
    end
    --]]

    --[[
    --Cancel any existng reset request
    for index, resetPlayer in pairs(self.resettingPlayers) do
		if resetPlayer[1] == player then
			table.remove(self.resettingPlayers, index)
			break
		end
	end

	--If the player who has just respawned is IT, remove IT from them
	if player == self:GetIT() and self:GetGameState() == self.tagStates.GAME_STATE_PLAY then
		self:SetIT(nil)
	end

    --Penalize the player
    self:SetPlayerScore(player, self:GetPlayerScore(player)+RESPAWN_PENALTY)
	player:Reset()
    --]]
end


function RaceBot:ProcessAI(frameTime)

    if self.botClock:GetTimeSeconds() - self.lastUpdate > self.updateRate then
        self.lastUpdate = self.botClock:GetTimeSeconds()
    else
        return
    end
	
	--if IsValid(self:GetPlayer()) and IsValid(self:GetPlayer():GetName()) then
        --print("processingBot:"..self:GetPlayer():GetName().." state:"..self.state)
    --end
	
	if self.state == self.BOT_STATES.CREATED then
		if self.isConnected == true then
			self.state = self.BOT_STATES.RESET
			print("RaceBot Connected: "..self:GetPlayer():GetName())
		end
	elseif self.state == self.BOT_STATES.RESET then
	    --The game may reset while they are connecting
	    if self.isConnected == true then
            --TODO: only come out of this state if spawned in game, come back here on new loads or round restarts
            --Do anything that needs to be done to reset the bot so it will be ready for a new round.
            self.state = self.BOT_STATES.STARTING_LINE
            --print("RaceBot Reset")
        end
		
	elseif self.state == self.BOT_STATES.STARTING_LINE then
		--Get first race node and make it the target.
		self.nodeIndex = 1
		if IsValid(self.raceNodeManager) then
            self.targetNode = self.raceNodeManager:GetNode(self.nodeIndex)
            if IsValid(self.targetNode) then
                self.state = self.BOT_STATES.RACE
                if not IsValid(self:GetPlayer()) then
                    print("Player not valid in self.state == self.BOT_STATES.STARTING_LINE")
                end
                print("RaceBot Started: "..self:GetPlayer():GetName())
            else
                print("Invalid targetNode: "..self:GetPlayer():GetName())
            end
		else
		    print("Invalid raceNodeManager: "..self:GetPlayer():GetName())
		end
				
	elseif self.state == self.BOT_STATES.RACE then
        
        --print("targetNode:"..self.targetNode:Get():GetIndex())
        
        local lastTarget = self.targetNode
        
        self:GoTo(self.targetNode:GetPosition())
        local vel = self:GetPlayer():GetLinearVelocity()
        local forwardPoint = self:GetPlayer():GetPosition()+vel*0.5
        if not IsValid(self.targetNode:Get()) then
            error("self.targetNode:Get() is invalid")
        end
        if self.targetNode:Get():GetPlane():GetPointOnSide(forwardPoint) == WPlane.POSITIVE_SIDE then
            self.targetNode = self.targetNode:Get():GetNextNode()
            --print("targetNode:"..self.targetNode:Get():GetIndex().."  "..self:GetPlayer():GetName())

        end
        
        if GetGameMode():GetGameState() == self.raceStates.GAME_STATE_RACE and not IsValid(lastTarget) or lastTarget:Get():GetIndex() ~= self.targetNode:Get():GetIndex() then
            self.lastNodeCheck = self.botClock:GetTimeSeconds()
        elseif GetGameMode():GetGameState() ~= self.raceStates.GAME_STATE_RACE then
            self.lastNodeCheck = self.botClock:GetTimeSeconds()
        end
        
        local distToNode = (self.targetNode:GetPosition() - forwardPoint):Length()
        local nodeDot = self.player:GetLinearVelocity():DotProduct(self.targetNode:Get():GetNormal())
        if self.player:GetLinearVelocity():Length() > distToNode*1 and math.abs(nodeDot) < 0.5 then
            self.goForward = false
        end
        
        --if self.player:GetLinearVelocity():Length() < 0.5 then
            --if not IsValid(self.lastHop) or self.botClock:GetTimeSeconds()-self.lastHop > 1.0 then
                --self:UseHop(true)
                --self.lastHop = self.botClock:GetTimeSeconds()
            --end
        --end
        
        --check if we're stuck
        if GetGameMode():GetGameState() == self.raceStates.GAME_STATE_RACE and self.botClock:GetTimeSeconds() > self.lastNodeCheck + 2.5 then
            local botVel = self:GetPlayer():GetLinearVelocity()
            botVel.y = 0
            if math.abs(self.nodeCheck - (self.targetNode:Get():GetIndex()+distToNode)) < 1 and botVel:Length() < 0.25 and self:GetPlayer():GetLinearVelocity():Length() > 0 then
                self:UseRespawn()
            end
            self.nodeCheck = self.targetNode:Get():GetIndex()+distToNode
            self.lastNodeCheck = self.botClock:GetTimeSeconds()
        end

                
        -- check if we have a weapon
        if self:GetPlayer():GetWeaponInQueue() and SRANDOM() < 0.01 then
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
                
        --[[
        if self:GoTo(self.targetNode:GetPosition(), 15) then
        	if self.nodeIndex < self.raceNodeManager:GetNumNodes() then
        		self.nodeIndex = self.nodeIndex + 1
        	else
        		self.nodeIndex = 1
        	end
        	
            self.targetNode = self.targetNode:Get():GetNextNode()
            
            print("New bot node:"..tostring(self.targetNode:Get():GetIndex()))
            
        end
        ]]--    
		--self:WorldCollisionAvoidance()
	end
	
	if self.botClock:GetTimeSeconds() - self.lastInputUpdate > self.inputRate then
        self.lastInputUpdate = self.botClock:GetTimeSeconds()
        self:SetInputs()
    end

end

--RACEBOT CLASS END


function CreateRaceBot()
	
	return RaceBot()

end