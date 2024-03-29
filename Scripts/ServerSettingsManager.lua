--SERVERSETTINGSMANAGER CLASS START

class 'ServerSettingsManager' (IBase)


function ServerSettingsManager:__init() super()

    if IsClient() then
        self.serverDir = GetClientSystem():GetServerDirectory()
        self.playerName = GetSteamClientSystem():GetLocalPlayerName()
    else
        self.serverDir = ".\\"
        self.playerName = GetSteamServerSystem():GetLocalPlayerName()
    end

    self.fileName = "serverSettings.txt"

    self.serverName = self.playerName.."'s Server"
    self.serverPass = ""
    self.gamePort = 27015
    self.steamPort = 27016
    self.authPort = 54320
    self.minPlayers = 7
    self.maxPlayers = 8
    self.mapTime = 5
    self.kartCC = 100

    self.mapCycle = { }
    self:ScanAllMaps(self.mapCycle)

    self:ReadFile()

end


function ServerSettingsManager:QuickPlay()

    self.minPlayers = 7
    self.maxPlayers = 8
    self.mapTime = 5
    self.kartCC = 100
    local allMaps = { }
    -- if GetDemoMode() then
    --     allMaps = { "ChampionCircuit", "KickIt" }
    -- else
        self:ScanAllMaps(allMaps)
    -- end
    self.mapCycle = { }

    while #allMaps > 0 do
        local rindex = math.modf((SRANDOM() * #allMaps) + 1)
        local map = allMaps[rindex]
        table.remove(allMaps, rindex)
        table.insert(self.mapCycle, map)
    end

    self:WriteFile()

end


function ServerSettingsManager:InitIBase()

end


function ServerSettingsManager:UnInitIBase()

end


function ServerSettingsManager:BuildInterfaceDefIBase()

	self:AddClassDef("ServerSettingsManager", "IBase", "The Server settings manager")

end


function ServerSettingsManager:ReadFile()

    print("ServerSettingsManager: Opening file:"..self.serverDir..self.fileName)
    if IsValid(self.serverDir) then
        local fname = self.serverDir..self.fileName
        local file = io.open(fname, "r")
        if IsValid(file) then
            local lineNum = 0
            local mode = nil
            for line in file:lines() do
                print("line:"..line)
                if string.sub(line,1,1) == "#" then
                    mode = line
                    if mode == "#MAP_CYCLE" then
                        self.mapCycle = {}
                    end
                elseif #line > 0 then
                    if mode == "#SERVER_NAME" then
                        self.serverName = line
                    elseif mode == "#SERVER_PASS" then
                        self.serverPass = line
                    elseif mode == "#GAME_PORT" then
                        self.gamePort = tonumber(line)
                    elseif mode == "#STEAM_PORT" then
                        self.steamPort = tonumber(line)
                    elseif mode == "#AUTH_PORT" then
                        self.authPort = tonumber(line)
                    elseif mode == "#MIN_PLAYERS" then
                        self.minPlayers = tonumber(line)
                    elseif mode == "#MAX_PLAYERS" then
                        self.maxPlayers = tonumber(line)
                    elseif mode == "#MAP_TIME" then
                        self.mapTime = line
                    elseif mode == "#KART_CC" then
                        self.kartCC = tonumber(line)
                    elseif mode == "#MAP_CYCLE" then
                        table.insert(self.mapCycle, line)
                    end
                end
                
                lineNum = lineNum + 1
            end
            file:close()

            print("Server Name:"..self.serverName)
            print("Server Pass:"..self.serverPass)
            print("Min Players:"..self.minPlayers)
            print("Max Players:"..self.maxPlayers)
            print("Map Time:"..self.mapTime)
            print("Kart CC:"..self.kartCC)
            print("Map Cycle:")
            for i=1,#self.mapCycle do
                print(self.mapCycle[i])
            end
        end 
    else
        error("ServerSettingsManager: ERROR OPENING FILE:" .. self.serverDir..self.fileName)
    end

end


function ServerSettingsManager:WriteFile()

    if IsValid(self.serverDir) then
        local fname = self.serverDir..self.fileName
        local file = io.open(fname, "w+")
        if IsValid(file) then
            file:write("#SERVER_NAME\n")
            file:write(self.serverName.."\n\n")
            file:write("#SERVER_PASS\n")
            file:write(self.serverPass.."\n\n")
            file:write("#GAME_PORT\n")
            file:write(self.gamePort.."\n\n")
            file:write("#STEAM_PORT\n")
            file:write(self.steamPort.."\n\n")
            file:write("#AUTH_PORT\n")
            file:write(self.authPort.."\n\n")
            file:write("#MIN_PLAYERS\n")
            file:write(self.minPlayers.."\n\n")
            file:write("#MAX_PLAYERS\n")
            file:write(self.maxPlayers.."\n\n")
            file:write("#MAP_TIME\n")
            file:write(self.mapTime.."\n\n")
            file:write("#KART_CC\n")
            file:write(self.kartCC.."\n\n")
            file:write("#MAP_CYCLE\n")
            for i=1,#self.mapCycle do
                file:write(self.mapCycle[i].."\n")
            end
            file:flush()
            file:close ()
        end 
    end

end


function ServerSettingsManager:ScanAllMaps(intoTable)

    local mapListParams = ScanMaps(ASSET_DIR .. "\\Maps")
    local i = 0
    while i < mapListParams:GetNumberOfParameters() do
        local mapName = mapListParams:GetParameter(i, true):GetStringData()
        if mapName ~= "Garage" and mapName ~= "SpaceJump" then
            table.insert(intoTable, mapName)
        end
        i = i + 1
    end

end

--SERVERSETTINGSMANAGER CLASS END