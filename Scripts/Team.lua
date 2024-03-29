UseModule("IBase", "Scripts/")

--TEAM CLASS START

class 'Team' (IBase)

function Team:__init(setName) super()

	self.name = setName
	
	self.players = { }

	--userData can be used for anything, keeping track of score, etc
	self.userData = { }

end


function Team:UnInitImp()

end

function Team:GetName()

	return self.name

end

function Team:NumberOfPlayers()

	return #self.players

end


function Team:AddPlayer(addPlayer)

	if not IsValid(addPlayer) then
		error("Invalid player passed into Team:AddPlayer()")
	end

	local playerExists = self:GetPlayerFromID(addPlayer:GetUniqueID())
	if not IsValid(playerExists) then
		table.insert(self.players, addPlayer)
	else
		error("Player named " .. addPlayer:GetName() .. " is already in the Team " .. self:GetName())
	end

end


function Team:RemovePlayer(removePlayer)

	for index, player in pairs(self.players) do
		if player:GetUniqueID() == removePlayer:GetUniqueID() then
			table.remove(self.players, index)
			return
		end
	end

end


function Team:RemoveAllPlayers()

	self.players = { }

end

function Team:ResetUserData()

	self.userData = { }

end

--TEAM CLASS END