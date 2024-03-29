UseModule("IBase", "Scripts/")

--NETWORKCLOCK CLASS START

class 'NetworkClock' (IBase)

function NetworkClock:__init(setNetworkSystem) super()

	self.networkSystem = setNetworkSystem

	if not IsValid(self.networkSystem) then
		error("NetworkClock passed null network system in constructor")
	end

	self.startTime = 0

	self:Reset()

end


function NetworkClock:BuildInterfaceDefIBase()

	self:AddClassDef("NetworkClock", "IBase", "Tracks time based on a synced network clock")

end


function NetworkClock:Reset()

	self.startTime = self.networkSystem:GetTime()

end


function NetworkClock:AddTime(addTime)

	--Subtract from the start time to add time
	self.startTime = self.startTime - addTime

end


function NetworkClock:RemoveTime(removeTime)

	--Add to the start time to remove time
	self.startTime = self.startTime + removeTime

end


--Get the amount of time that has passed since this clock was Reset()
function NetworkClock:GetTimeSeconds()

	return self.networkSystem:GetTime() - self.startTime

end


function NetworkClock:GetTimeDifference()

	local time = self:GetTimeSeconds()
	self:Reset()

	return time

end

--NETWORKCLOCK CLASS END