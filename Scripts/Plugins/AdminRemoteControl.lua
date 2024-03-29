class 'AdminRemoteControl' (IBase)

function AdminRemoteControl:__init() super()
    self.permissionsFile = "adminControlPermissions.txt"
    self.permissions = { }
    
    self.bansFile = "adminControlBans.txt"
    self.bans = { }
    
    self.banUnbanLevel = 1
    self.kickLevel = 1
    self.addRemoveAdminLevel = 1
    self.physicsLevel = 1
    self.mapChangeLevel = 1
    self.restartLevel = 1
    self.getIDLevel = 1
    
    --self.steamIDpattern = "^(%d:%d:%d+)$"
    self.steamIDpattern = "^(%d+)$"
    self:LoadPermissions()
    self:LoadBans()
    
    self.sendMessageSlot = self:CreateSlot("SendChatMessage", "SendChatMessage", GetServerSystem())
    self.clientConnectedSlot = self:CreateSlot("ClientConnected", "ClientConnected")
    --We need to wait for the SteamServerSystem to receive the client's info so we can find the newly
    --connected client's SteamID
    GetSteamServerSystem():GetSignal("ReceivedClientInfo", true):Connect(self.clientConnectedSlot)
end

function AdminRemoteControl:LoadBans()
    local fname = self.bansFile
    
    if IsValid(fname) then
        print("AdminRemoteControl: Loading bans from file: " .. fname)
        local file = io.open(fname, "r")
        
        if IsValid(file) then
            for line in file:lines() do
                if line:sub(1,4) == '#BAN' then
                    local splitString = self:StringSplit2(line)

                    if # splitString >= 3 then
                        local istart, iend, steamID = splitString[2]:find(self.steamIDpattern)
                        
                        if steamID ~= nil then
                            local nickname = splitString[3]
                            local reason = ""
                            
                            if # splitString >= 4 then
                                reason = self:StringJoin2(splitString, 4)
                            else
                                reason = "Banned from server."
                            end
                            self.bans[steamID] = { nickname = nickname, reason = reason }
                        end
                    end
                end
            end
            file:close()
        else
            print("AdminRemoteControl: Error reading bans, creating new file")
            self:WriteBans()
        end
    end
end

function AdminRemoteControl:WriteBans()
    local fname = self.bansFile
    
    if IsValid(fname) then
        print("AdminRemoteControl: Creating bans file: " .. fname)
        local file = io.open(fname, "w+")
        
        if IsValid(file) then
            file:write("This file stores steamIDs and ban reasons for banned users.\n" ..
                       "The format is as follows: #BAN <steamID> <\"nickname\"> [reason] (for example, #BAN 0:1:23456789 \"some guy\" Just because)\n\n")

            for steamid, value in pairs(self.bans) do
                file:write("#BAN " .. steamid .. " \"" .. value.nickname .. "\" " .. value.reason .. "\n")
            end
            
            file:flush()
            file:close()
        else
            error("AdminRemoteControl: Error creating bans file")
        end
    end
end

function AdminRemoteControl:LoadPermissions()
    local fname = self.permissionsFile
    
    if IsValid(fname) then
        print("AdminRemoteControl: Loading permissions from file: " .. fname)
        local file = io.open(fname, "r")
    
        if IsValid(file) then
            for line in file:lines() do
                if line:sub(1,1) == '#' then
                    local splitString = WUtil_StringSplit(" ", line)
                    
                    if # splitString == 2 and tonumber(splitString[2]) ~= nil then
                        local level = tonumber(splitString[2])
                        
                        if splitString[1] == "#BANUNBANLEVEL" then
                            self.banUnbanLevel = level
                        elseif splitString[1] == "#KICKLEVEL" then
                            self.kickLevel = level
                        elseif splitString[1] == "#ADDREMOVEADMINLEVEL" then
                            self.addRemoveAdminLevel = level
                        elseif splitString[1] == "#PHYSICSLEVEL" then
                            self.physicsLevel = level
                        elseif splitString[1] == "#MAPCHANGELEVEL" then
                            self.mapChangeLevel = level
                        elseif splitString[1] == "#RESTARTLEVEL" then
                            self.restartLevel = level
                        elseif splitString[1] == "#GETIDLEVEL" then
                            self.getIDLevel = level
                        end
                    elseif # splitString >= 3 and splitString[1] == "#ADMIN" then
                        if splitString[2]:find(self.steamIDpattern) ~= nil then
                            local adminLevel = tonumber(splitString[3])
                        
                            if adminLevel ~= nil and adminLevel > 0 then
                                self.permissions[splitString[2]] = adminLevel
                            end
                        end
                    end
                end
            end
            
            file:close()
        else
            print("AdminRemoteControl: Error reading permissions, creating new file")
            self:WritePermissions()
        end
    end
end

function AdminRemoteControl:WritePermissions()
    local fname = self.permissionsFile
    
    if IsValid(fname) then
        print("AdminRemoteControl: Writing permissions to file: " .. fname)
        local file = io.open(fname, "w+")
        
        if IsValid(file) then
            file:write("This is the configuration file for the AdminRemoteControl plugin.\n" ..
                       "To give somebody administrative privileges, add a new #ADMIN line as follows:\n" ..
                       " #ADMIN <steamid> <permission level> (for example, #ADMIN 76531529146315199 1)\n" ..
                       "The permission level is a number given to each command to determine who can use that command.\n" ..
                       "Admins can only use features for which the permission level is less than or equal to their own permission level.\n" ..
                       "For instance, if a command has a permission level of 4, only admins of rank 4, 3, 2, and 1 can use that command.\n" ..
                       "A command with a permission level of 0 means the command is disabled.\n\n")
            
            file:write("#BANUNBANLEVEL " .. self.banUnbanLevel .. "\n")
            file:write("#KICKLEVEL " .. self.kickLevel .. "\n")
            file:write("#ADDREMOVEADMINLEVEL " .. self.addRemoveAdminLevel .. "\n")
            file:write("#PHYSICSLEVEL " .. self.physicsLevel .. "\n")
            file:write("#MAPCHANGELEVEL " .. self.mapChangeLevel .. "\n")
            file:write("#RESTARTLEVEL " .. self.restartLevel .. "\n")
            file:write("#GETIDLEVEL " .. self.getIDLevel .. "\n\n")
            
            for steamid,level in pairs(self.permissions) do
                file:write("#ADMIN " .. steamid .. " " .. level .. "\n")
            end
            
            file:flush()
            file:close()
        else
            error("AdminRemoteControl: Error writing permissons")
        end
    end
end

function AdminRemoteControl:SendChatMessage(sendParams)
    local player = sendParams:GetParameterAtIndex(0, false)
	local message = sendParams:GetParameterAtIndex(1, true)
    local peerID = sendParams:GetParameter("PeerID", true):GetIntData()
    
	if IsValid(player) and IsValid(message) and IsValid(peerID) then
	    local steamID = GetSteamServerSystem():GetClientSteamID(peerID)
	    message = message:GetStringData()
	    local messageLen = message:len() - 7
	    
	    -- Message only contains color code for some reason
	    if messageLen <= 0 then
	        return nil 
	    end

	    message = message:sub(8)
	    
	    if message == "nextmap" then
	        GetServerManager():SendServerMessage("Next map is: " .. GetServerManager():GetNextMap())
	    elseif message == "timeleft" then
	       if not GetServerManager().deferredLoadMap and IsValid(tonumber(GetServerManager().serverSettings.mapTime)) then
	            local timeleft = tonumber(GetServerManager().serverSettings.mapTime)*60 - GetServerManager().mapTimeLimitClock:GetTimeSeconds()
	            if timeleft < 0 then
	                timeleft = 0
	            end
	            local minLeft = math.floor(timeleft / 60)
	            local secLeft = timeleft - 60 * minLeft
	            GetServerManager():SendServerMessage("Time left: " .. minLeft .. ":" .. string.format('%02u', secLeft))
		   end
		elseif StartsWith(message, "!gravity") and self:HasAccess(peerID, steamID, self.physicsLevel) then
		    self:ChangeGravity(peerID, message)
		elseif StartsWith(message, "!kick") and self:HasAccess(peerID, steamID, self.kickLevel) then
		    self:Kick(peerID, message)
		elseif StartsWith(message, "!changemap") and self:HasAccess(peerID, steamID, self.mapChangeLevel) then
		    self:ChangeMap(peerID, message)
		elseif StartsWith(message, "!restart") and self:HasAccess(peerID, steamID, self.restartLevel) then
		    self:RestartMap(peerID)
		elseif StartsWith(message, "!ban") and self:HasAccess(peerID, steamID, self.banUnbanLevel) then
		    self:Ban(peerID, message)
		elseif StartsWith(message, "!unban") and self:HasAccess(peerID, steamID, self.banUnbanLevel) then
		    self:Unban(peerID, message)
		--elseif StartsWith(message, "!changeprop") and self:HasAccess(peerID, steamID, self.physicsLevel) then
		--    self:ChangeProp(peerID, message)
		elseif StartsWith(message, "!addadmin") and self:HasAccess(peerID, steamID, self.addRemoveAdminLevel) then
		    self:AddAdmin(peerID, message, steamID)
		elseif StartsWith(message, "!removeadmin") and self:HasAccess(peerID, steamID, self.addRemoveAdminLevel) then
		    self:RemoveAdmin(peerID, message, steamID)
		elseif StartsWith(message, "!getids") and self:HasAccess(peerID, steamID, self.getIDLevel) then
		    self:GetIDs(peerID)
	    end
	end
end

function AdminRemoteControl:GetIDs(peerID)
    local retval = ""
    local playerManager = GetPlayerManager()
    
    for i,v in pairs(playerManager.players) do
        local playerNick = v:GetName()
        local playerID = v:GetUniqueID()
        retval = retval .. ", " .. playerNick .. " = " .. playerID
    end
    
    SENDMESSAGE(peerID, "Local player IDs: " .. retval:sub(3))
end

function AdminRemoteControl:AddAdmin(peerID, message, steamID)
    local strparams = self:StringSplit2(message)
    local paramlen = # strparams

    if paramlen >= 3 then
        local matchnick = self:StringJoin2(strparams, 2, paramlen - 1)
        local newlevel = tonumber(strparams[paramlen])
        local level = self.permissions[steamID]
        
        if newlevel ~= nil and newlevel >= 1 then
            if level == 1 or newlevel > level then
                local id, nick = self:MatchNickname(matchnick)
                
                if id ~= nil then
                    local oldlevel = self.permissions[newsteamID]
                    if oldlevel == nil or oldlevel > level or level == 1 then
                        local newsteamID = GetSteamServerSystem():GetClientSteamID(id)
                        self.permissions[newsteamID] = newlevel
                        self:WritePermissions()
                        SENDMESSAGE(peerID, "Added " .. nick .. " (" .. newsteamID .. ") as an admin of level " .. newlevel)
                    else
                        SENDMESSAGE(peerID, "You cannot modify an admin with a lower access level than yourself.")
                    end
                else
                    SENDMESSAGE(peerID, "No match found.")
                end
            else
                SENDMESSAGE(peerID, "You can only add admins of level " .. level + 1 .. " or above.")
            end
        else
            SENDMESSAGE(peerID, "Admin level must be greater than or equal to 1")
        end
    end
end

function AdminRemoteControl:RemoveAdmin(peerID, message, steamID)
    local strparams = self:StringSplit2(message)
    local paramlen = # strparams

    if paramlen >= 2 then
        local matchnick = self:StringJoin2(strparams, 2, paramlen)
        local level = self.permissions[steamID]
        local id, nickname = self:MatchNickname(matchnick)
        local oldsteamID = nil 
        
        if id ~= nil then
            oldsteamID = GetSteamServerSystem():GetClientSteamID(id)
        else
            oldsteamID = matchnick
        end
        
        local oldlevel = self.permissions[oldsteamID]
            
        if oldlevel ~= nil then
            if level < oldlevel or level == 1 then
                self.permissions[oldsteamID] = nil
                self:WritePermissions()
                
                if id ~= nil then
                    SENDMESSAGE(peerID, "Removed admin " .. nickname .. " (" .. oldsteamID .. ")")
                else
                    SENDMESSAGE(peerID, "Removed admin " .. oldsteamID)
                end
            else
                SENDMESSAGE(peerID, "You cannot modify an admin with a lower access level than yourself.")
            end
        else
            SENDMESSAGE(peerID, "No match found.")
        end
    end
end

function AdminRemoteControl:ChangeProp(peerID, message)
    local player = GetPlayerManager():GetPlayerFromID(peerID)
    if player ~= nil then
        SENDMESSAGE(peerID, "found player")
    end
    local controller = player:GetController()
    if controller.physicalKart ~= nil then
        SENDMESSAGE(peerID, "physkart valid")
    end
    if controller.kartObjectServer ~= nil then
        SENDMESSAGE(peerID, "kartobjserver valid")
    end
    --local scriptObject = ToScriptObject(player:GetController().physicalKart)
    --SENDMESSAGE(peerID, "sobject: " .. scriptObject:GetScriptObjectTypeName())
    local strparams = self:StringSplit2(message)
    if # strparams >= 3 then
        local prop = strparams[2]
        local value = strparams[3]
        
    end
end

function AdminRemoteControl:Ban(peerID, message)
    local strparams = self:StringSplit2(message)
    if # strparams >= 2 then
        local matchnick = strparams[2]
        local id,nickname = self:MatchNickname(matchnick)
        
        if id == nil then
            if tonumber(matchnick) ~= nil then
                local player = GetPlayerManager():GetPlayerFromID(tonumber(matchnick))
                if player ~= nil then
                    id = tonumber(matchnick)
                    nickname = player:GetName()
                end
            end
        end
        
        if id ~= nil then
            local bansteamID = GetSteamServerSystem():GetClientSteamID(id)
            local reason = "Banned from server."
        
            if # strparams >= 3 then
                reason = "Banned: " .. self:StringJoin2(strparams, 3)
            end
            
            self.bans[bansteamID] = { nickname = nickname, reason = reason }
            self:WriteBans()
            KICKID(id, reason)
        else
            SENDMESSAGE(peerID, "No match found.")
        end
    end
end

function AdminRemoteControl:Unban(peerID, message)
    local strparams = self:StringSplit2(message)
    
    if # strparams >= 2 then
        local matchname = string.lower(self:StringJoin2(strparams, 2))

        for steamid, value in pairs(self.bans) do
            if steamid == matchname or StartsWith(string.lower(value.nickname), matchname) then
                self.bans[steamid] = nil
                self:WriteBans()
                SENDMESSAGE(peerID, "Removed ban for " .. value.nickname .. " (" .. steamid .. ")")
                return nil
            end
        end
        
        SENDMESSAGE(peerID, "No match found.")
    end
end

function AdminRemoteControl:ChangeGravity(peerID, message)
    local messageLen = message:len()
    
    if messageLen == 8 then -- Just "!gravity", so set default gravity
        GetBulletPhysicsSystem():SetGravity(Tags(Tags.ANY), GetBulletPhysicsSystem():GetDefaultGravity(Tags(Tags.ANY)))
        SENDMESSAGE(peerID, "Gravity changed.")
    elseif messageLen > 9 then -- User wants custom gravity
        message = message:sub(10)
        local strparams = WUtil_StringSplit(" ", message)
        
       if # strparams == 3 then
           local numparams = { tonumber(strparams[1]), tonumber(strparams[2]), tonumber(strparams[3]) }

           if (not numparams[1]) or (not numparams[2]) or (not numparams[3]) then
                return nil
           end
           
           local vec = WVector3(numparams[1], numparams[2], numparams[3])
           GetBulletPhysicsSystem():SetGravity(Tags(Tags.ANY), vec)
           SENDMESSAGE(peerID, "Gravity changed.")
       end
    end
end

function AdminRemoteControl:Kick(peerID, message)
    local strparams = self:StringSplit2(message)
    if # strparams >= 2 then
        local reason = nil
        
        if # strparams >= 3 then
            reason = "Kicked: " .. self:StringJoin2(strparams,3)
        end
        local result = KICK(strparams[2], reason)
        
        -- User didn't deliver an accurate nickname,
        -- So try to do a simple nickname match or kick by peer ID
        if result == false then
            local id = self:MatchNickname(strparams[2])
            if id == nil and tonumber(strparams[2]) ~= nil then
                id = tonumber(strparams[2])
            end
		            
            if id ~= nil then
                result = KICKID(id, reason)
            end
            if result == false then
                SENDMESSAGE(peerID, "No match found.")
            end
        end
    end
end

function AdminRemoteControl:RestartMap(peerID)
    if GetServerManager():GetGameMode().raceStates ~= nil then
	    RESTARTRACE()
		GetServerManager():SendServerMessage("Race restarted.")
    else
        SENDMESSAGE(peerID, "Only race mode games can be restarted.")
    end
end

function AdminRemoteControl:ChangeMap(peerID, message)
    local strparams = WUtil_StringSplit(" ", message)
    if # strparams == 2 then
        local file = io.open(ASSET_DIR .. "Maps/" .. strparams[2] .. "/" .. strparams[2] .. ".xml", "r")
        if IsValid(file) then
            file:close()
            LoadMap(strparams[2])
        else
            SENDMESSAGE(peerID, "Map not found.")
        end
    else
        NEXTMAP()
    end
end

function AdminRemoteControl:ClientConnected(connectParams)
    local clientID = connectParams:GetParameter("PeerID", true):GetIntData()
    
    if IsValid(clientID) then
        local steamID = GetSteamServerSystem():GetClientSteamID(clientID)
        local bandata = self.bans[steamID]

        if bandata ~= nil then
            KICKID(clientID, bandata.reason)
        end
    end
end

function AdminRemoteControl:HasAccess(peerID, steamid, level)
    local retval = false
    
    if level > 0 then
        local permission = self.permissions[steamid]

        if permission ~= nil then
            if permission > 0 and permission <= level then
                retval = true
            end
        end
    end
    
    if retval == false then
        SENDMESSAGE(peerID, "You do not have sufficient access.")
    end
    
    return retval
end

-- Attempts to match a partial nickname to a currently connected user, and returns their peer ID if found
function AdminRemoteControl:MatchNickname(str)
    local playerManager = GetPlayerManager()
    str = string.lower(str)
    
    for i,v in pairs(playerManager.players) do
        local playerNick = v:GetName()
        
        if StartsWith(string.lower(playerNick), str) then
            return v:GetUniqueID(), playerNick
        end
    end
    
    return nil
end

-- Joins a list of strings together with spaces between start & end indices (inclusive)
function AdminRemoteControl:StringJoin2(list, starti, endi)
    if starti == nil then
        starti = 1
    end
    if endi == nil then
        endi = # list
    end
    
    if starti <= endi then
        retval = list[starti]
        for i = starti + 1, endi do
            retval = retval .. " " .. list[i]
        end

        return retval
    end
    
    return nil
end

-- Split a space-delimited string into tokens, but treat quoted strings as a single token
function AdminRemoteControl:StringSplit2(str)
    local retval = { }
    local tokenPattern = "\"(.-)\" " -- Quoted string that is not at the end of the string
    local tokenPattern2 = "\"(.-)\"$" -- Quoted string at the end of the string
    local tokenPattern3 = "([^%s]*)" -- Unquoted word
    local oldend = 1 -- The index to begin searching at for the next iteration
    local istart, iend, istart2, iend2, match2, istart3, iend3, match3
    local strlen = str:len()
    local patternNum = nil

    while oldend <= strlen do
        -- Attempt a match with all three patterns
        istart, iend, match = str:find(tokenPattern, oldend)
        istart2, iend2, match2 = str:find(tokenPattern2, oldend)
        istart3, iend3, match3 = str:find(tokenPattern3, oldend)

        patternNum = 1
        -- If the second pattern doesn't go as far ahead as the first, use it
        if istart == nil or (istart2 ~= nil and istart2 < istart) then
            istart = istart2
            iend = iend2
            match = match2
            patternNum = 2
        end
        -- If the third pattern doesn't go as far ahead as the first or second, use it
        if istart == nil or (istart3 ~= nil and istart3 < istart) then
            istart = istart3
            iend = iend3
            match = match3
            patternNum = 3
        end

        oldend = iend + 2
        -- If the first pattern was used, don't include the trailing space as part of the match
        if patternNum == 1 then
            oldend = oldend - 1
        end
        
        if match ~= nil then
            table.insert(retval, match)
        end
    end
    
    return retval
end

function AdminRemoteControl:BuildInterfaceDefIBase()
	self:AddClassDef("AdminRemoteControl", "IBase", "Commands for controlling dedicated servers")
end

function AdminRemoteControl:InitIBase()

end

function AdminRemoteControl:UnInitIBase()

end