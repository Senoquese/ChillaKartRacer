UseModule("IBase", "Scripts/")
UseModule("Player", ASSET_DIR .. "Scripts/")

--TEAMMANAGER CLASS START

class 'TeamManager' (IBase)

function TeamManager:__init(setMap) super()

	self.teams = { }


end


function TeamManager:NumberOfTeams()

	return #self.teams

end


function TeamManager:AddTeam(newTeam)

	if not IsValid(newTeam) then
		error("Invalid team passed into TeamManager:AddTeam()")
	end

	local teamExists = self:GetTeam(newTeam)
	if not IsValid(teamExists) then
		table.insert(self.teams, newTeam)
	else
		error("Team named " .. newTeam:GetName() .. " is already in the TeamManager")
	end
		
end


--Return the player that matches the passed in index or name
function TeamManager:GetTeam(name)

	for index, team in pairs(self.teams) do
        if team:GetName() == name then
            return team
        end
	end
	return nil

end


function TeamManager:RemoveTeam(teamName)

	for index, team in pairs(self.teams) do
		if team:GetName() == teamName then
			team:UnInit()
			table.remove(self.teams, index)
			return
		end
	end

end


function TeamManager:RemoveAllTeams()

	for index, team in pairs(self.teams) do
		team:UnInit()
	end

	self.teams = { }

end


--TEAMMANAGER CLASS END