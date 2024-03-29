--AchievementManager CLASS START

class 'AchievementManager' (IBase)

function AchievementManager:__init() super()

    self.FLOAT = 0
    self.INT = 1

    self.STAT_MILES_DRIVEN = { 2, "STAT_MILES_DRIVEN", self.FLOAT }
    self.STAT_PLAYERS_PUNCHED = { 3, "STAT_PLAYERS_PUNCHED", self.INT }
    self.STAT_FINISHES_3RD = { 4, "STAT_FINISHES_3RD", self.INT }
    self.STAT_FINISHES_2ND = { 5, "STAT_FINISHES_2ND", self.INT }
    self.STAT_FINISHES_1ST = { 6, "STAT_FINISHES_1ST", self.INT }
    self.STAT_TARGET_POINTS = { 7, "STAT_TARGET_POINTS", self.INT }
    self.STAT_RESET_COUNT = { 8, "STAT_RESET_COUNT", self.INT }
    self.STAT_SPRING_COUNT = { 9, "STAT_SPRING_COUNT", self.INT }
    self.STAT_AIR_TIME = { 10, "STAT_AIR_TIME", self.INT }
    self.STAT_BARREL_ROLLS = { 12, "STAT_BARREL_ROLLS", self.INT }
    self.STAT_WHEELS_USED = { 13, "STAT_WHEELS_USED", self.INT }
    self.STAT_HATS_USED = { 14, "STAT_HATS_USED", self.INT }
    self.STAT_CHARS_USED = { 15, "STAT_CHARS_USED", self.INT }
    self.STAT_KARTS_USED = { 16, "STAT_KARTS_USED", self.INT }
    self.STAT_ACC_USED = { 17, "STAT_ACC_USED", self.INT }
    self.STAT_FLIPS = { 18, "STAT_FLIPS", self.INT }

    self.AVMT_GENTLEMANS_WAGER = { 0, "AVMT_GENTLEMANS_WAGER" }
    self.AVMT_COMPLETE_SHUTOUT = { 1, "AVMT_COMPLETE_SHUTOUT" }
    self.AVMT_500_MILES = { 2, "AVMT_500_MILES", self.STAT_MILES_DRIVEN, 500 }
    self.AVMT_500_MORE = { 3, "AVMT_500_MORE", self.STAT_MILES_DRIVEN, 1000 }
    self.AVMT_INDIE_GAMER = { 4, "AVMT_INDIE_GAMER" }
    self.AVMT_NAIL_BITER = { 5, "AVMT_NAIL_BITER" }
    self.AVMT_FROZEN_FINISH = { 6, "AVMT_FROZEN_FINISH" }
    self.AVMT_FLOAT_BUTTERFLY = { 7, "AVMT_FLOAT_BUTTERFLY" }
    self.AVMT_STING_BEE = { 8, "AVMT_STING_BEE" }
    self.AVMT_CLIMATE_CHANGE = { 9, "AVMT_CLIMATE_CHANGE" }
    self.AVMT_COMEBACK = { 10, "AVMT_COMEBACK" }
    self.AVMT_NEED_LOVE = { 11, "AVMT_NEED_LOVE" }
    self.AVMT_ROUTE_66 = { 12, "AVMT_ROUTE_66", self.STAT_MILES_DRIVEN, 2448 }
    self.AVMT_BRONZE_MEDAL = { 13, "AVMT_BRONZE_MEDAL", self.STAT_FINISHES_3RD, 25 }
    self.AVMT_SILVER_MEDAL = { 14, "AVMT_SILVER_MEDAL", self.STAT_FINISHES_2ND, 50 }
    self.AVMT_GOLD_MEDAL = { 15, "AVMT_GOLD_MEDAL", self.STAT_FINISHES_1ST, 100 }
    self.AVMT_TICKET_MASTER = { 16, "AVMT_TICKET_MASTER", self.STAT_TARGET_POINTS, 10000 }
    self.AVMT_DISAPPEARING_ACT = { 17, "AVMT_DISAPPEARING_ACT", self.STAT_RESET_COUNT, 50 }
    self.AVMT_BFF = { 18, "AVMT_BFF" }
    self.AVMT_DEEP_SPACE = { 19, "AVMT_DEEP_SPACE" }
    self.AVMT_DEEP_6 = { 20, "AVMT_DEEP_6" }
    self.AVMT_DRAFT_MASTER = { 21, "AVMT_DRAFT_MASTER" }
    self.AVMT_ROCKET_SAUCE = { 22, "AVMT_ROCKET_SAUCE" }
    self.AVMT_SPRING_CHICKEN = { 23, "AVMT_SPRING_CHICKEN", self.STAT_SPRING_COUNT, 50 }
    self.AVMT_FLIGHT_FALCON = { 24, "AVMT_FLIGHT_FALCON", self.STAT_AIR_TIME, 15 }
    self.AVMT_PARATROOPER = { 25, "AVMT_PARATROOPER" }
    self.AVMT_GOOD_SPORT = { 26, "AVMT_GOOD_SPORT" }
    self.AVMT_FLIPPIN_AWESOME = { 27, "AVMT_FLIPPIN_AWESOME" }
    self.AVMT_DOUBLE_FLIP = { 28, "AVMT_DOUBLE_FLIP" }
    self.AVMT_TRIPLE_FLIP = { 29, "AVMT_TRIPLE_FLIP" }
    self.AVMT_I_GET_AROUND = { 30, "AVMT_I_GET_AROUND", self.STAT_FLIPS, 20 }
    self.AVMT_BARREL_ROLL = { 31, "AVMT_BARREL_ROLL" }
    self.AVMT_SLIPPY_SEZ = { 32, "AVMT_SLIPPY_SEZ", self.STAT_BARREL_ROLLS, 10 }
    self.AVMT_PACIFIST = { 33, "AVMT_PACIFIST" }
    self.AVMT_OVERACHIEVER = { 34, "AVMT_OVERACHIEVER" }
    self.AVMT_KO = { 35, "AVMT_KO" }
    self.AVMT_PIRATE_PARTY = { 36, "AVMT_PIRATE_PARTY" }
    self.AVMT_LEMMING = { 37, "AVMT_LEMMING" }
    self.AVMT_USE_THE_FORCE = { 38, "AVMT_USE_THE_FORCE" }
    self.AVMT_PWNT = { 39, "AVMT_PWNT" }
    self.AVMT_SCREWED = { 40, "AVMT_SCREWED" }
    self.AVMT_WAR_GAMES = { 41, "AVMT_WAR_GAMES" }
    self.AVMT_TERMINATION = { 42, "AVMT_TERMINATION" }
    self.AVMT_EASY_RIDER = { 43, "AVMT_EASY_RIDER" }
    self.AVMT_INSPECTOR_KEMP = { 44, "AVMT_INSPECTOR_KEMP" }

    self.STAT_MILES_DRIVEN[4] = { self.AVMT_500_MILES, self.AVMT_500_MORE, self.AVMT_ROUTE_66 }
    self.STAT_FINISHES_3RD[4] = { self.AVMT_BRONZE_MEDAL }
    self.STAT_FINISHES_2ND[4] = { self.AVMT_SILVER_MEDAL }
    self.STAT_FINISHES_1ST[4] = { self.AVMT_GOLD_MEDAL }
    self.STAT_TARGET_POINTS[4] = { self.AVMT_TICKET_MASTER }
    self.STAT_RESET_COUNT[4] = { self.AVMT_DISAPPEARING_ACT }
    self.STAT_SPRING_COUNT[4] = { self.AVMT_SPRING_CHICKEN }
    self.STAT_AIR_TIME[4] = { self.AVMT_FLIGHT_FALCON }
    self.STAT_FLIPS[4] = { self.AVMT_I_GET_AROUND }
    self.STAT_BARREL_ROLLS[4] = { self.AVMT_SLIPPY_SEZ }

end

function AchievementManager:InitIBase()

    --[[self.achievementUnlockedSlot = self:CreateSlot("AchievementUnlocked", "AchievementUnlocked")
    GetSteamClientSystem():GetStatsAndAchievements():GetSignal("AchievementUnlocked", true):Connect(self.achievementUnlockedSlot)
    self.achievementProgressSlot = self:CreateSlot("AchievementProgress", "AchievementProgress")
    GetSteamClientSystem():GetStatsAndAchievements():GetSignal("AchievementProgress", true):Connect(self.achievementProgressSlot)--]]

end

function AchievementManager:UnInitIBase()

end

function AchievementManager:BuildInterfaceDefIBase()

	self:AddClassDef("AchievementManager", "IBase", "The Achievements manager")
	
end

function AchievementManager:Unlock(avmt)

    if IsClient() then
        --Don't unlock this achievement if it has already been unlocked
        if not GetSteamClientSystem():GetStatsAndAchievements():GetAchievementUnlocked(avmt[2]) then
            print("Achievement "..avmt[2].." unlocked")
            --Notify other players on the server
            local displayName = GetSteamClientSystem():GetStatsAndAchievements():GetAchievementDisplayName(avmt[2])
            GetMenuManager():GetChat():SendMessage("Just achieved " .. displayName .. "!")
            GetSteamClientSystem():GetStatsAndAchievements():UnlockAchievement(avmt[2])
        end
    end

end

function AchievementManager:UpdateStat(stat, delta)

    if IsClient() then
        if not IsValid(delta) then
            print("Warning: delta is nil in AchievementManager:UpdateStat()")
            return
        end
        print("Stat "..stat[2].." updated by: "..delta)
        if stat[3] == self.FLOAT then
            GetSteamClientSystem():GetStatsAndAchievements():UpdateFloatStat(stat[2], delta)
        else
            GetSteamClientSystem():GetStatsAndAchievements():UpdateIntStat(stat[2], delta)
        end
        --Check if this stat is tied to an achievement
        if IsValid(stat[4]) then
            local i = 1
            local avmts = stat[4]
            while i <= #avmts do
                if avmts[i][3][3] == self.FLOAT then
                    print("Checking " .. avmts[i][3][2] .. ": " .. tostring(GetSteamClientSystem():GetStatsAndAchievements():GetFloatStat(avmts[i][3][2])) .. " >= " .. tostring(avmts[i][4]))
                    if GetSteamClientSystem():GetStatsAndAchievements():GetFloatStat(avmts[i][3][2]) >= avmts[i][4] then
                        self:Unlock(avmts[i])
                    end
                else
                    print("Checking " .. avmts[i][3][2] .. ": " .. tostring(GetSteamClientSystem():GetStatsAndAchievements():GetIntStat(avmts[i][3][2])) .. " >= " .. tostring(avmts[i][4]))
                    if GetSteamClientSystem():GetStatsAndAchievements():GetIntStat(avmts[i][3][2]) >= avmts[i][4] then
                        self:Unlock(avmts[i])
                    end
                end
                i = i + 1
            end
        end
    end

end

function AchievementManager:AchievementUnlocked(params)

end

function AchievementManager:AchievementProgress(params)

    local achName = params:GetParameter("Achievement", true):GetStringData()
    local current = params:GetParameter("Current", true):GetIntData()
    local max = params:GetParameter("Max", true):GetIntData()
    print(achName .. " progress current: " .. tostring(current) .. " / max: " .. tostring(max))

end

--AchievementManager CLASS END